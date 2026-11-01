# Ecobank Guinée / Visa — fiche d'intégration (carte)

Légende : ✅ vérifié · 🟡 indicatif · 📄 doc recopiée · ❓ non confirmé · **NON TROUVÉ** aucune source.
Vérifié le **1er novembre 2026** — voir `../verifications.md`.

> ⚠️ **Conclusion de la recherche : il n'existe pas de documentation publique d'une passerelle marchande self-service pour Ecobank Guinée.** Un encaissement Visa en Guinée passe en pratique par un **PSP / agrégateur** (`agregateurs-gn.md`), pas par une intégration directe avec la banque.

## Ce qui est confirmé

- ✅ Ecobank est présent en **Guinée Conakry** (site pays : https://ecobank.com/gn/), avec offres entreprises et particuliers.
- ✅ **3-D Secure** est en place pour les porteurs de carte Ecobank : le paiement en ligne déclenche une validation supplémentaire (code envoyé au client). C'est ce qui rend l'acceptation carte possible sans transfert de responsabilité.
  Source : https://ecobank.com/gn/business-banking/payments-and-collections
- ✅ Ecobank propose l'**acceptation de paiements** côté commerçant (POS « cashless », Ecobank Mobile, Internet Banking) et un **programme fintech** pour partenaires.
  Source : même page

## Ce qui n'est pas confirmé

- **NON TROUVÉ — une API marchande publique** (checkout, tokenisation, endpoints, webhooks) pour Ecobank Guinée. La page « Payments and collections » est une page marketing : elle décrit une offre commerciale, pas une spécification technique.
- ❓ Le **canal d'intégration réel** : passerelle carte régionale du groupe Ecobank ? partenaire acquéreur ? mise en relation manuelle par l'agence ? — à demander à l'agence Ecobank Guinée, service entreprises.
- ❓ Les **frais** d'acceptation carte (commission MDR, abonnement terminal, frais de mise en service).
- ❓ Le support de **Visa** spécifiquement en e-commerce international (une carte Visa étrangère peut-elle payer un marchand guinéen ?).
- ❓ L'existence d'un **sandbox**.

## Comment encaisser la carte en pratique

Deux chemins réalistes, dans cet ordre :

### A. Via un agrégateur qui couvre la carte en Guinée (recommandé)

L'agrégateur expose une **page de paiement hébergée** ou un champ carte, et prend en charge le 3-D Secure, la tokenisation et la conformité PCI. Côté code : rien de spécifique à Ecobank, seulement l'adaptateur de l'agrégateur. Voir `agregateurs-gn.md`.

Avantage : pas de contrat acquéreur, pas de PCI-DSS à porter, un seul webhook pour tous les rails.
Limite : frais cumulés (agrégateur + réseau), et dépendance à la couverture réelle de la Guinée par l'agrégateur — à vérifier rail par rail.

### B. Contrat acquéreur direct avec Ecobank Guinée

Si le volume le justifie : demander à l'agence un contrat « acceptation e-commerce », l'accès à la passerelle et la documentation d'intégration. C'est un projet commercial de plusieurs semaines, pas une tâche de code.

## Ce qu'on ne fait jamais

- **Ne jamais manipuler un numéro de carte complet** dans le code du projet : pas de champ carte maison, pas de CVV stocké, pas de token maison. Si le projet veut un formulaire carte intégré, il faut une bibliothèque du PSP (iframe / champs hébergés) et un périmètre **PCI-DSS SAQ A**.
- Ne jamais considérer un `3-D Secure` réussi comme une preuve de capture : la capture se confirme par l'API du PSP (règle d'or 3).
- Ne jamais écrire « paiement par carte Visa » dans l'interface si aucun contrat d'acceptation n'est signé.

## Interface : ce que le client voit

- Carte refusée ≠ erreur technique : afficher « paiement refusé, essayez une autre carte » et laisser réessayer (nouvelle tentative, pas rejeu du même paiement).
- 3-D Secure abandonné par le client → statut `failed` (ou `cancelled` si c'est le client qui annule explicitement), jamais `succeeded`.
- Délai dépassé pendant le 3-D Secure → `processing`, et le rattrapage tranche.
