# Orange Money Guinée — fiche d'intégration (pay-in)

Légende : ✅ vérifié · 🟡 indicatif (doc / API standard, non exécuté) · 📄 doc recopiée · ❓ non confirmé.
Vérifié le **1er novembre 2026** — voir `../verifications.md`.

## Ce qui est confirmé

- ✅ **Orange Money Web Payment est officiellement disponible en Guinée Conakry.** La liste des pays de la page produit inclut « Guinea Conakry » (avec Mali, Cameroun, Côte d'Ivoire, Sénégal, Madagascar, Botswana, Guinée Bissau, Sierra Leone, RD Congo, RCA, Liberia).
  Source : https://developer.orange.com/apis/om-webpay
- ✅ Le **marchand** doit être un marchand Orange Money **enregistré et conforme KYA**, ouvert dans une **agence Orange locale**. L'inscription en ligne ne suffit pas.
  Source : même page + https://developer.orange.com/apis/om-webpay/faq
- ✅ Le client final **valide le paiement par un code OTP reçu via le service USSD Orange Money**. Ce n'est donc pas un webhook « silencieux » : il y a une action utilisateur à la fin.
  Source : https://developer.orange.com/apis/om-webpay
- ✅ La FAQ cite explicitement **les frais de scolarité** (« school fees ») parmi les cas d'usage couverts. C'est exactement le cas de `gestion_Eleve`.
  Source : https://developer.orange.com/apis/om-webpay/faq
- ✅ Le parcours se fait par **redirection** vers une page Orange (URL de paiement générée côté serveur), avec des URL de retour et de notification fournies par le marchand.
- 📄 Les **frais** ne sont pas publiés sur le portail développeur : « speak to your local Orange operator ». À obtenir par écrit auprès d'Orange Guinée avant de fixer une marge.

## Ce qui n'est pas confirmé ici (à lire dans la doc avant de coder)

- ❓ Les **chemins exacts** des endpoints (`POST /webpayment`, `GET /webpayment/{order_id}/status` selon les versions), les noms de champs (`merchant_key`, `currency`, `reference`, `notif_url`, `return_url`, `cancel_url`, `lang`) et la forme de la réponse. **Ouvre la référence API de `om-webpay` et copie la section pay-in** ; ne code pas ces noms de mémoire.
- ❓ La **signature / authentification des notifications** Orange. Si la doc ne la décrit pas clairement : applique l'**échec fermé** (règle d'or 3) — la notification ne sert que de signal, la décision vient de l'appel de statut.
- ❓ La **liste complète des statuts** renvoyés (et lesquels sont définitifs).
- ❓ Les **montants minimum et maximum** en GNF, et le délai d'expiration d'une demande de paiement.
- ❓ L'existence d'un **endpoint de remboursement** côté Guinée.
- ❓ Un **sandbox**. Orange ne propose pas toujours d'environnement de test sur tous les pays ; demande-le à ton interlocuteur Orange Guinée. S'il n'y en a pas : la première intégration se fait avec un vrai paiement de **5 000 GNF**.

## Parcours recommandé

**Page de paiement Orange** (parcours 1) — pas de gestion de PIN côté appli, pas de secret dans le mobile :

1. le serveur crée la commande en base (`pending`), calcule le montant **depuis sa base**, en GNF entier ;
2. le serveur appelle l'API Orange pour obtenir l'**URL de paiement** (avec `reference` = ton identifiant de commande, `notif_url`, `return_url`, `cancel_url` en HTTPS) ;
3. le client est redirigé vers cette URL, saisit son numéro, reçoit l'OTP par USSD et valide ;
4. Orange appelle ta `notif_url` **et** redirige le client vers `return_url` ;
5. dans les deux cas : **on ne fait pas confiance au message**. On lit la référence, on appelle l'endpoint de **statut**, et c'est cette réponse qui déclenche `appliquerTransition`.

Le parcours « paiement direct » (le client saisit son numéro dans ton appli, Orange envoie une demande sur son téléphone) existe aussi côté API Orange : 🟡 à confirmer pour la Guinée avant de le proposer.

## Webhook (route serveur)

```text
POST /webhooks/orange-money
  corps brut conservé (express.raw / $request->getContent())
  → vérifier l'authentification si la doc la décrit (sinon : échec fermé)
  → extraire la référence de commande
  → doublon ? (table webhook_events, contrainte unique sur l'id d'événement ou la référence + statut)
  → appeler getPaymentStatus(reference)      ← la vérité
  → appliquerTransition(statut traduit)
  → répondre 200 vite, le travail lourd part en outbox / file
```

Le webhook Orange peut arriver **avant** le retour du client, ou jamais (client qui ferme l'onglet). Le **rattrapage** (toutes les 2–5 min sur les `pending`) est donc obligatoire, pas optionnel.

## Correspondance des statuts

À remplir **après** lecture de la doc, dans une seule constante commentée :

```js
// À CONFIRMER : doc om-webpay, section statuts (non vérifié le 01/11/2026)
const STATUTS_ORANGE = {
  // 'SUCCESS'  : 'succeeded',
  // 'FAILED'   : 'failed',
  // 'CANCELED' : 'failed',
  // 'PENDING'  : 'processing',   // ≠ échec
  // 'EXPIRED'  : 'expired',
};
```

Tant que cette table n'est pas confirmée, tout statut inconnu doit tomber dans `inconnu` et **ne pas** faire échouer la commande, et **ne pas** la marquer payée.

## Opérations prises en charge

| Opération | Niveau | Détail |
| --- | --- | --- |
| Pay-in Orange Money (page hébergée) | 🟡 | disponible en Guinée ✅ ; endpoints à confirmer ❓ |
| Pay-in paiement direct (OTP poussé) | ❓ | à confirmer pour la Guinée |
| Statut d'une transaction | ❓ | indispensable — sans lui, on ne code pas |
| Notification / callback | 🟡 | URL à fournir ; vérification de signature à confirmer |
| Remboursement | ❓ | ne pas implémenter sans doc |
| Payout / versement | ❓ | ne pas implémenter sans doc |
| Carte | ❌ | hors périmètre Orange Money |

## Compte marchand (le vrai prérequis)

- Souscription « Paiement Marchand » Orange Guinée : https://orange-guinee.com/fr/formulaire-de-souscription-au-paiement-marchand-
- Candidature API développeur : https://developer.orange.com/products/payment-financial-services/apply-orange-money/
- Pièces à prévoir côté marchand : registre de commerce, NIF, coordonnées bancaires, pièce d'identité du représentant. 🟡 (à confirmer avec l'agence)

## Cas `gestion_Eleve`

Les frais de scolarité sont un cas d'usage explicitement listé par Orange Money. Utilise la **référence de paiement = numéro d'inscription + échéance** (`INS-2026-0147-T1`), jamais le nom de l'élève seul : deux élèves peuvent porter le même nom, et le rapprochement manuel qui suit doit être sans ambiguïté.
