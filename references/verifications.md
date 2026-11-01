# Journal des vérifications — 1er novembre 2026 (Guinée)

Ce fichier dit **ce qui a été ouvert, lu et constaté**, et **ce qui ne l'a pas été**. Une ligne ✅ sans URL ici n'est pas une ligne ✅.

Le journal d'origine du pack (31 octobre 2026, Afrique de l'Ouest / FedaPay-KkiaPay-FeexPay) est conservé dans `journal-verifications-origine.md` et reste valable pour ces trois agrégateurs.

---

## ✅ Sources ouvertes aujourd'hui

| # | URL | Ce qui en a été lu | Sert à |
| --- | --- | --- | --- |
| 1 | https://developer.orange.com/apis/om-webpay | Liste des pays où Orange Money Web Payment est disponible — **Guinea Conakry y figure** ; exigence d'un marchand Orange Money enregistré (KYA) ouvert en agence locale ; validation du client par **OTP via USSD** | `guinee/orange-money-gn.md` |
| 2 | https://developer.orange.com/apis/om-webpay/faq | Confirmation de la disponibilité en Guinée ; cas d'usage listés, dont **« school fees »** ; les frais renvoient à l'opérateur local (« speak to your local Orange operator ») | `guinee/orange-money-gn.md`, `guinee/cas-usage-gestion-eleve.md` |
| 3 | https://momodeveloper.mtn.com/ | Présentation des produits MoMo (Request Payment, Refund, Payment Status, Account Balance, Transfer) | `guinee/mtn-momo-gn.md` |
| 4 | https://momodeveloper.mtn.com/api-documentation/getting-started | Inscription développeur, **4 produits souscriptibles** (Collection Widget, Collection, Remittances, Disbursements), clés primaire/secondaire sans expiration, **Sandbox Provisioning API** | `guinee/mtn-momo-gn.md` |
| 5 | https://www.wave.com/en/business/ | **Checkout API confirmée** (« Increase sales on your website… Wave's best-in-market APIs »), transferts en masse (1 % expéditeur), appli business | `guinee/wave-gn.md` |
| 6 | https://www.wave.com/fr/ | Page grand public : **aucune mention d'API** | `guinee/wave-gn.md` |
| 7 | https://ecobank.com/gn/business-banking/payments-and-collections | Présence Guinée Conakry, **3-D Secure** pour les porteurs, POS cashless, programme fintech — **aucune spécification d'API marchand** | `guinee/ecobank-visa-gn.md` |

## ❌ Sources tentées sans succès

| URL | Résultat | Conséquence |
| --- | --- | --- |
| https://docs.wave.com/ | **404** « Sorry, that page wasn't found » | pas de doc API Wave |
| https://docs.wave.com/api | **404** | idem |
| https://developers.wave.com | accès bloqué / page vide | idem |
| https://momodeveloper.mtn.com/API-collections | coquille d'application (SPA) : **aucune opération rendue** | endpoints MoMo restent 🟡 |
| pied de page MoMo « Open API is available in: … » | rendu en JavaScript, **non capturé** | **couverture Guinée non confirmée** |
| recherche « Prink paiement Guinée / mobile money / Africa payment » (FR + EN) | **aucun résultat pertinent** | `guinee/prink.md` = **NON TROUVÉ** |

## Ce que ce journal autorise à écrire

✅ **Orange Money Guinée est disponible en Guinée Conakry**, avec OTP USSD, et les frais de scolarité font partie des cas d'usage cités par l'opérateur.

❌ **On n'écrit pas** : « MTN MoMo est disponible en Guinée », « Wave est disponible en Guinée pour les marchands », « Ecobank Guinée a une API marchande », « Prink existe ».

## Ce qui reste à confirmer avant la production

| Sujet | Qui peut confirmer | Bloque quoi |
| --- | --- | --- |
| Endpoints, champs et statuts exacts d'Orange Money Web Payment | doc `om-webpay` (référence API) | le code pay-in |
| Signature / authentification des notifications Orange | doc ou support Orange | la route webhook |
| Frais Orange Money Guinée (barème écrit) | agence Orange Guinée | la marge |
| Sandbox Orange en Guinée (existe / n'existe pas) | agence Orange Guinée | les tests niveau 3 |
| Couverture MoMo Guinée + devise GNF | support MTN MoMo | le rail MTN |
| Couverture Wave Guinée (marchand) + accès doc API | support Wave marchand | le rail Wave |
| Canal d'acceptation carte pour un marchand guinéen | agence Ecobank Guinée, service entreprises | le rail carte |
| Nature exacte de « Prink » | l'utilisateur (lien, contrat, interlocuteur) | tout |

## Méthode

Chaque ligne de ce journal vient d'une page effectivement ouverte dans cette session. Aucune information n'a été complétée depuis la mémoire du modèle, ni depuis une page marketing prise pour une spécification technique. Quand une page n'a pas pu être lue (JavaScript, 404, blocage), elle est listée en ❌ et l'information correspondante reste 🟡 ou ❓ dans les fiches.

Règle appliquée, reprise de `detection-agregateur.md` : « Si tu ne la trouves pas, écris NON TROUVÉ et dis-le à l'utilisateur. Ne complète jamais un trou avec ce qui *devrait* marcher. »
