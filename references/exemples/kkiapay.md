# KkiaPay — fiche d'intégration (pay-in)

Doc officielle : https://docs.kkiapay.me (index pour IA : https://docs.kkiapay.me/v1/llms.txt ; chaque page existe en Markdown en ajoutant `.md` à l'URL).
Légende : ✅ vérifié · 🟡 indicatif · ❓ non confirmé (voir SKILL.md).
Version testée le 31/10/2026 : SDK Node `@kkiapay-org/nodejs-sdk` **1.0.7** (API simulée, aucune requête réelle).

Principe : un **widget** côté client encaisse, puis le **serveur vérifie** la transaction. Sans vérification serveur, n'importe qui peut simuler un succès.

## Les clés

🟡 Tableau de bord → Développeurs / Clés API : clé **publique**, clé **privée**, **secret**, en sandbox et en live.
- Clé publique : la seule autorisée dans l'appli ou le navigateur.
- Clé privée et secret : **serveur uniquement**.

## Côté client : le widget

🟡 Web (paquet `kkiapay`, d'après la doc React / Next.js) :
```js
import { openKkiapayWidget, addKkiapayListener, removeKkiapayListener } from 'kkiapay';
openKkiapayWidget({ amount: 4000, api_key: '<CLÉ_PUBLIQUE>', sandbox: true, phone: '97000000', data: '<id_paiement_interne>' });
addKkiapayListener('success', (response) => { /* envoyer l'identifiant de transaction au serveur, c'est tout */ });
// retirer l'écouteur au démontage : removeKkiapayListener('success', handler)
```
❓ Le champ exact qui transporte notre référence interne (`data` ?) et la forme de `response` : à lire dans la doc du SDK utilisé (web, Flutter, React Native…).
Le montant du widget vient du client : le serveur compare le montant **vérifié** au prix de la commande.

## Côté serveur : vérifier

✅ Node (import, initialisation, URL, en-têtes et corps testés avec une API simulée) :
```js
const { kkiapay } = require('@kkiapay-org/nodejs-sdk');
const k = kkiapay({
  privatekey: process.env.KKIAPAY_PRIVATE_KEY,
  publickey: process.env.KKIAPAY_PUBLIC_KEY,
  secretkey: process.env.KKIAPAY_SECRET,
  sandbox: process.env.KKIAPAY_SANDBOX === 'true',
});
try {
  const tx = await k.verify(transactionId);
} catch (e) {
  // ✅ testé : verify() LÈVE une erreur si la transaction est introuvable -> traiter comme « non payé », pas comme un crash
}
```
✅ Ce que fait `verify()` (utile pour PHP, Python, Dart côté serveur…) :
- `POST https://api-sandbox.kkiapay.me/api/v1/transactions/status` (sandbox) ou `https://api.kkiapay.me/api/v1/transactions/status` (live)
- en-têtes `x-api-key: <publique>`, `x-private-key: <privée>`, `x-secret-key: <secret>`
- corps `{ "transactionId": "..." }`

🟡 Réponse (exemples de la doc et du SDK Python communautaire) : `status` (`SUCCESS`, `FAILED`…), `amount`, `fees`, `source`, `transactionId`, `performed_at`… ❓ La liste complète des statuts : lis la doc.
Correspondance : `SUCCESS` → `succeeded` · `FAILED` → `failed` · transaction introuvable → rester `processing` (le client n'a peut-être pas fini) · autre valeur → `inconnu`.

🟡 Python : paquet communautaire `kkiapay` (`Kkiapay(public, private, secret, sandbox=True).verify_transaction(id)`), non officiel ; l'appel HTTP direct ci-dessus est souvent plus sûr.

Enregistre `transactionId` comme `provider_ref` avec la contrainte `UNIQUE (provider, provider_ref)` : un même identifiant ne paie jamais deux commandes (c'est la vraie protection contre le rejeu d'un identifiant de transaction).

## Webhook

- 🟡 Créé dans le tableau de bord : URL, événements, et un **secret de hachage** que tu choisis. KkiaPay attend une réponse 2xx et réessaie jusqu'à 5 fois.
- 🟡 Corps : `transactionId`, `isPaymentSucces` (orthographe de l'API), `amount`, `fees`, `method`, `performedAt`, `event` (`transaction.success` / `transaction.failed`), `failureCode`, `failureMessage`. Pas d'identifiant d'événement : `event_key` = `transactionId + event`.
- ❓ **La vérification exacte.** La doc montre un en-tête `x-kkiapay-secret` contenant le secret, mais parle aussi de « signature ». Tant que ce n'est pas confirmé, fais les deux protections :
  1. compare `x-kkiapay-secret` au secret configuré, en temps constant (Node : vérifier d'abord la longueur, puis `crypto.timingSafeEqual`) ; s'il ne correspond pas → `401` ;
  2. **dans tous les cas**, appelle `verify(transactionId)` et décide uniquement sur sa réponse.
  Ainsi, même si la méthode de signature réelle est différente, un faux webhook ne peut rien valider.

## Opérations prises en charge

| Opération | Niveau | Détail |
| --- | --- | --- |
| Pay-in mobile money (widget) | ✅ serveur / 🟡 widget | vérification serveur testée ; options du widget d'après la doc |
| Carte | 🟡 | méthode `CARD` dans les webhooks ; passe par le widget |
| Remboursement | ✅ appel / ❓ conditions | le SDK Node 1.0.7 a `k.refund(transactionId)` → `POST /api/v1/transactions/revert` (lu dans le code) ; remboursement partiel, délais et frais : ❓ voir la doc |
| Payout | 🟡 | d'après le SDK Python, la planification de payout par API est arrêtée depuis le 20/02/2023 et se fait sur le tableau de bord : ne code pas de payout automatique sans doc récente qui dit le contraire |
| Récurrent | ❓ | rien de confirmé |
| Liste des transactions (réconciliation) | ❓ | pas d'API confirmée : export depuis le tableau de bord |
