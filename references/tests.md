# Tests automatiques

Trois niveaux. Les deux premiers tournent sans clés ni réseau : ils doivent passer avant toute mise en production.

## Niveau 1 — Adaptateur (API simulée)

Simule l'agrégateur avec l'outil standard du langage :
- Node : `nock` ou `msw` · PHP / Laravel : `Http::fake()` (client HTTP Laravel) ou Guzzle `MockHandler` · Python : `responses` (requests) ou `respx` (httpx) · Dart / Flutter : `MockClient` de `package:http/testing.dart`.

Derrière un proxy d'entreprise, exclure les hôtes simulés du proxy (`NO_PROXY`), sinon la simulation est contournée.

Cas à couvrir pour `createPayment` et `getPaymentStatus` :
- [ ] réponse normale (succès, échec, en attente) → bon statut normalisé ;
- [ ] **erreur réseau** (connexion refusée, DNS) → `ErreurReseau`, aucun statut final ;
- [ ] **délai dépassé** → `DelaiDepasse`, le paiement reste `pending` / `processing` ;
- [ ] erreur 401 / 403 → message clair (clé ou IP non autorisée), pas de nouvel essai en boucle ;
- [ ] erreur 4xx avec message de l'agrégateur → `RefusFournisseur` avec le **message réel** ;
- [ ] erreur 5xx → nouvel essai limité (lecture seulement : jamais pour une création de payout) ;
- [ ] **réponse inattendue** : JSON invalide, champ manquant, statut inconnu, montant en texte → `ReponseInattendue` ou `inconnu`, **jamais** `succeeded` ;
- [ ] montant / devise de la réponse différents de la demande → anomalie.

Cas pour `verifyWebhook` :
- [ ] signature valide → accepté ;
- [ ] mauvaise signature, mauvais secret, en-tête absent, en-tête mal formé → refusé ;
- [ ] corps modifié d'un seul caractère → refusé ;
- [ ] horodatage trop ancien (si l'agrégateur en met un) → refusé ;
- [ ] corps déjà parsé passé par erreur → doit échouer (preuve que le corps **brut** est utilisé).
Pour produire des signatures valides : outil de test du SDK (FedaPay : `Webhook.generateTestHeaderString`) ou ton propre calcul à partir de la doc.

## Niveau 2 — Service et base de données (vraie base, sans réseau)

Sur le **même moteur** que la production (PostgreSQL, MySQL…) : SQLite en mémoire ne reproduit pas les verrous.
- [ ] machine à états : chaque transition autorisée passe, chaque transition interdite est refusée et journalisée ;
- [ ] le même webhook 10 fois **en parallèle** → une seule livraison ;
- [ ] webhook + rattrapage simultanés → une seule livraison ;
- [ ] événements dans le désordre (échec après succès) → reste `succeeded` ;
- [ ] paiement tardif après `expired` / `failed` → `succeeded` et règle métier appliquée ;
- [ ] deux paiements réussis pour une commande → une livraison + `anomalie = double_paiement` ;
- [ ] remboursement : seulement depuis `succeeded`, total ≤ montant, deux confirmations parallèles → une transition ;
- [ ] payout : délai dépassé → **aucun** nouvel envoi automatique ;
- [ ] double clic (même clé d'idempotence) → un seul paiement ;
- [ ] crash simulé entre l'appel à l'agrégateur et l'enregistrement → le rattrapage retrouve le paiement.
Référence exécutable : `outils/test-concurrence-postgres.js`.

## Niveau 3 — Sandbox de l'agrégateur (avec les clés de test de l'utilisateur)

À faire par l'utilisateur (ou par toi s'il a mis ses clés de test dans `.env`), avec un tunnel HTTPS pour le webhook :
- [ ] paiement réussi de bout en bout, webhook reçu, commande payée une fois ;
- [ ] paiement refusé / annulé ;
- [ ] client qui ne valide pas → expiration ;
- [ ] faux webhook envoyé à la main → refusé ;
- [ ] remboursement (si pris en charge) ;
- [ ] chaque réseau proposé dans l'appli (MTN, Moov, Celtiis…).

Ce que le sandbox ne sait pas reproduire (désordre, doublons, pannes, réponses étranges) est couvert par les niveaux 1 et 2. **Un test sandbox n'est pas un test en réel** : le rapport final le dit.
