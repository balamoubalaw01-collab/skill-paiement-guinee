# Réconciliation et suivi financier

Un paiement « réussi » techniquement n'explique pas toujours pourquoi l'argent reçu ne correspond pas aux chiffres : frais différents selon le réseau, paiements tardifs, doubles paiements, remboursements, webhooks perdus, versements de l'agrégateur vers le compte du marchand. La réconciliation compare régulièrement **ta base** et **l'agrégateur**, et signale chaque écart.

## Deux mécanismes différents

| | Rattrapage (toutes les 2 à 5 min) | Réconciliation (1 fois par jour, ou à la demande) |
| --- | --- | --- |
| But | finir les paiements en cours | trouver les écarts |
| Périmètre | paiements `pending` / `processing` récents | toutes les transactions d'une période (la veille, J-2 par sécurité) |
| Action | applique les transitions | **n'écrit pas** de statut tout seul : produit un rapport et des alertes ; les corrections passent par `appliquerTransition` ou par un humain |

## Sources côté agrégateur

- API de liste / recherche des transactions si elle existe (voir la fiche de l'agrégateur).
- Sinon : export CSV du tableau de bord, importé par l'utilisateur (prévois une commande ou un écran d'import).
- Si rien n'est disponible : réconciliation par `getPaymentStatus` sur chaque paiement local de la période (ne détecte pas les paiements inconnus chez nous).

## Écarts à détecter

| Écart | Exemple | Gravité |
| --- | --- | --- |
| Chez l'agrégateur, absent chez nous | webhook perdu + crash | haute : argent reçu sans commande |
| Chez nous `succeeded`, absent ou non réussi chez l'agrégateur | bug, fraude, mauvais environnement | **critique** : livré sans être payé |
| Statuts différents | `processing` chez nous, `succeeded` chez lui | moyenne (le rattrapage aurait dû le voir) |
| Montant ou devise différents | 1 000 attendu, 200 reçu | haute |
| Frais différents de ceux prévus | frais plus élevés sur un réseau | moyenne : marge fausse |
| Double paiement d'une commande | deux `succeeded` | haute : à rembourser |
| Remboursement sans trace chez nous (ou l'inverse) | remboursé depuis le tableau de bord | moyenne |
| Total net du jour ≠ versement / solde | net attendu = Σ montants − Σ frais − Σ remboursements | haute |

## Stockage

- `reconciliation_runs` : période, source (API, export), date, nombre de lignes de chaque côté, totaux brut / frais / net, nombre d'écarts, statut.
- `reconciliation_items` : une ligne par écart : type, références locale et fournisseur, valeurs des deux côtés, gravité, statut de traitement (`ouvert`, `corrige`, `accepte`), commentaire, qui a traité.
- Le journal `payment_events` (ajout seulement) permet de rejouer l'histoire d'un paiement.

## Alertes

- Critique et haute : alerte immédiate (e-mail, Slack, WhatsApp, Telegram… selon ce que le projet utilise déjà).
- Résumé quotidien : totaux, nombre d'écarts ouverts.
- Alerte aussi si la réconciliation **ne tourne pas** (pas de run depuis 36 h) ou si le rattrapage voit des paiements bloqués trop longtemps.

## Journalisation sécurisée

- Jamais : clés, secrets, PIN, OTP, numéro de carte, en-têtes d'authentification.
- Masquer : numéros de téléphone (`2290166****00`), e-mails partiels.
- Garder les réponses brutes de l'agrégateur dans une colonne dédiée, avec accès restreint, et une durée de conservation définie.
- Les logs de paiement ne se modifient pas (ajout seulement) ; les corrections sont des nouvelles lignes.

## À livrer

- la tâche planifiée de réconciliation (voir le guide du framework pour la planification) ;
- une commande pour la lancer à la main sur une période ;
- un rapport lisible (page d'admin existante, export CSV, ou e-mail) ;
- si le projet n'a pas d'admin : ne construis pas une admin complète, un rapport par e-mail ou un CSV suffit.
