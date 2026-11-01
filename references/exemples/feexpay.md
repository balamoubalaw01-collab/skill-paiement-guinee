# FeexPay — fiche d'intégration (pay-in)

Doc officielle : https://docs.feexpay.me (prends la **version v2** : sections payin, statut, webhook, sandbox).
Légende : ✅ vérifié · 🟡 indicatif · ❓ non confirmé (voir SKILL.md). « 📄 doc v2 » = recopié de la doc officielle v2 (page « API - Payin », transmise le 31/10/2026), non exécuté ici.
Autre source : **code source du SDK PHP officiel `feexpay/feexpay-php` 3.0.0** (installé et lu le 31/10/2026 ; aucune requête réelle envoyée).

## Généralités

- ✅ Hôte : `https://api-v2.feexpay.me`. L'ancien hôte `https://api.feexpay.me` n'est plus disponible : un vieux code ou un vieux SDK ne marche plus.
- ✅ 📄 Authentification : en-tête `Authorization: Bearer <clé API>` (la clé commence par `fp_`). Sans cet en-tête, la requête est refusée. Le SDK ajoute aussi `Accept: application/json` et `Content-Type: application/json`.
- 📄 Montant : **minimum 100, maximum 2 000 000 XOF** par transaction. Refuse côté serveur, avant l'appel, tout montant hors de ces limites.
- 📄 Pays couverts par le pay-in : Bénin, Togo, Côte d'Ivoire, Congo Brazzaville, Sénégal, Burkina Faso (réseaux et URL propres à chaque pays : voir la doc v2, onglet du pays).

## Pay-in mobile money — Bénin (📄 doc v2)

Une URL par réseau, `POST` :

| Réseau | URL |
| --- | --- |
| MTN Bénin | `https://api-v2.feexpay.me/api/transactions/public/requesttopay/mtn` |
| Moov Bénin | `https://api-v2.feexpay.me/api/transactions/public/requesttopay/moov` |
| Celtiis Bénin | `https://api-v2.feexpay.me/api/transactions/public/requesttopay/celtiis_bj` |
| Coris Bénin (wallet) | listé dans la doc, URL ❓ : lis l'onglet Coris |

Corps JSON :

| Champ | Obligatoire | Description | Exemple |
| --- | --- | --- | --- |
| `phoneNumber` | oui | `229` + numéro à 10 chiffres commençant par `01` | `2290166000000` |
| `amount` | oui | montant | `100` |
| `shop` | oui | identifiant de la boutique | — |
| `first_name` | non | prénom du client | — |
| `last_name` | non | nom du client | — |
| `description` | non | **sans caractères spéciaux** | `Achat de produit` |
| `callback_info` | non | information renvoyée dans le webhook : mets-y **ton identifiant interne de paiement** | `pay_12345` |

