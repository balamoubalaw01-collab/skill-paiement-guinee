---
name: skill-paiement-guinee
description: Intègre de A à Z un paiement mobile money ou carte en Guinée (Orange Money Guinée, MTN MoMo Guinée, Wave Guinée, Ecobank / Visa) dans une appli existante — pay-in, remboursement, payout, carte — avec webhooks sécurisés, machine à états, tests et réconciliation. À utiliser pour encaisser en GNF, brancher un agrégateur guinéen (Paycard, CinetPay, Paynote) ou sécuriser une intégration de paiement existante.
---

# Intégrer un paiement en Guinée

Tu branches l'appli de l'utilisateur sur un moyen de paiement guinéen. Tu fais le travail de bout en bout : analyse, code, tests, rapport. L'utilisateur fournit ses clés et valide.

Parle en français simple. Une ou deux phrases par étape, sans jargon inutile.

## Niveaux de confiance (à respecter partout)

Les fiches de ce skill marquent chaque information :

- ✅ **vérifié** : exécuté et testé, ou lu dans le code source d'un SDK officiel (version et date dans `references/verifications.md`) ;
- 🟡 **indicatif** : tiré de la doc officielle ou de l'API standard, non exécuté ici ;
- 📄 **doc officielle recopiée** : texte exact de la doc, non exécuté ; même niveau que 🟡 ;
- ❓ **non confirmé** : interdit en production sans confirmation ;
- **NON TROUVÉ** : aucune source trouvée. On ne l'invente pas.

Règles :

1. **Ne transforme jamais une supposition en code de production.** Une valeur ❓ se confirme dans la doc officielle (ou par un test sandbox) avant d'être codée.
2. Ce que tu ne peux pas confirmer : si c'est une **capacité** (remboursement, payout…), ne l'implémente pas ; si c'est un **détail** du pay-in (vérification du webhook, par exemple), code en **échec fermé** : le webhook ne sert que de signal, la décision vient de l'endpoint de statut.
3. Si l'endpoint de statut lui-même est inconnu : **arrête-toi** et demande la doc ou le support de l'opérateur. Sans lui, aucune intégration n'est sûre.
4. Si la version du SDK du projet diffère de celle testée, relance les scripts de `outils/` ou relis le code du SDK installé.

## Les 7 règles d'or (jamais d'exception)

1. La **clé secrète** reste sur le serveur : jamais dans l'appli mobile, le navigateur, Git ni les logs.
2. Le **montant** est calculé par le serveur à partir de sa base, jamais reçu du client.
3. Un paiement n'est réussi que si **le serveur l'a confirmé auprès de l'opérateur** (endpoint de statut). Jamais sur la foi de l'appli, d'une URL de retour ou d'un webhook seul.
4. Tout **webhook est authentifié** (signature ou secret, corps brut, comparaison à temps constant), puis revérifié par l'API.
5. **La base de données arbitre** : contraintes d'unicité, transitions atomiques, idempotence. Un même paiement, un même événement, une même commande ne sont traités qu'une fois, même en parallèle.
6. **Montant, devise et référence** sont contrôlés avant de marquer une commande payée.
7. **Honnêteté** : tu ne prétends jamais avoir testé un paiement réel si ce n'est pas le cas.

Si le code existant viole une de ces règles, dis-le clairement et corrige ce point.

## Le paysage guinéen (ce qui existe vraiment)

| Rail | Nature | Niveau | Fiche |
| --- | --- | --- | --- |
| **Orange Money Guinée** | API Web Payment / M Payment, OTP par USSD | ✅ disponible en Guinée Conakry, frais de scolarité explicitement cités dans la FAQ | `references/guinee/orange-money-gn.md` |
| **MTN MoMo** | API Open API (Collection, Disbursement), clés d'abonnement | 🟡 API confirmée, **disponibilité en Guinée ❓** | `references/guinee/mtn-momo-gn.md` |
| **Wave** | Checkout API + transferts en masse | 📄 API confirmée, docs publiques introuvables, **Guinée ❓** | `references/guinee/wave-gn.md` |
| **Ecobank Guinée / Visa** | 3-D Secure, POS, banque en ligne — pas de gateway marchand self-service documentée | 📄 → passer par un PSP | `references/guinee/ecobank-visa-gn.md` |
| **Prink** | — | **NON TROUVÉ** | `references/guinee/prink.md` |
| **Agrégateurs** (Paycard, CinetPay, Paynote…) | une seule intégration pour plusieurs rails | 🟡 comparatif | `references/guinee/agregateurs-gn.md` |

