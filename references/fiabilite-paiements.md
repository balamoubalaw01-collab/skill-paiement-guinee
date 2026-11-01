# Fiabilité des paiements : concurrence, unicité, ordre des opérations

Vérifier le paiement auprès de l'agrégateur ne suffit pas. Deux webhooks peuvent arriver en même temps, le webhook et la tâche de rattrapage peuvent traiter le même paiement à la même seconde, un client peut payer deux fois. Cette fiche rend le traitement **sûr en parallèle**. Les statuts et transitions sont définis dans `machine-etats.md`.

Principe : **la base de données arbitre**, pas le code. Jamais « je lis le statut, puis j'écris » sans protection.

## 1. Contraintes en base (obligatoires)

| Contrainte | Pourquoi |
| --- | --- |
| `UNIQUE (provider, provider_ref)` sur `payments` | une transaction de l'agrégateur ne paie qu'un seul paiement interne |
| `UNIQUE (idempotency_key)` sur `payments` | un double clic ou une requête renvoyée ne crée pas deux paiements |
| Un seul paiement `succeeded` sans anomalie par commande | une commande n'est jamais payée deux fois |
| Un seul paiement `pending` / `processing` par commande | pas deux demandes de PIN en même temps |
| `UNIQUE (provider, event_key)` sur `webhook_events` | un même événement n'est traité qu'une fois |
| `CHECK (status IN (...))` | aucun statut inventé |

Index partiels :
- PostgreSQL / SQLite : `CREATE UNIQUE INDEX ... ON payments (order_id) WHERE status = 'succeeded' AND anomalie IS NULL;` et `... WHERE status IN ('pending','processing');`
- MySQL / MariaDB (pas d'index partiel) : colonne générée ou colonne `success_order_id` nullable et `UNIQUE`, remplie seulement quand la condition est vraie (plusieurs `NULL` sont permis).

`event_key` = identifiant d'événement de l'agrégateur s'il existe ; sinon `transactionId + type d'événement`, ou l'empreinte SHA-256 du corps brut.

## 2. Ordre impératif d'un traitement (webhook ou rattrapage)

1. **Hors transaction de base** :
   1. vérifier la signature / le secret du webhook (sinon `401`) ;
   2. enregistrer l'événement dans `webhook_events` (doublon → `200` et fin) ;
   3. appeler `getPaymentStatus` chez l'agrégateur.
   On n'appelle **jamais** une API externe en tenant un verrou ou une transaction ouverte : un appel lent bloquerait tout.
2. **Dans une transaction courte** : `appliquerTransition` (voir `machine-etats.md`) :
   ```sql
   UPDATE payments SET status = :vers, ...
    WHERE id = :id AND status = ANY(:statuts_de_depart_autorises);
   ```
   - 0 ligne modifiée → déjà traité ou transition interdite : journaliser, ne rien faire d'autre.
   - erreur d'unicité (index « un seul réussi par commande ») → un autre paiement a déjà payé la commande : annuler, puis enregistrer ce paiement `succeeded` avec `anomalie = 'double_paiement'` dans une nouvelle transaction. Codes : PostgreSQL `23505`, MySQL `1062`, Prisma `P2002`, Django `IntegrityError`, Laravel `UniqueConstraintViolationException` (10.21+) ou `QueryException`.
   - 1 ligne → mettre à jour la commande avec sa propre garde (`WHERE status = 'awaiting_payment'`), écrire `payment_events` et l'outbox.
3. **Après le commit seulement** : effets de bord (livraison, e-mail, crédit), une seule fois, via l'outbox ou une file d'attente (`DB::afterCommit` / `->afterCommit()` en Laravel, `transaction.on_commit` en Django, outbox lue par un worker en Node).

Avec un ORM, utilise la **mise à jour en masse filtrée** qui renvoie le nombre de lignes (`updateMany`, `->where()->update()`, `.filter().update()`), jamais « charger l'objet, modifier, sauvegarder ».
Alternative : `SELECT ... FOR UPDATE` sur la ligne, décision, écriture, dans la même transaction.

## 3. Créer un paiement sans doublon

1. L'appli génère une `idempotency_key` (UUID) **par tentative** et l'envoie avec la demande.
2. Transaction : verrouiller la commande (`SELECT ... FOR UPDATE`), refuser si elle est payée, réutiliser le paiement en cours s'il existe, sinon insérer un paiement `pending`. Clé déjà connue → renvoyer le paiement existant.
3. **Après le commit**, appeler `createPayment` en donnant notre identifiant interne comme référence marchand quand l'agrégateur le permet (pour retrouver le paiement si on plante entre l'appel et l'enregistrement).
4. Enregistrer `provider_ref` et passer à `processing`. Refus clair → `failed`. Délai dépassé / erreur réseau → **ne rien conclure** : le paiement reste `pending` et le rattrapage s'en occupe.

## 4. Payouts (versements sortants) : règles en plus

Un payout envoyé deux fois, c'est de l'argent perdu. En plus de tout ce qui précède :
- clé d'idempotence côté agrégateur si l'API en propose une ; sinon, enregistrer en base (et committer) le jeton / la référence de la demande **avant** de l'envoyer ;
- **jamais de nouvel essai automatique** d'un payout dont le résultat est inconnu (délai dépassé, erreur 5xx) : on vérifie d'abord son statut, puis un humain décide ;
- jamais de bascule automatique vers un autre agrégateur après une erreur sur un payout ;
- plafonds par opération et par jour, validation humaine au-delà ;
- vérifier le solde disponible avant d'envoyer.

## 5. Implémentation de référence testée

`outils/test-concurrence-postgres.js` implémente `appliquerTransition` et la teste sur un vrai PostgreSQL 16 : doublons en parallèle, désordre, webhook + rattrapage simultanés, paiement tardif, double paiement, montant faux, statut inconnu, remboursement concurrent, double clic. ✅ 10/10 tests passent (exécuté 4 fois le 31/10/2026). Traduis cette logique dans le langage du projet ; ne la réinvente pas.
