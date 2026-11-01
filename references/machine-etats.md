# Machine à états des paiements

Une seule source de vérité pour les statuts. Toute écriture de statut passe par la fonction de transition (`appliquerTransition`) ; aucun autre code n'écrit la colonne `status`.

## Les 7 statuts

| Statut | Sens | Définitif ? |
| --- | --- | --- |
| `pending` | créé chez nous, pas encore accepté par l'agrégateur | non |
| `processing` | accepté par l'agrégateur, en attente du client (PIN, page de paiement) ou du réseau | non |
| `succeeded` | l'agrégateur confirme que l'argent est reçu | oui, sauf remboursement |
| `failed` | refusé ou échoué | **non** : un paiement tardif peut encore être confirmé |
| `cancelled` | annulé (par le client, par nous, ou par l'agrégateur) | **non** : même raison |
| `expired` | délai dépassé sans réponse | **non** : même raison |
| `refunded` | remboursé (totalement) et confirmé par l'agrégateur | oui |

Correspondance des statuts des agrégateurs : voir chaque fiche (`references/<agregateur>.md`). Un statut inconnu de l'agrégateur = **aucune transition** + alerte (jamais « succès par défaut », jamais « échec par défaut »).

Les anomalies métier ne sont **pas** des statuts : elles vont dans une colonne `anomalie` (`montant_incorrect`, `devise_incorrecte`, `double_paiement`, `statut_inconnu`…). Le statut décrit ce que dit l'agrégateur ; la commande décrit ce que l'entreprise a livré.

## Transitions autorisées

| De \ Vers | processing | succeeded | failed | cancelled | expired | refunded |
| --- | --- | --- | --- | --- | --- | --- |
| `pending` | ✔ | ✔ | ✔ | ✔ | ✔ | |
| `processing` | | ✔ | ✔ | ✔ | ✔ | |
| `failed` | ✔ (nouvel essai) | ✔ (tardif) | | | | |
| `cancelled` | | ✔ (tardif + anomalie) | | | | |
| `expired` | | ✔ (tardif) | | | | |
| `succeeded` | | | | | | ✔ (remboursement confirmé) |
| `refunded` | | | | | | |

Tout le reste est **refusé et journalisé** (par exemple `succeeded → failed` à cause d'un webhook en retard).

`pending → succeeded` est autorisé pour le cas où la confirmation arrive avant qu'on ait enregistré `processing`.

## Règles de traitement

1. **On ne croit pas l'ordre des événements.** À chaque webhook ou passage du rattrapage, on demande le statut **actuel** à l'agrégateur (`getPaymentStatus`) et on applique la transition vers ce statut si elle est autorisée. Un vieil événement « échec » reçu après un succès produit une transition refusée : rien ne change.
2. **Doublons** : chaque événement est enregistré dans `webhook_events` avec `UNIQUE (provider, event_key)` avant tout traitement. Déjà vu → réponse 200, fin.
3. **Écriture atomique** : la transition est un `UPDATE ... WHERE id = :id AND status IN (<statuts de départ autorisés>)`. 0 ligne modifiée = quelqu'un est passé avant, ou transition interdite : on relit et on journalise (voir `fiabilite-paiements.md`).
4. **Paiement tardif** (`failed` / `cancelled` / `expired` → `succeeded`) : l'argent est reçu. Si la commande est encore payable → on la valide. Si elle a été annulée, revendue, ou payée par un autre paiement → `anomalie = 'double_paiement'` ou `'paiement_tardif'`, pas de livraison automatique, alerte pour remboursement.
5. **Remboursement** : `succeeded → refunded` seulement quand l'agrégateur **confirme** le remboursement. Pendant la demande, garde `succeeded` et suis la demande dans une table `refunds` (sa propre machine : `requested → processing → succeeded | failed`). Remboursement partiel : `refunds` porte le montant ; le paiement reste `succeeded` tant que le total remboursé est inférieur au montant.
6. **Journal** : chaque transition (acceptée ou refusée) écrit une ligne dans `payment_events` : `payment_id`, `from`, `to`, `source` (`webhook`, `rattrapage`, `api`, `admin`), `provider_status`, date, empreinte de la réponse brute. Ce journal ne se modifie jamais (ajout seulement).

## La commande suit le paiement, pas l'inverse

- La commande passe à « payée » **dans la même transaction de base** que la transition vers `succeeded`, avec sa propre garde (`WHERE status <> 'paid'`).
- Les effets (livraison, e-mail, crédit) partent **après le commit**, une seule fois (outbox ou file d'attente).
- Un remboursement confirmé met la commande à jour selon la règle métier du projet (annulée, à reprendre…) : demande-la à l'utilisateur si elle n'existe pas.

## Implémentation de référence

`outils/test-concurrence-postgres.js` contient la table des transitions, la fonction de transition atomique et les tests (événements en double, désordre, paiement tardif, double paiement, remboursement), exécutés sur un vrai PostgreSQL.
