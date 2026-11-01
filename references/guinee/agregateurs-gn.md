# Agrégateurs et PSP couvrant la Guinée

Légende : ✅ vérifié (doc ou API ouverte) · 🟡 indicatif · 📄 doc recopiée · ❓ non confirmé · **NON TROUVÉ**.
Relevé du **1er novembre 2026** — voir `../verifications.md`.

> ⚠️ Aucun de ces acteurs n'a été vérifié au niveau de l'API dans cette recherche : ce sont des **pistes classées**, pas des fiches d'intégration. Pour en retenir un, ouvre sa doc et remplis `../detection-agregateur.md` ligne par ligne. Tant que ce n'est pas fait, tout est 🟡.

## Pourquoi un agrégateur plutôt qu'une intégration directe

| | Intégration directe par opérateur | Agrégateur |
| --- | --- | --- |
| Contrats | un contrat marchand **par** opérateur | un seul contrat |
| Intégration | une par rail (Orange, MTN, Wave, carte…) | une seule API |
| Webhooks | un format par opérateur | un format unifié |
| Frais | frais opérateur seuls | frais opérateur **+ marge agrégateur** |
| Dépendance | faible | forte (intermédiaire en plus) |
| Délai de mise en route | long (KYA local par opérateur) | plus court |

Pour un projet qui doit encaisser Orange Money **et** MTN **et** la carte, l'agrégateur est le choix par défaut. Pour Orange Money seul, l'intégration directe est plus rentable.

## Acteurs identifiés

### Paycard (Guinée) — 🟡

- Paiement marchand par **USSD `*717#`**, lancé en **novembre 2024** selon la presse guinéenne (guineematin.com).
- Positionnement local, cas d'usage orienté commerces et paiement du quotidien.
- ❓ **Aucune documentation API ouverte** dans cette recherche : rien sur un checkout web, des webhooks ou un sandbox.
- À vérifier en premier : existe-t-il un **canal e-commerce** (pas seulement USSD) ?

### CinetPay — 🟡

- Agrégateur panafricain historique (Côte d'Ivoire, Sénégal, Cameroun, Mali…), API de collecte documentée, page de paiement hébergée, webhooks signés.
- ❓ **Couverture Guinée et devise GNF non vérifiées** ici : la liste de pays doit être lue sur leur doc, rail par rail.
- Piste la plus crédible pour un projet Laravel/Express francophone : écosystème francophone, doc en français.

### Paynote — 🟡

- Agrégateur orienté Afrique de l'Ouest, API de collecte et payout.
- ❓ Couverture Guinée, devises, frais : non vérifiés.

### Intégrateurs locaux (Fallcon Tech, tigsi sarl) — 🟡

- Sociétés guinéennes citées comme intégrateurs de solutions de paiement.
- Intérêt : elles connaissent les contraintes locales (KYA, agences, réseau). Utilité : **mise en relation** avec les opérateurs, pas forcément API self-service.
- ❓ Aucune doc technique publique trouvée.

### Coris Money (Coris Bank International Guinée) — 🟡

- Service de transfert lancé en **février 2026** selon la presse.
- Nouveau sur le marché : pas d'API marchand documentée publiquement à ce jour. ❓

## Frais et ordres de grandeur

- Commission de collecte mobile money en Guinée : ordre de **2 à 4 %** selon l'opérateur et le volume. 🟡 (relevé de presse / comparatifs, non contractuel)
- **Ne fixe jamais une marge commerciale sur cet ordre de grandeur** : demande le barème écrit à l'opérateur ou à l'agrégateur, il dépend du volume, du type de marchand et du pays. Orange indique explicitement « speak to your local Orange operator ».
- Devise : **GNF**, montant entier.

## Grille de sélection (à remplir avant de choisir)

| Critère | Pourquoi ça compte | Paycard | CinetPay | Paynote | Direct Orange |
| --- | --- | --- | --- | --- | --- |
| Couvre Orange Money GN | rail n°1 du marché | ? | ? | ? | ✅ |
| Couvre MTN MoMo GN | rail n°2 | ? | ? | ? | ❌ |
| Carte Visa | paiement à l'étranger, parents expatriés | ? | ? | ? | ❌ |
| Devise GNF | sinon conversion imposée | ? | ? | ? | 🟡 |
| Page hébergée | évite le périmètre PCI | ? | ? | ? | ✅ |
| Webhook signé | sécurité, règle d'or 4 | ? | ? | ? | ❓ |
| Endpoint de statut | **obligatoire**, sinon on ne code pas | ? | ? | ? | ❓ |
| Remboursement | annulation d'inscription | ? | ? | ? | ❓ |
| Payout | reversement à l'école | ? | ? | ? | ❓ |
| Sandbox | tests niveau 3 | ? | ? | ? | ❓ |
| Frais écrits | marge | ? | ? | ? | ? |
| Doc en français | support | ? | ✅ | ? | 🟡 |

Remplis une ligne = une source ouverte. Une case qui reste `?` après recherche devient **NON TROUVÉ**, jamais une supposition.

## Rappel : ce que l'agrégateur ne change pas

Les 7 règles d'or restent identiques. Un agrégateur ne dispense pas de :

- vérifier le webhook (corps brut, signature, temps constant) ;
- revérifier par l'endpoint de statut avant de marquer payé ;
- une machine à états atomique en base ;
- la réconciliation quotidienne (l'agrégateur, lui, a toujours ses propres chiffres).