Devise : **GNF**, montant **entier** (le franc guinéen n'a pas de sous-unité). 🟡

**Choix par défaut** quand l'utilisateur n'a pas d'avis : un **agrégateur** qui couvre Orange Money + MTN + carte en une seule API (`references/guinee/agregateurs-gn.md`). Une intégration directe par opérateur = un contrat marchand et une intégration par rail.

## Déroulé

### 1. Comprendre le besoin

Pose seulement les questions dont la réponse n'est pas dans le projet :

- quel(s) rail(s) : Orange Money, MTN, Wave, carte Visa ? (ou « je ne sais pas » → agrégateur)
- quelles opérations : pay-in (toujours), remboursement, payout, carte, récurrent ?
- quel parcours : page hébergée de l'opérateur, ou paiement direct (le client saisit son numéro et valide par OTP / PIN) ?
- que paie le client et où est le prix ? (en GNF)
- a-t-il un **compte marchand** chez l'opérateur ou l'agrégateur, et ses clés de **test** ? (Ne lui demande jamais de coller une clé secrète dans la conversation : il la met lui-même dans `.env`.)

⚠️ En Guinée, le blocage le plus fréquent n'est pas technique : **le compte marchand**. Orange Money exige un marchand enregistré et conforme KYA, ouvert dans une agence Orange locale. Sans ça, pas de production, même avec du code parfait.

### 2. Analyser le projet → `references/adaptation-projet.md`

Détecte langage, framework, base et ORM, migrations, hébergement, tâches de fond, authentification, conventions, paiement existant. Résume en quelques lignes. Ouvre ensuite le guide du framework (`frameworks/`). Respecte l'architecture existante, réutilise ce qui existe, ne reconstruis rien sans raison.

### 3. Analyser l'opérateur

- Rail connu : lis la fiche dans `references/guinee/`.
- Rail inconnu, ou doute sur une fiche : `references/detection-agregateur.md`. Remplis la fiche d'analyse avec une source pour chaque ligne ; « NON TROUVÉ » plutôt qu'une invention.
- **Si tu ne peux pas ouvrir la doc** (site bloqué, contenu chargé en JavaScript, page qui demande une connexion, pas d'outil web dans la session), ne devine pas : **demande à l'utilisateur** le lien ou un copier-coller. Demande précisément :
  1. la section **pay-in / collecte** du pays voulu (URL, champs, en-têtes, exemple de réponse) ;
  2. la section **statut d'une transaction** (et la liste complète des statuts) ;
  3. la section **webhook / notification** (format du message et comment vérifier qu'il vient bien de l'opérateur) ;
  4. la section **remboursement**, **payout** ou **carte** si ces opérations sont demandées ;
  5. les **limites** (montants min/max en GNF) et le **mode test**.
  Rappelle-lui d'**enlever ses vraies clés** des exemples avant de coller. Une page collée compte comme doc officielle : note sa source (URL, date) dans le rapport.
- Montre à l'utilisateur ce qui est confirmé, ce qui ne l'est pas, et quelles opérations sont réellement possibles.

### 4. Architecture → `references/architecture.md`

Une interface commune (`createPayment`, `getPaymentStatus`, `verifyWebhook`, `refundPayment`, et selon les capacités `createPayout`…), un adaptateur par rail, un registre. Les opérations non prises en charge ou non confirmées **n'existent pas** dans l'adaptateur.

### 5. Données et machine à états → `references/machine-etats.md` et `references/fiabilite-paiements.md`

Statuts : `pending`, `processing`, `succeeded`, `failed`, `cancelled`, `expired`, `refunded`. Transitions autorisées en table, une seule fonction de transition atomique, anomalies dans une colonne séparée, journal `payment_events`, `webhook_events` pour les doublons, outbox pour les effets après commit.

### 6. Code serveur

- création du paiement (idempotente, montant lu en base, en GNF entier) ;
- une route webhook par rail (corps brut → authentification → doublon ? → statut chez l'opérateur → transition) ;
- `GET` du statut **de ta base** pour l'appli ;
- tâche de **rattrapage** (2 à 5 min) et tâche de **réconciliation** (`references/reconciliation.md`) ;
- remboursement / payout seulement si confirmés, avec les règles renforcées des payouts ;
- variables dans `.env.example` sans valeur, `.env` dans `.gitignore`, validation au démarrage ;
- logs sans secret, téléphone masqué, délai maximal explicite sur chaque appel HTTP (les API mobile money guinéennes sont lentes : 30 s minimum, jamais d'appel sans timeout).

### 7. Interface

Selon le guide du framework (Flutter : `frameworks/flutter.md`). L'appli n'utilise qu'une clé publique si besoin, interroge **ton** serveur, affiche : en attente, réussi, échoué (réessayer = nouvelle tentative), délai dépassé, erreur réseau. Double clic bloqué. Montants affichés en `GNF` avec séparateur de milliers.

### 8. Tests → `references/tests.md`

Niveau 1 (API simulée : réseau, délais, signatures, réponses inattendues), niveau 2 (vraie base : concurrence, désordre, doublons, remboursements), niveau 3 (sandbox avec les clés de test de l'utilisateur). Exécute les niveaux 1 et 2 toi-même et montre les résultats.

### 9. Mise en production (checklist pour l'utilisateur)

- [ ] compte marchand vérifié (KYA / KYC) chez l'opérateur ou l'agrégateur — sinon plafonds ou blocages ;
- [ ] clés **live** sur le serveur de production ;
- [ ] URL de notification **live** enregistrée en **HTTPS** (son secret diffère souvent de celui du test) ;
- [ ] IP du serveur autorisée si l'opérateur a une liste blanche ;
- [ ] rattrapage et réconciliation actifs, alertes reçues ;
- [ ] premier vrai paiement de petit montant (5 000 GNF par exemple) vérifié de bout en bout, puis remboursé si besoin ;
- [ ] aucune clé secrète dans l'appli publiée ni dans l'historique Git (sinon : la régénérer).

### 10. Rapport de validation honnête (obligatoire)

Termine par ce rapport, en français simple :

```
## Rapport d'intégration — <rail> dans <projet>

### Implémenté
- fichiers créés / modifiés (liste courte), routes, tables, tâches planifiées

### Testé (et comment)
- niveau 1 — API simulée : X tests, résultat
- niveau 2 — base <moteur> : X tests, résultat
- niveau 3 — sandbox : fait / pas fait (et par qui)
- paiement RÉEL : NON TESTÉ (sauf si l'utilisateur l'a fait et l'a confirmé)

### À tester avec de vraies clés
- …

### Non pris en charge par l'API de l'opérateur
- …

### Non confirmé dans la documentation (et comment c'est protégé)
- …

### À faire par toi
- variables à remplir dans .env
- URL du webhook à copier dans le tableau de bord
- étapes de test sandbox (3 à 5)
```

N'écris jamais « testé » pour quelque chose qui a seulement été écrit, et jamais « fonctionne en production » sans paiement réel confirmé par l'utilisateur.

## Erreurs fréquentes

- Valider la commande dans le callback de l'appli ou sur l'URL de retour.
- Mettre une clé secrète dans Flutter, React Native ou le front (même via `.env` embarqué ou `--dart-define`).
- Parser le JSON avant de vérifier la signature (elle se calcule sur le corps brut).
- « Lire puis écrire » un statut sans garde atomique ; livrer avant le commit.
- Traiter un délai dépassé, une erreur réseau, `PENDING` ou `TIMEOUT` comme un échec définitif.
- Relancer automatiquement un payout dont le résultat est inconnu.
- Croire un message d'erreur générique de l'API : regarder aussi le tableau de bord (compte non vérifié, plafond, solde, IP non autorisée).
- Oublier que les secrets et webhooks du mode test et du mode live sont différents.
- **Déduire la disponibilité d'un rail depuis une page marketing.** « Wave est en Guinée » vu sur un post social ≠ Wave Checkout disponible pour un marchand guinéen. Tant que ce n'est pas écrit dans la doc opérateur, c'est ❓.
- **Écrire `GNF` avec des décimales.** Le franc guinéen n'a pas de sous-unité : `amount: 50000`, pas `50000.00`.

## Fichiers

```
SKILL.md                        ce fichier
LISEZ-MOI.md                    notice d'installation et d'usage
references/
  architecture.md               interface commune + adaptateurs + registre
  machine-etats.md              7 statuts et transitions autorisées
  fiabilite-paiements.md        concurrence, unicité, ordre des opérations
  reconciliation.md             rattrapage / réconciliation / écarts / alertes
  tests.md                      3 niveaux de test
  adaptation-projet.md          analyser un projet existant
  detection-agregateur.md       analyser une doc inconnue, sans inventer
  verifications.md              journal daté de ce qui a été vérifié
  guinee/                       fiches opérateurs et agrégateurs guinéens
  exemples/                     fiches FedaPay, FeexPay, KkiaPay (Afrique de l'Ouest)
  journal-verifications-origine.md, lisez-moi-origine.md   sources d'origine
frameworks/                     express, nextjs, laravel, django, flutter
outils/                         implémentations de référence (voir outils/README.md)
```
