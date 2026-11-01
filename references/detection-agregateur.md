# Analyser n'importe quel agrégateur à partir de sa documentation

À utiliser pour un agrégateur sans fiche (PayDunya, CinetPay, PawaPay, Flutterwave, Wave…), et pour **revérifier** une fiche existante quand la doc a pu changer.

Règle absolue : **chaque information vient d'une source que tu as ouverte**. Si tu ne la trouves pas, écris « NON TROUVÉ » et dis-le à l'utilisateur. Ne complète jamais un trou avec ce qui « devrait » marcher, ni avec ta mémoire.

## 1. Sources, par ordre de fiabilité

1. **Code source du SDK officiel** (npm, Packagist, PyPI, pub.dev, GitHub de l'éditeur) : ce que le SDK envoie vraiment. Installe-le et lis-le : URL de base, en-têtes, corps, chemins.
2. **Spécification OpenAPI** (`openapi.json`, `swagger.json`) si elle est publiée.
3. **Documentation officielle** du site de l'agrégateur. Cherche d'abord un index pour IA : `/llms.txt`, ou des pages en Markdown (`.md`). Si tu ne peux pas l'ouvrir, **demande à l'utilisateur** le lien ou un copier-coller des sections (liste dans SKILL.md, étape 3) : une page collée par l'utilisateur vaut la doc officielle, note l'URL et la date.
4. **Exemples officiels** (dépôts GitHub de l'éditeur, plugins officiels).
5. Tout le reste (blogs, forums, plugins tiers) : seulement comme piste à confirmer, jamais comme source.

Si deux sources se contredisent (fréquent : une doc en retard sur le SDK), note les deux et la date, et choisis ce qui sera **testé en sandbox**.

## 2. La fiche d'analyse à remplir

Pour chaque ligne : la valeur, la source (URL ou fichier du SDK + version) et le niveau (✅ / 🟡 / ❓ / NON TROUVÉ).

| Sujet | Ce qu'il faut trouver |
| --- | --- |
| Environnements | URL sandbox, URL live, comment obtenir un compte de test |
| Authentification | type (Bearer, Basic, en-têtes personnalisés, signature de requête), quelles clés, où les trouver |
| Devises | codes acceptés (`XOF`, `XAF`, `GNF`…), entiers ou décimaux |
| Pays et réseaux | liste par pays, **valeur exacte** à envoyer pour chaque réseau, format du numéro |
| Parcours | page hébergée, widget, paiement direct (PIN / USSD), OTP éventuel (Orange Money…) |
| Créer un paiement | endpoint, méthode, corps, champ « référence marchand », réponse |
| Statut | endpoint, liste **complète** des statuts, lesquels sont définitifs |
| Webhook | en-tête, algorithme de vérification, secret, horodatage / anti-rejeu, nouveaux essais, identifiant d'événement |
| Remboursement | existe ? partiel ? délai ? frais ? |
| Payout | existe ? clé d'idempotence ? solde nécessaire ? |
| Carte | page hébergée ? 3-D Secure ? |
| Récurrent | vraie API d'abonnement ou de carte enregistrée ? |
| Liste / export des transactions | pour la réconciliation |
| Limites | montant minimum et maximum, limite de requêtes, délai d'expiration d'un paiement, durée des appels (certains attendent la validation du client), liste blanche d'IP, plafonds avant validation KYC |
| Frais | qui les paie (client ou marchand), différences par réseau, comment ils apparaissent dans les réponses |
| Codes d'erreur | liste et sens |

Montre cette fiche à l'utilisateur **avant** de coder et liste clairement les lignes ❓ / NON TROUVÉ.

## 3. Transformer la fiche en adaptateur

- Les lignes ✅ et 🟡 deviennent du code (voir `architecture.md`).
- Une **capacité** ❓ ou NON TROUVÉ (remboursement, payout…) n'est **pas** implémentée : la méthode reste absente et `capacites()` ne la déclare pas.
- Un **détail** ❓ indispensable au pay-in (par exemple la vérification du webhook) est géré en **échec fermé** : le webhook ne sert que de signal, et la décision vient de l'endpoint de statut. Si l'endpoint de statut lui-même est ❓, **arrête-toi** et demande la doc à l'utilisateur ou au support de l'agrégateur : sans lui, aucune intégration n'est sûre.
- Les valeurs à confirmer restent dans une seule constante clairement commentée (`// À CONFIRMER : doc v2 section payin, non vérifié`), jamais éparpillées.

## 4. Valider en sandbox

Pour chaque ligne ✅ / 🟡 utilisée, prévois un test sandbox (voir `tests.md`). Une valeur 🟡 qui passe le test sandbox devient ✅ dans le rapport final, avec la date.
