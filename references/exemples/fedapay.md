# FedaPay — fiche d'intégration (pay-in)

Doc officielle : https://docs.fedapay.com (index pour IA : https://docs.fedapay.com/llms.txt)
Légende : ✅ vérifié · 🟡 indicatif · ❓ non confirmé (voir SKILL.md, « Niveaux de confiance »).
Versions testées le 31/10/2026 : SDK Node `fedapay` **1.2.5**, SDK PHP `fedapay/fedapay-php` **0.4.9**. Si le projet utilise une autre version, relance `outils/test-sdk-fedapay-*.js`.

## Environnements et authentification

- ✅ Sandbox `https://sandbox-api.fedapay.com/v1` · Live `https://api.fedapay.com/v1` (constantes du SDK Node).
- ✅ En-tête `Authorization: Bearer <CLÉ_SECRÈTE>` (requête observée depuis le SDK).
- 🟡 Clés publique et secrète, en test et en live, dans le tableau de bord.

## Parcours 1 — Page de paiement FedaPay

✅ Requêtes vérifiées avec le SDK Node (réponses simulées) :
```js
const { FedaPay, Transaction } = require('fedapay');
FedaPay.setApiKey(process.env.FEDAPAY_SECRET_KEY);
FedaPay.setEnvironment(process.env.FEDAPAY_ENV);            // 'sandbox' ou 'live'

const transaction = await Transaction.create({               // POST /v1/transactions
  description: `Commande ${order.id}`,
  amount: order.amount,                                      // entier, lu en base
  currency: { iso: 'XOF' },
  callback_url: `${process.env.APP_URL}/paiement/retour`,
  customer: { firstname, lastname, email, phone_number: { number: '0166000000', country: 'bj' } },
});
const token = await transaction.generateToken();             // POST /v1/transactions/{id}/token -> { token, url }
// rediriger le client vers token.url ; garder transaction.id comme provider_ref
const t = await Transaction.retrieve(transaction.id);        // fetchStatus
```
- 🟡 Le champ `customer` et son format viennent de la doc ; vérifie les champs obligatoires dans la référence API « Create a transaction ».
- 🟡 Au retour sur `callback_url`, **ne crois pas** le statut dans l'URL : revérifie avec `Transaction.retrieve`.

## Parcours 2 — Paiement direct (demande de PIN)

✅ Signature réelle du SDK : `sendNowWithToken(mode, token, params)` — le numéro va **dans `params`** :
```js
const token = await transaction.generateToken();
await transaction.sendNowWithToken(mode, token.token, { phone_number: { number: '0166000001', country: 'bj' } });
// envoie POST /v1/{mode} avec { phone_number, token }
// raccourci : await transaction.sendNow(mode, { phone_number: {...} })
```
❓ **Le nom exact du `mode` par réseau.** La doc a utilisé selon les versions `mtn`, `mtn_open`, `mtn_benin` (MTN Bénin), `moov` / `moov_benin` (Moov Bénin), `sbin` (Celtiis Bénin), `moov_tg`, `mtn_ci`… Ne choisis pas au hasard : lis la page « méthodes de paiement » à jour, ou teste chaque mode en sandbox. Sans confirmation, propose le parcours 1 (page FedaPay), qui n'a pas besoin du mode.

## Statuts

🟡 D'après la doc : `pending` (expire après 24 h), `approved`, `declined`, `canceled`, `expired`, `refunded`, `transferred`.
Correspondance vers les 7 statuts : `pending` (côté FedaPay) → `processing` · `approved` / `transferred` → `succeeded` · `declined` / `canceled` → `failed` (ni l'un ni l'autre ne sont définitifs : le client peut réessayer sur la même transaction ; `cancelled` reste réservé aux annulations faites par ton appli) · `expired` → `expired` · `refunded` → `refunded` · autre → `inconnu`.

## Webhook

- 🟡 Configuré dans le tableau de bord ; un secret par webhook (`wh_sandbox...` en test), **différent en live** ; FedaPay attend une réponse 2xx et réessaie sinon.
- ✅ En-tête `X-FEDAPAY-SIGNATURE`, format `t=<horodatage>,s=<signature>`. Signature = HMAC-SHA256(secret, `"<t>.<corps brut>"`) en hexadécimal. Tolérance par défaut du SDK : 300 s (anti-rejeu).
- ✅ Node (testé : signature valide acceptée ; mauvais secret, corps modifié, signature vieille d'1 h rejetés) :
  ```js
  const { Webhook } = require('fedapay');
  // le corps doit être BRUT (Buffer ou string) : express.raw, req.text() (Next.js)…
  const event = Webhook.constructEvent(rawBody, req.headers['x-fedapay-signature'], process.env.FEDAPAY_WEBHOOK_SECRET);
  ```
  ✅ Passer un objet JSON déjà parsé fait **échouer** la vérification (testé).
- ✅ PHP (testé, SDK 0.4.9) : `\FedaPay\Webhook::constructEvent($request->getContent(), $request->header('X-FEDAPAY-SIGNATURE'), $secret)` ; erreur levée : `\FedaPay\Error\SignatureVerification`.
- ✅ Python (pas de SDK officiel utilisé) : `outils/fedapay_signature.py`, portage du SDK testé contre des signatures générées par le SDK officiel.
- 🟡 Le nom des événements (`transaction.approved`, `transaction.canceled`, `transaction.declined`…) et la place de l'identifiant de transaction dans le corps : lis l'exemple de la doc. Dans tous les cas, l'identifiant sert seulement à appeler `Transaction.retrieve` : c'est **cette réponse** qui décide (règles d'or 3 et 4).

## Tests

🟡 Clés et compte sandbox. Les numéros mobile money de test (succès / échec) sont dans la doc « mode test » ; ils peuvent changer, consulte-la.

## Opérations prises en charge

| Opération | Niveau | Détail |
| --- | --- | --- |
| Pay-in mobile money | ✅ / ❓ | page de paiement ✅ ; paiement direct ✅ mais nom du `mode` ❓ |
| Carte | 🟡 | proposée sur la page de paiement d'après la doc (cartes de test dans la doc « mode test ») |
| Payout | 🟡 | API « Payouts » documentée (`https://api.fedapay.com/v1/payouts/...`) ; champs à lire dans la référence API |
| Remboursement | ❓ | le statut `refunded` existe et la doc dit qu'un remboursement part de `approved` ou `transferred`, mais l'appel API n'est pas confirmé ici : vérifie la référence API avant de coder `refundPayment` |
| Récurrent | ❓ | rien de confirmé : ne pas proposer sans doc |
| Liste des transactions (réconciliation) | 🟡 | « Search your transactions » dans la référence API |
