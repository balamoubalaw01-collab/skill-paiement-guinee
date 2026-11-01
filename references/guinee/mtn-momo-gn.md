# MTN MoMo Guinée — fiche d'intégration (pay-in)

Légende : ✅ vérifié · 🟡 indicatif · 📄 doc recopiée · ❓ non confirmé.
Vérifié le **1er novembre 2026** — voir `../verifications.md`.

> ⚠️ **Point bloquant à lever avant tout code : la disponibilité de MTN MoMo en Guinée n'est pas confirmée.** Le portail développeur ne rend sa liste de pays qu'en JavaScript, et je n'ai pas pu la lire. Ne l'annonce pas comme disponible : demande la confirmation au support MTN MoMo (ou au responsable MoMo Guinée), et note-la dans `../verifications.md` avec la date.

## Ce qui est confirmé (sur l'API, pas sur la Guinée)

- ✅ Le produit existe : **MTN MoMo Open API**, portail https://momodeveloper.mtn.com/
- ✅ Quatre produits souscriptibles séparément :
  - **Collection Widget** (widget hébergé, le plus simple)
  - **Collection** (demande de paiement par API — celui qu'on veut pour un serveur)
  - **Remittances**
  - **Disbursements** (payout)
  Source : https://momodeveloper.mtn.com/api-documentation/getting-started
- ✅ Deux environnements : **sandbox** `https://sandbox.momodeveloper.mtn.com` · **production** `https://momoapi.mtn.com` (chemins par produit sous ce domaine).
- ✅ Chaque produit souscrit donne une **clé primaire et une clé secondaire**, sans expiration, à créer dans le profil développeur.
- ✅ Une **Sandbox Provisioning API** crée l'utilisateur API (`X-Reference-Id`) et la clé API de test — c'est ce qui permet d'obtenir des identifiants sandbox sans passer par un humain.
- ✅ Les notifications (callback) sont configurables par abonnement, avec une URL HTTPS.
- ✅ Devises supportées côté API : **EUR, XOF, XAF, GHS, UGX, RWF, ZAR, USD, ZMW, XCD** — voir le ❓ ci-dessous.

## Ce qui n'est pas confirmé

- ❓ **La Guinée fait-elle partie des marchés MoMo couverts par l'Open API ?** Le franc guinéen (**GNF**) n'apparaît pas dans la liste des devises ci-dessus. C'est un signal fort : soit la Guinée n'est pas couverte, soit elle est couverte avec une devise non listée. **À faire confirmer par MTN avant d'écrire une ligne de code.**
- ❓ Les chemins exacts (`/collection/v1_0/requesttopay`, `/collection/v1_0/requesttopay/{referenceId}`), les en-têtes (`X-Reference-Id`, `X-Target-Environment`, `Ocp-Apim-Subscription-Key`, jeton OAuth `Bearer`), la forme du corps (`amount`, `currency`, `externalId`, `payer.partyIdType`, `payer.partyId`). Ces noms sont 🟡 standards MoMo mais **non vérifiés ici** : lis la référence API du produit « Collection ».
- ❓ La liste complète des statuts (`PENDING`, `SUCCESSFUL`, `FAILED`) et le sens de chacun — notamment si `PENDING` peut rester définitivement bloqué.
- ❓ L'existence d'un remboursement (produit distinct ?) côté Guinée.

## Si la Guinée est confirmée : parcours recommandé

**Produit « Collection »** (API, pas le widget), pour garder le contrôle côté serveur :

1. générer un `referenceId` **UUID v4** côté serveur, et l'utiliser comme **clé d'idempotence** — MTN refuse un doublon sur le même `referenceId` ;
2. `POST requesttopay` avec `amount` (GNF entier, lu en base), `currency`, `externalId` = ton numéro de commande, `payer.partyId` = numéro au format international sans `+`, et `callbackUrl` si tu veux la notification ;
3. MTN répond **202 Accepted** (pas 200) : le paiement est *en cours*, pas réussi. Statut local = `processing` ;
4. le client reçoit une demande sur son téléphone et valide avec son **PIN MoMo** ;
5. notification → on ne la croit pas : `GET requesttopay/{referenceId}` tranche ;
6. si pas de notification sous ~60 s : le **rattrapage** interroge le statut toutes les 2–5 min jusqu'à expiration.

Le **Collection Widget** est plus rapide à intégrer (pas de gestion de statut côté serveur à écrire) mais il te lie à l'UI MTN et complique l'alignement avec la charte du projet.

## Pièges spécifiques MoMo

- `X-Reference-Id` doit être un **UUID v4 valide** ; réutiliser un UUID déjà utilisé renvoie une erreur, ce qui est en fait une **protection contre les doublons** — garde-le en base et réutilise-le pour un retry réseau, jamais pour un nouveau paiement.
- `partyIdType` vaut `MSISDN` pour un client ; le numéro doit être au format `224XXXXXXXXX` (indicatif Guinée **224**, sans `+`, sans espaces). 🟡
- Les clés primaire/secondaire servent à la **rotation** : en cas de fuite, on bascule sur la secondaire. Stocke les deux dans `.env`, jamais dans le code.
- Le jeton OAuth expire (~1 h) : mets-le en cache, ne le redemande pas à chaque appel.

```js
// Squelette — chemins et champs À CONFIRMER dans la référence API « Collection »
// avant exécution. Ne pas livrer tel quel.
const referenceId = crypto.randomUUID();          // UUID v4, persisté avec la commande
await fetch(`${MOMO_BASE}/collection/v1_0/requesttopay`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${token}`,
    'X-Reference-Id': referenceId,
    'X-Target-Environment': process.env.MOMO_ENV,          // 'sandbox' | 'mtn guinea'
    'Ocp-Apim-Subscription-Key': process.env.MOMO_KEY_COLLECTION,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    amount: String(order.montant_gnf),                      // lu en base, entier
    currency: 'GNF',                                        // ❓ devise à confirmer
    externalId: order.numero,
    payer: { partyIdType: 'MSISDN', partyId: telephone },   // 224XXXXXXXXX
    payerMessage: `Scolarite ${order.numero}`,
    payeeNote: 'Merci',
  }),
  signal: AbortSignal.timeout(30_000),
});
```

## Décision

| Scénario | Action |
| --- | --- |
| MTN confirme la Guinée + GNF | intégrer le produit « Collection » comme second rail, derrière la même interface que Orange Money |
| MTN ne couvre pas la Guinée (ou pas en GNF) | **ne pas intégrer** ; couvrir MTN via un agrégateur (`agregateurs-gn.md`) |
| Pas de réponse du support | traiter comme ❓ : ne pas annoncer MTN à l'utilisateur comme disponible |
