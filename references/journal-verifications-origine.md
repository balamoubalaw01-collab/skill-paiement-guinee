# Journal des vérifications (31 octobre 2026)

Ce qui a été réellement exécuté pour écrire ce skill. Aucun paiement réel ni aucun appel à une API de production n'a été fait : les API des agrégateurs étaient **simulées**.

| Élément | Méthode | Résultat |
| --- | --- | --- |
| FedaPay — vérification de webhook (Node) | SDK `fedapay` 1.2.5, signatures générées par l'outil de test du SDK | ✅ valide accepté ; mauvais secret, corps modifié, signature d'1 h, objet déjà parsé : refusés |
| FedaPay — webhook dans Express | route `express.raw`, requêtes HTTP locales | ✅ 200 si valide, 400 si falsifié |
| FedaPay — création, token, paiement direct (Node) | SDK 1.2.5 + `nock` (réponses simulées) | ✅ `POST /v1/transactions` (Bearer), `POST /v1/transactions/{id}/token`, `POST /v1/{mode}` avec `{phone_number, token}` ; le numéro va dans le 3e paramètre de `sendNowWithToken` |
| FedaPay — vérification de webhook (PHP) | SDK `fedapay/fedapay-php` 0.4.9 | ✅ valide accepté ; mauvais secret, signature ancienne, corps modifié : `SignatureVerification` |
| FedaPay — vérification de webhook (Python) | portage `outils/fedapay_signature.py`, testé contre des signatures du SDK officiel | ✅ mêmes résultats, y compris accents UTF-8 et en-têtes mal formés |
| Django — vue webhook + mise à jour filtrée | Django 6.1, client de test, CSRF actif, SQLite | ✅ 200 / 401 / 405 ; `.filter().update()` renvoie 1 puis 0 |
| KkiaPay — vérification serveur (Node) | SDK `@kkiapay-org/nodejs-sdk` 1.0.7 + `nock` | ✅ URL, en-têtes, corps, sandbox / live ; erreur levée si transaction introuvable |
| KkiaPay — remboursement | lecture du code du SDK 1.0.7 | ✅ `refund()` → `POST /api/v1/transactions/revert` (non exécuté) |
| FeexPay — requêtes | lecture du code du SDK `feexpay/feexpay-php` 3.0.0 | ✅ hôte, en-têtes, corps du pay-in, endpoint de statut, paiement carte (non exécutés) |
| FeexPay — pay-in Bénin par réseau | page « API - Payin » de la doc officielle v2, copiée par Eric (31/10/2026) | 📄 URL par réseau (`mtn`, `moov`, `celtiis_bj`), champs, en-tête Bearer, limites 100 – 2 000 000 XOF, réponse `PENDING` (non exécuté) |
| Machine à états + concurrence | `outils/test-concurrence-postgres.js`, PostgreSQL 16, 10 scénarios en parallèle, 4 exécutions | ✅ 10/10 |

Non vérifié (et marqué ❓ dans les fiches) : vérification des webhooks KkiaPay et FeexPay, noms des `mode` FedaPay par réseau, URL FeexPay des pays autres que le Bénin, API de remboursement FedaPay et FeexPay, payouts par API, paiements récurrents, numéros de test sandbox.

Non exécuté (marqué 🟡) : guides Next.js, Laravel (hors SDK FedaPay), Flutter ; options des widgets.

Pour revérifier avec d'autres versions : `outils/test-sdk-fedapay-kkiapay.js`, `outils/test-sdk-fedapay-requetes.js`, `outils/test-concurrence-postgres.js`.
