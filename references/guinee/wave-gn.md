# Wave Guinée — fiche d'intégration

Légende : ✅ vérifié · 🟡 indicatif · 📄 doc recopiée · ❓ non confirmé · **NON TROUVÉ** aucune source.
Vérifié le **1er novembre 2026** — voir `../verifications.md`.

> ⚠️ **Deux inconnues distinctes, à ne pas mélanger :**
> 1. **Wave en Guinée** — présence grand public rapportée par des sources non officielles seulement.
> 2. **Wave Checkout API** — l'API existe officiellement, mais **sa documentation publique n'a pas pu être ouverte**.

## Ce qui est confirmé

- ✅ **Wave propose une API Checkout pour les marchands.** La page business annonce : « Increase sales on your website… Wave's best-in-market APIs », avec une API de paiement en ligne, les **transferts en masse** (frais expéditeur 1 %), l'appli business et les encaissements.
  Source : https://www.wave.com/en/business/
- ✅ La page grand public (https://www.wave.com/fr/) ne mentionne **aucune API** : le parcours marchand passe par la page business.
- ✅ Wave communique « 1 M+ d'utilisateurs actifs de l'API ». 🟡 (chiffre marketing, non audité)

## Ce qui n'est pas confirmé

- **NON TROUVÉ — la documentation technique de l'API Wave.** Tentatives le 01/11/2026 :
  - `https://docs.wave.com/` → **404** « Sorry, that page wasn't found »
  - `https://docs.wave.com/api` → **404**
  - `https://developers.wave.com` → accès bloqué / page vide
  Conséquence : **aucun endpoint, en-tête, format de signature ou liste de statuts n'est disponible**. On ne peut pas coder l'intégration, seulement la préparer derrière une interface.
- ❓ **La disponibilité de Wave en Guinée.** Les listes publiques anciennes (mi-2025) citent Sénégal, Côte d'Ivoire, Ouganda, Gambie, Sierra Leone, Mali — **la Guinée n'y figure pas**. Un post social (~7 mois) annonce l'arrivée de Wave à Conakry, ce qui est une **piste, pas une source**. À faire confirmer par Wave (support marchand) avant de promettre ce rail à l'utilisateur.
- ❓ Le **mode de collecte** en Guinée : transfert P2P grand public, ou vrai compte marchand avec Checkout ? Les deux n'ont pas les mêmes implications (pas de webhook fiable dans le premier cas).

## Comment débloquer (dans cet ordre)

1. **Demander l'accès à la doc API au support Wave** (canal marchand) : ils fournissent un accès documenté + des clés sandbox aux marchands inscrits. C'est la voie normale, pas un contournement.
2. **Demander en même temps la confirmation de la couverture Guinée** pour les comptes marchands, avec la devise **GNF**.
3. Une fois la doc en main, remplir la grille de `../detection-agregateur.md` **ligne par ligne avec l'URL source**, puis coder.

Si l'utilisateur obtient la doc : elle compte comme doc officielle. Note l'URL et la date dans `../verifications.md` et repasse les lignes 🟡 en ✅ après un test sandbox.

## Ce qu'on peut préparer sans la doc

- la **place du rail dans l'interface commune** (`../architecture.md`) : un adaptateur `WaveAdapter` qui lève `NotConfiguredError` tant que les clés manquent ;
- la **référence de paiement** (numéro de commande / d'échéance) qui servira d'`idempotency key` quel que soit le format final ;
- le **rattrapage** : quel que soit le rail, il interroge un statut toutes les 2–5 min sur les `pending`. Le nom de la fonction d'appel reste à écrire.

On **ne** prépare pas : les noms d'endpoints « probables », un faux format de signature, ou une table de statuts inventée.

## Tableau de décision

| Situation | Action |
| --- | --- |
| Doc + clés obtenues, Guinée confirmée | implémenter `WaveAdapter` (pay-in d'abord) |
| Guinée non couverte | retirer Wave du périmètre ; le dire clairement à l'utilisateur |
| Wave disponible seulement en P2P grand public | ❌ ne pas l'utiliser pour encaisser : pas de notification marchande fiable, rapprochement manuel obligatoire |