Exemple Node (axios), d'après la doc :
```js
const { data } = await axios.post(
  'https://api-v2.feexpay.me/api/transactions/public/requesttopay/mtn',
  { shop: process.env.FEEXPAY_SHOP_ID, amount: 1000, phoneNumber: 2290166000000,
    description: 'Commande 1234', callback_info: `pay_${payment.id}` },
  { headers: { Authorization: `Bearer ${process.env.FEEXPAY_API_KEY}` }, timeout: 60000 },
);
// data.reference -> provider_ref ; data.status vaut 'PENDING' à ce stade
```
La doc envoie `phoneNumber` comme nombre ; garde ce format (13 chiffres, sans risque d'arrondi en JavaScript).

Réponse (📄) : `reference`, `message` (`Accepted`…), `status` (**`PENDING`**), `amount`, `description`, `callback_info`, `phoneNumber`.
- `PENDING` veut dire « demande envoyée au client », **pas** « payé ». Enregistre `reference` comme `provider_ref`, passe le paiement à `processing`, puis attends le webhook ou interroge le statut.
- **Celtiis** : la réponse peut contenir en plus une charge SOAP de l'opérateur (`normal_response`, `response_operator`, `statusCode`). Ne t'en sers pas pour décider : seul l'endpoint de statut fait foi.

## Statut d'une transaction

- ✅ (SDK) `GET https://api-v2.feexpay.me/api/transactions/public/single/status/{reference}`, même en-tête Bearer. Réponse : `amount`, `status`, `reference`, `phoneNumber`.
- Statuts : `SUCCESSFUL`, `PENDING`, `FAILED` (SDK) ; `TIMEOUT` d'après la doc du SDK Flutter v2 (« statut inconnu après 2 minutes, le paiement peut encore aboutir »).
- Vérifie aussi que `shop` (s'il est présent) correspond à ta boutique (recommandation du SDK Flutter v2).
- Correspondance : `SUCCESSFUL` → `succeeded` · `FAILED` → `failed` · `PENDING` / `TIMEOUT` → `processing` · autre → `inconnu`.

## Autre endpoint vu dans le SDK PHP (✅ lu dans le code)

Le SDK PHP 3.0.0 n'utilise pas les URL par réseau ci-dessus : il appelle `POST /api/transactions/requesttopay/integration` avec le réseau dans le corps (`reseau`: `MTN`, `MOOV`…) et un champ `reference` (ton identifiant). Ce chemin **attend la validation du client** (le SDK ne met aucun délai maximal).
Recommandation : en code HTTP direct, utilise les **URL par réseau de la doc v2** (réponse immédiate `PENDING`). Si tu utilises le SDK PHP, mets un délai côté serveur et traite son dépassement comme « en cours » (le rattrapage conclura).

```php
// 🟡 README officiel ; signatures ✅ vérifiées dans le code
use Feexpay\FeexpayPhp\FeexpayClass;
$fp = new FeexpayClass(config('services.feexpay.shop_id'), config('services.feexpay.api_key'), config('services.feexpay.callback_url'), config('services.feexpay.mode')); // LIVE ou SANDBOX
$reference = $fp->paiementLocal($order->amount, $phone, 'MTN', $nom, $email, "pay_{$payment->id}", (string) $payment->id);
$statut = $reference ? $fp->getPaiementStatus($reference) : $fp->getLastError();
```

## Non confirmé (❓) — à lire dans la doc v2 avant de coder

- **Le webhook** : la doc confirme qu'il existe (il renvoie `callback_info`), mais pas ici le format du corps ni la méthode de vérification. Tant que ce n'est pas confirmé : le webhook est un **signal**, ton serveur appelle l'endpoint de statut et décide sur sa réponse (`status`, `amount`, `shop`). Si la page de la doc n'est pas accessible, **demande à l'utilisateur de copier la section « Webhook »** (voir SKILL.md, étape 3).
- URL et réseaux exacts des autres pays (Togo, Côte d'Ivoire, Congo, Sénégal, Burkina Faso) et de Coris Bénin : onglet de chaque pays dans la doc v2.
- Retrouver un paiement par ton identifiant (`callback_info`) si la réponse de création n'est jamais arrivée.
- Numéros et montants de test en sandbox.
- 🟡 Si l'API répond `ERR_IP_NOT_AUTHORIZED` : ajoute l'IP publique du serveur dans la liste blanche du tableau de bord (section « IP whitelist »).

## Opérations prises en charge

| Opération | Niveau | Détail |
| --- | --- | --- |
| Pay-in mobile money | 📄 requête Bénin / ✅ statut / ❓ webhook | voir plus haut |
| Carte | ✅ requête | SDK : `paiementCard(...)` → `POST /api/transactions/public/requesttopay/init`, renvoie une URL de paiement (`url` / `payment_url`) et une `reference` ; lu dans le code, non exécuté |
| Payout | 🟡 | la doc a une section « payout API » ; endpoints et champs ❓ : lis la doc v2 avant de coder |
| Remboursement | ❓ | rien de confirmé : ne code pas `refundPayment` sans doc |
| Récurrent | ❓ | rien de confirmé |
| Liste des transactions (réconciliation) | 🟡 | export depuis le tableau de bord ; API de liste ❓ |
