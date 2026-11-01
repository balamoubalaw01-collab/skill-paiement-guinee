# Pack paiement Guinee - contenu complet

Document unique regroupant l'integralite du skill `paiement-guinee`
pour import dans ChatGPT (Projet / GPT personnalise / fichier de connaissances).

Depot source : https://github.com/balamoubalaw01-collab/skill-paiement-guinee

## Sommaire

1. SKILL.md
2. LISEZ-MOI.md
3. README.md
4. references/guinee/orange-money-gn.md
5. references/guinee/mtn-momo-gn.md
6. references/guinee/wave-gn.md
7. references/guinee/ecobank-visa-gn.md
8. references/guinee/prink.md
9. references/guinee/agregateurs-gn.md
10. references/guinee/cas-usage-gestion-eleve.md
11. references/architecture.md
12. references/machine-etats.md
13. references/fiabilite-paiements.md
14. references/reconciliation.md
15. references/tests.md
16. references/adaptation-projet.md
17. references/detection-agregateur.md
18. references/verifications.md
19. references/exemples/fedapay.md
20. references/exemples/feexpay.md
21. references/exemples/kkiapay.md
22. frameworks/express.md
23. frameworks/nextjs.md
24. frameworks/laravel.md
25. frameworks/django.md
26. frameworks/flutter.md
27. outils/README.md

---


<!-- ===== FICHIER 1 : SKILL.md ===== -->

# [1] SKILL.md

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

---

<!-- ===== FICHIER 2 : LISEZ-MOI.md ===== -->

# [2] LISEZ-MOI.md

# Skill « Intégrer un paiement en Guinée »

Adaptation du skill *integrer-agregateur-paiement* d'Eric Dev au marché guinéen : **Orange Money Guinée, MTN MoMo Guinée, Wave Guinée, Ecobank / Visa**, et les agrégateurs qui couvrent le pays.

Ce skill apprend à une IA à brancher une appli existante sur un moyen de paiement guinéen, de A à Z. L'IA fait l'intégration ; toi, tu fournis tes clés et tu testes.

## Ce que l'IA fait avec ce skill

- Elle analyse ton projet (langage, framework, base, hébergement) et respecte ton code existant.
- Elle lit la doc de l'opérateur et te dit clairement ce qui est confirmé et ce qui ne l'est pas. **Elle n'invente pas** : une information absente est marquée `NON TROUVÉ`, jamais devinée.
- Elle crée une interface commune avec un adaptateur par rail, pour que tu puisses en ajouter ou en changer plus tard.
- Elle gère le pay-in et, si l'API le permet : remboursements, versements, carte.
- Elle sécurise les webhooks et met en place une vraie machine à états. Doublons, messages reçus dans le désordre et paiements tardifs ne cassent pas tes commandes.
- Elle ajoute le rattrapage des paiements bloqués, la réconciliation quotidienne et des alertes.
- Elle écrit et lance des tests : erreurs réseau, délais dépassés, fausses signatures, paiements simultanés.
- Elle termine par un **rapport honnête** : ce qui est fait, ce qui est testé, ce qui reste à tester avec tes vraies clés.

## État des rails en Guinée (1er novembre 2026)

| Rail | État | Ce que ça veut dire pour toi |
| --- | --- | --- |
| **Orange Money Guinée** | ✅ disponible, OTP par USSD, frais de scolarité explicitement couverts | **commence par là** — il faut un compte marchand KYA ouvert en agence Orange |
| **MTN MoMo** | 🟡 API confirmée, **disponibilité en Guinée non confirmée** | à faire confirmer par MTN avant de le promettre |
| **Wave** | 📄 Checkout API existe, **docs publiques introuvables**, présence Guinée non confirmée | à obtenir auprès du support Wave marchand |
| **Ecobank / Visa** | 📄 3-D Secure oui, **pas d'API marchand publique** | passer par un agrégateur, ou contrat acquéreur en agence |
| **Prink** | **NON TROUVÉ** | aucune source ne relie ce nom à un paiement guinéen — à clarifier avec un lien |
| **Agrégateurs** (Paycard, CinetPay, Paynote…) | 🟡 pistes classées, API non vérifiées | la voie la plus rapide pour encaisser plusieurs rails |

Détail complet : `references/guinee/`. Journal des sources ouvertes : `references/verifications.md`.

## Installer

- **Claude Code** : copie le dossier `skill-paiement-guinee` dans `~/.claude/skills/` (tous tes projets) ou dans `.claude/skills/` à la racine de ton projet.
- **Claude (web ou application)** : paramètres → Skills → importer le fichier `.zip`.
- **Autre agent** (Cursor, Cline, GPT, etc.) : le skill est du Markdown pur. Colle `SKILL.md` comme instruction système, et laisse les fichiers de `references/` accessibles à l'agent.

## Utiliser

Ouvre ton projet avec l'IA et écris par exemple :

> Utilise le skill paiement-guinee pour intégrer Orange Money Guinée dans mon appli de gestion des élèves. Le parent paie les frais de scolarité en GNF.

ou

> Utilise le skill paiement-guinee : je veux encaisser Orange Money, MTN et la carte Visa. Choisis l'agrégateur et dis-moi ce qui est confirmé.

## Avant de commencer

- **Ouvre ton compte marchand.** En Guinée, c'est le vrai prérequis : Orange Money exige un marchand enregistré et conforme KYA, ouvert dans une agence locale. Le code ne remplace pas le contrat.
- Récupère tes **clés de test** si l'opérateur en fournit. Orange n'a pas toujours de sandbox sur ce marché : prévois alors un premier paiement réel de **5 000 GNF**.
- **Ne colle jamais ta clé secrète dans la conversation** : mets-la toi-même dans le `.env` du serveur.
- Fais toujours un premier paiement réel de petit montant avant d'ouvrir à tes clients.

## Ce que ce skill ne fera pas

- Il n'inventera pas une API qui n'existe pas, ni ne déclarera disponible un rail non confirmé.
- Il ne mettra jamais une clé secrète dans une appli mobile ou un front.
- Il ne dira pas « testé » pour du code seulement écrit.

Fourni gratuitement, sans garantie. Les API des opérateurs changent : relis toujours l'intégration avant la mise en production.

---

Adaptation : structure, procédure en 10 étapes, 7 règles d'or et système de niveaux de confiance repris du skill d'origine **« Intégrer un agrégateur de paiement » — Eric Dev**. Les fiches guinéennes, le journal de vérifications et le cas d'usage scolaire ont été ajoutés.

---

<!-- ===== FICHIER 3 : README.md ===== -->

# [3] README.md

# skill-paiement-guinee

Skill pour agent IA : **intégrer un paiement mobile money ou carte en Guinée** dans une application existante — Orange Money Guinée, MTN MoMo Guinée, Wave Guinée, Ecobank / Visa, et les agrégateurs qui couvrent le pays.

Adapté au marché guinéen (devise **GNF**) depuis le skill *« Intégrer un agrégateur de paiement »* d'Eric Dev.

## Installation

```bash
# Claude Code — pour tous les projets
git clone https://github.com/balamoubalaw01-collab/skill-paiement-guinee.git \
  ~/.claude/skills/skill-paiement-guinee

# ou pour un seul projet
git clone https://github.com/balamoubalaw01-collab/skill-paiement-guinee.git \
  .claude/skills/skill-paiement-guinee
```

Autre agent (Cursor, Cline, GPT, …) : le contenu est du **Markdown pur**. Charge `SKILL.md` comme instruction système et laisse `references/` accessible à l'agent.

## Utilisation

> Utilise le skill `paiement-guinee` pour intégrer Orange Money Guinée dans mon application de gestion des élèves. Le parent paie les frais de scolarité en GNF.

> Utilise le skill `paiement-guinee` : je veux encaisser Orange Money, MTN et Visa. Choisis l'agrégateur et dis-moi ce qui est confirmé.

## État des rails (vérifié le 1er novembre 2026)

| Rail | État | Fiche |
| --- | --- | --- |
| Orange Money Guinée | ✅ disponible en Guinée Conakry, OTP par USSD, frais de scolarité cités par l'opérateur | [orange-money-gn.md](references/guinee/orange-money-gn.md) |
| MTN MoMo | 🟡 API confirmée, **couverture Guinée non confirmée** | [mtn-momo-gn.md](references/guinee/mtn-momo-gn.md) |
| Wave | 📄 Checkout API existe, docs publiques introuvables, **Guinée non confirmée** | [wave-gn.md](references/guinee/wave-gn.md) |
| Ecobank / Visa | 📄 3-D Secure oui, **pas d'API marchand publique** → passer par un PSP | [ecobank-visa-gn.md](references/guinee/ecobank-visa-gn.md) |
| Prink | **NON TROUVÉ** | [prink.md](references/guinee/prink.md) |
| Agrégateurs (Paycard, CinetPay, Paynote…) | 🟡 pistes classées, API non vérifiées | [agregateurs-gn.md](references/guinee/agregateurs-gn.md) |

Journal des sources réellement ouvertes : [references/verifications.md](references/verifications.md).

## Structure

```
SKILL.md            procédure en 10 étapes, 7 règles d'or, niveaux de confiance
LISEZ-MOI.md        notice d'installation et d'usage
references/         architecture, machine à états, fiabilité, réconciliation, tests
references/guinee/  fiches opérateurs, agrégateurs, cas d'usage scolarité
references/exemples/fiches FedaPay, FeexPay, KkiaPay (Afrique de l'Ouest)
frameworks/         express, nextjs, laravel, django, flutter
outils/             schéma SQL de référence (contraintes, transitions atomiques)
```

## Les 7 règles d'or

1. La clé secrète reste sur le serveur.
2. Le montant vient de la base, jamais du client.
3. Un paiement n'est réussi que si le serveur l'a confirmé auprès de l'opérateur.
4. Tout webhook est authentifié, puis revérifié par l'API.
5. La base de données arbitre : unicité, transitions atomiques, idempotence.
6. Montant, devise et référence sont contrôlés avant de marquer payé.
7. Honnêteté : jamais « testé » pour du code seulement écrit.

## Niveaux de confiance

✅ vérifié (exécuté / source SDK) · 🟡 indicatif (doc, non exécuté) · 📄 doc recopiée · ❓ non confirmé · **NON TROUVÉ** aucune source.

Une information `❓` ou `NON TROUVÉ` n'est jamais transformée en code de production. C'est la règle qui évite les intégrations fantômes.

## Crédit

Structure, procédure en 10 étapes, 7 règles d'or et système de niveaux de confiance repris du skill **« Intégrer un agrégateur de paiement » — Eric Dev**. Fiches guinéennes, journal de vérifications, schéma SQL et cas d'usage scolaire ajoutés.

Fourni gratuitement, sans garantie. Les API des opérateurs changent : relis toujours l'intégration avant la mise en production.

---

<!-- ===== FICHIER 4 : references/guinee/orange-money-gn.md ===== -->

# [4] references/guinee/orange-money-gn.md

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

---

<!-- ===== FICHIER 5 : references/guinee/mtn-momo-gn.md ===== -->

# [5] references/guinee/mtn-momo-gn.md

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

---

<!-- ===== FICHIER 6 : references/guinee/wave-gn.md ===== -->

# [6] references/guinee/wave-gn.md

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

---

<!-- ===== FICHIER 7 : references/guinee/ecobank-visa-gn.md ===== -->

# [7] references/guinee/ecobank-visa-gn.md

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

---

<!-- ===== FICHIER 8 : references/guinee/prink.md ===== -->

# [8] references/guinee/prink.md

# « Prink » — NON TROUVÉ

Légende : ✅ vérifié · 🟡 indicatif · **NON TROUVÉ** aucune source pertinente.
Recherche du **1er novembre 2026** — voir `../verifications.md`.

## Résultat de la recherche

**NON TROUVÉ.** Deux recherches (français et anglais) sur « Prink paiement Guinée », « Prink mobile money », « Prink Africa payment » n'ont renvoyé **aucun service de paiement guinéen, aucune API, aucun opérateur, aucun agrégateur** portant ce nom.

Ce qui existe sous des noms proches, et qui **n'est pas** un moyen de paiement :

| Nom proche | Ce que c'est | Pertinence paiement |
| --- | --- | --- |
| Prink (imprimerie photo en ligne, France) | impression de photos | ❌ aucune |
| Marques / comptes sociaux divers | sans rapport avec la Guinée | ❌ aucune |

Rien ne relie « Prink » à un rail de paiement, à un agrégateur, ni à la Guinée.

## Ce que la règle du pack impose

`../detection-agregateur.md`, règle absolue : « chaque information vient d'une source que tu as ouverte. Si tu ne la trouves pas, écris NON TROUVÉ […] Ne complète jamais un trou avec ce qui *devrait* marcher, ni avec ta mémoire. »

Donc : **on n'intègre pas Prink**, on ne crée pas d'adaptateur, on ne l'annonce pas dans l'interface, et on ne l'inclut pas dans les frais ou le comparatif.

## Si l'utilisateur y tient

Le nom vient peut-être de l'oral, d'une faute de frappe, ou d'un acteur local non référencé sur le web. Trois questions à poser, une seule fois :

1. **Un lien** — site, page Facebook, ou numéro de l'agent commercial.
2. **La nature** : opérateur mobile money, agrégateur, fintech de transfert, ou simple revendeur de crédit ?
3. **Le contrat** : as-tu déjà un compte marchand chez eux, avec un identifiant ?

Avec un lien, on remplit la grille de `../detection-agregateur.md` normalement. Sans lien, on reste à **NON TROUVÉ** et on travaille avec les rails confirmés (Orange Money Guinée en premier).

---

<!-- ===== FICHIER 9 : references/guinee/agregateurs-gn.md ===== -->

# [9] references/guinee/agregateurs-gn.md

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

---

<!-- ===== FICHIER 10 : references/guinee/cas-usage-gestion-eleve.md ===== -->

# [10] references/guinee/cas-usage-gestion-eleve.md

# Cas d'usage : frais de scolarité dans `gestion_Eleve`

Ce que le projet est aujourd'hui, ce qu'il faut ajouter pour encaisser, et le modèle de données qui va avec.

## 1. État réel du projet (constaté le 01/11/2026)

| Élément | Constat |
| --- | --- |
| `pom.xml` | Maven, `groupId com.mycompany`, artefact `gestion_Eleve`, packaging **jar** |
| Point d'entrée | `com.mycompany.gestion_eleve.Gestion_Eleve` (`exec.mainClass`) |
| Nature | **application console Java** (menus, `menu_simple.cpp` à côté, exécutables `.exe`) |
| `laravel_app/` | **dossier vide** |
| Serveur HTTP | **aucun** |
| Base de données | aucune couche de persistance visible à la racine |

⚠️ **Conséquence directe, à dire à l'utilisateur avant tout code** : une application console **ne peut pas recevoir de webhook**. Orange Money, MTN, Wave et les agrégateurs notifient par **appel HTTP entrant**. Il faut donc une brique serveur exposée en HTTPS avant de parler de paiement en production.

C'est le point n°1 du rapport d'intégration : *« le projet n'a pas de serveur HTTP ; le webhook ne peut pas être reçu en l'état »*.

## 2. Trois options, du moins cher au plus lourd

| Option | Ce qu'on ajoute | Pour qui | Effort |
| --- | --- | --- | --- |
| **A. Serveur HTTP minimal en Java** | `com.sun.net.httpserver.HttpServer` (JDK, zéro dépendance) : 3 routes (`POST /paiements`, `POST /webhooks/{rail}`, `GET /paiements/{ref}`) + JDBC | garder le projet Java existant | faible |
| **B. Spring Boot** | dépendance `spring-boot-starter-web` + `spring-boot-starter-jdbc`, même base | si le projet doit grossir (API pour une appli mobile, back-office) | moyen |
| **C. Application web séparée** | Laravel ou Express qui porte le paiement et lit la même base | si une interface web scolaire est prévue de toute façon (`laravel_app/` vide pour l'instant) | élevé |

Recommandation : **A** pour valider le parcours avec un vrai paiement, **B ou C** quand l'interface web arrive. Ne mélange pas : un seul endroit écrit le statut.

Si l'utilisateur choisit C, ouvre `frameworks/laravel.md` ou `frameworks/express.md`. Pour A et B, la logique est la même que dans `frameworks/express.md` (routes, corps brut, machine à états) — seul le langage change.

## 3. Modèle de données

```sql
-- L'élève et son inscription existent déjà ou sont à créer.
CREATE TABLE inscription (
  id            BIGSERIAL PRIMARY KEY,
  matricule     TEXT NOT NULL UNIQUE,          -- ex. 'INS-2026-0147'
  eleve_nom     TEXT NOT NULL,
  classe        TEXT NOT NULL,
  annee         TEXT NOT NULL,                 -- '2025-2026'
  tuteur_tel    TEXT                           -- 224XXXXXXXXX
);

-- Une échéance = une ligne à payer. C'est l'unité de paiement.
CREATE TABLE echeance (
  id             BIGSERIAL PRIMARY KEY,
  inscription_id BIGINT NOT NULL REFERENCES inscription(id),
  libelle        TEXT NOT NULL,                -- 'Scolarité T1', 'Cantine octobre'
  montant_gnf    BIGINT NOT NULL CHECK (montant_gnf > 0),
  echeance_le    DATE NOT NULL,
  statut         TEXT NOT NULL DEFAULT 'due'   -- due | partielle | payee | annulee
);
```

Le paiement, lui, suit le modèle du pack (`references/machine-etats.md`), avec deux colonnes propres au métier :

```sql
ALTER TABLE paiement
  ADD COLUMN echeance_id BIGINT REFERENCES echeance(id),
  ADD COLUMN recu_numero TEXT UNIQUE;          -- 'REC-2026-000412'
```

Contraintes qui font le travail (règle d'or 5) :

```sql
-- Un même appel de l'opérateur ne crée jamais deux paiements
ALTER TABLE paiement ADD CONSTRAINT paiement_provider_ref_unique
  UNIQUE (provider, provider_ref);

-- Une échéance ne peut pas être encaissée deux fois au-delà de son montant
CREATE UNIQUE INDEX paiement_echeance_reussi
  ON paiement (echeance_id)
  WHERE statut = 'succeeded' AND echeance_id IS NOT NULL;
```

La deuxième contrainte est la plus importante du projet : elle rend le **double encaissement impossible au niveau base**, même si un parent paie deux fois et que les deux webhooks arrivent en parallèle.

## 4. Référence de paiement

Format stable, lisible au téléphone, unique :

```
INS-2026-0147-T1
└── matricule ─┘ └ échéance
```

- **Jamais** le nom de l'élève seul : deux homonymes = rapprochement impossible.
- La référence est envoyée à l'opérateur (`reference` / `externalId` / `merchant_key` selon le rail) **et** affichée au parent, pour qu'il puisse la citer en cas de litige.

## 5. Montants en GNF

- Entier, sans décimale : `montant_gnf BIGINT`, jamais `DECIMAL` avec des centimes.
- Affichage : `1 500 000 GNF` (espace fine insécable comme séparateur de milliers) — pas `1.500.000` qui se lit mal, pas `1,5M`.
- Le montant envoyé à l'opérateur est **relu en base** (`SELECT montant_gnf FROM echeance WHERE id = ?`), jamais pris dans la requête du client.

```java
// Java : formatage lisible
String affichage = String.format("%,d GNF", montantGnf).replace(',', '\u202F');
// 1500000 -> "1 500 000 GNF"
```

## 6. Parcours parent (celui qu'on code)

1. Le parent ouvre l'appli / la page, choisit l'échéance → le serveur crée (ou réutilise) un `paiement` `pending` avec la référence `INS-…-T1`.
2. Le serveur demande l'URL de paiement au rail (Orange Money par défaut) et redirige.
3. Le parent valide sur son téléphone (OTP Orange par USSD / PIN MoMo).
4. Notification → statut vérifié → `succeeded` → **génération du reçu** et passage de l'échéance à `payee`, dans la même transaction ou via l'outbox.
5. Le reçu (`REC-2026-000412`) est consultable et imprimable. C'est ce que le parent montre à l'école : il doit porter la référence, le montant, la date, le rail et le statut.

## 7. Ce que la direction attend (à ne pas oublier)

- **Journal du jour** : total encaissé par rail, nombre de paiements, échecs.
- **Liste des impayés** : échéances `due` dont la date est dépassée, triées par classe.
- **Rapprochement** : total base vs total opérateur, écarts signalés (`references/reconciliation.md`).
- **Relance** : un paiement `pending` de plus de 15 min n'est pas un échec — mais un parent qui a « payé » sans reçu doit être rappelé avec la référence exacte.

## 8. Pièges propres à ce cas d'usage

- Un parent paie **pour deux enfants** en une fois : soit deux paiements séparés (recommandé), soit un paiement multi-échéances — mais alors la contrainte d'unicité ci-dessus doit être repensée. Choisis le simple.
- Un parent paie **une partie** : `montant_gnf` partiel → échéance `partielle`, jamais `payee`. Le statut `succeeded` du paiement reste vrai, c'est l'échéance qui porte la nuance.
- Un parent paie **en retard** : ne bloque pas, encaisse, et laisse le retard visible dans la liste des impayés.
- Un parent **conteste** : le reçu + la référence + la réponse de l'opérateur archivée (`payment_events`) sont la seule preuve recevable. D'où l'interdiction de modifier un log de paiement.

---

<!-- ===== FICHIER 11 : references/architecture.md ===== -->

# [11] references/architecture.md

# Architecture commune : une interface, un adaptateur par agrégateur

But : changer d'agrégateur (ou en ajouter un deuxième) sans réécrire l'application. Le reste du code ne parle **qu'à l'interface**, jamais directement à FedaPay, KkiaPay ou FeexPay.

Avant de créer quoi que ce soit, lis `adaptation-projet.md` : si le projet a déjà un module de paiement, adapte-le au lieu d'en écrire un second.

## L'interface (à traduire dans le langage du projet)

```ts
type Operation = 'payin' | 'refund' | 'payout' | 'card' | 'recurring';
type Statut = 'pending' | 'processing' | 'succeeded' | 'failed' | 'cancelled' | 'expired' | 'refunded';

interface Capacites {
  operations: Operation[];            // seulement ce que l'agrégateur prend en charge ET qui est confirmé
  pays: string[];                      // ex. ['BJ', 'TG']
  reseaux: Record<string, string[]>;   // ex. { BJ: ['mtn', 'moov', 'celtiis'] }
  devises: string[];                   // ex. ['XOF']
  parcours: ('page' | 'widget' | 'direct')[];
  remboursementPartiel: boolean | 'inconnu';
}

interface ResultatStatut {
  statut: Statut | 'inconnu';          // déjà traduit par l'adaptateur
  statutFournisseur: string;           // valeur brute, pour le journal
  montant: number | null;              // entier, unité de la devise (le FCFA n'a pas de centimes)
  devise: string | null;
  frais: number | null;
  referenceFournisseur: string;
}

interface AdaptateurPaiement {
  readonly nom: string;                // 'fedapay', 'kkiapay', 'feexpay'…
  capacites(): Capacites;
  createPayment(p: { paiementId: string; montant: number; devise: string; client: {...};
                     reseau?: string; telephone?: string; urlRetour?: string; cleIdempotence: string })
    : Promise<{ referenceFournisseur: string | null; urlPaiement?: string; statut: Statut }>;
  getPaymentStatus(referenceFournisseur: string): Promise<ResultatStatut>;
  verifyWebhook(corpsBrut: Buffer | string, entetes: Record<string, string>)
    : Promise<{ valide: boolean; referenceFournisseur?: string; eventKey?: string }>;
  refundPayment?(referenceFournisseur: string, montant?: number): Promise<{ referenceRemboursement: string; statut: string }>;
  createPayout?(p: {...}): Promise<{...}>;
  getPayoutStatus?(reference: string): Promise<{...}>;
}
```

Règles :
- Une méthode facultative **n'existe pas** dans l'adaptateur si l'opération n'est pas prise en charge **ou** pas confirmée. Le code appelant vérifie `capacites()` et affiche « non disponible avec cet agrégateur », il n'improvise pas.
- `verifyWebhook` ne fait **que** l'authentification de la requête. La décision vient toujours de `getPaymentStatus`.
- La traduction des statuts du fournisseur vers les 7 statuts se fait **uniquement** dans l'adaptateur. Valeur inconnue → `'inconnu'`.
- Erreurs normalisées : `ErreurReseau`, `DelaiDepasse`, `RefusFournisseur` (avec le message réel), `ReponseInattendue`, `OperationNonPriseEnCharge`. `DelaiDepasse` et `ErreurReseau` ne signifient **jamais** « échec du paiement ».
- Chaque appel HTTP a un délai maximal explicite et journalise : méthode, URL sans secret, code HTTP, durée, référence. Jamais de clé, de PIN ni de numéro complet dans les logs.

## Organisation des fichiers (exemple, à adapter aux conventions du projet)

```
paiements/
  interface            (types, erreurs)
  registre             (choisit l'adaptateur selon la config : PAYMENT_PROVIDER=fedapay)
  adaptateurs/fedapay  adaptateurs/kkiapay  adaptateurs/feexpay
  service              (createPayment côté métier, appliquerTransition, rattrapage, réconciliation)
  webhooks             (une route par agrégateur, toutes appellent le service)
```

Plusieurs agrégateurs en même temps (par pays ou par réseau) : le registre choisit l'adaptateur par règle explicite (pays, réseau). Jamais de bascule automatique vers un autre agrégateur après une erreur : on risque un double débit.

## Opérations possibles

| Opération | À faire seulement si… | Points d'attention |
| --- | --- | --- |
| Pay-in mobile money | toujours (c'est le cœur) | parcours page / widget / direct |
| Paiement par carte | l'agrégateur le propose | souvent une page hébergée (3-D Secure) ; frais plus élevés ; jamais de numéro de carte sur ton serveur |
| Remboursement | API confirmée dans la doc | table `refunds` avec sa propre machine à états ; total remboursé ≤ montant payé |
| Payout (versement sortant) | API confirmée et compte autorisé | règles renforcées (`fiabilite-paiements.md` §4) ; solde ; validation humaine |
| Paiement récurrent | l'agrégateur a une vraie API d'abonnement ou de carte enregistrée | en mobile money, chaque débit demande en général un nouveau PIN : c'est une **nouvelle demande de paiement planifiée** que le client confirme, pas un prélèvement automatique |

Ce que chaque agrégateur propose (et le niveau de confiance) : voir sa fiche. Si une opération demandée n'est pas prise en charge, dis-le clairement à l'utilisateur et propose une alternative (autre agrégateur, opération manuelle depuis le tableau de bord).

---

<!-- ===== FICHIER 12 : references/machine-etats.md ===== -->

# [12] references/machine-etats.md

# Machine à états des paiements

Une seule source de vérité pour les statuts. Toute écriture de statut passe par la fonction de transition (`appliquerTransition`) ; aucun autre code n'écrit la colonne `status`.

## Les 7 statuts

| Statut | Sens | Définitif ? |
| --- | --- | --- |
| `pending` | créé chez nous, pas encore accepté par l'agrégateur | non |
| `processing` | accepté par l'agrégateur, en attente du client (PIN, page de paiement) ou du réseau | non |
| `succeeded` | l'agrégateur confirme que l'argent est reçu | oui, sauf remboursement |
| `failed` | refusé ou échoué | **non** : un paiement tardif peut encore être confirmé |
| `cancelled` | annulé (par le client, par nous, ou par l'agrégateur) | **non** : même raison |
| `expired` | délai dépassé sans réponse | **non** : même raison |
| `refunded` | remboursé (totalement) et confirmé par l'agrégateur | oui |

Correspondance des statuts des agrégateurs : voir chaque fiche (`references/<agregateur>.md`). Un statut inconnu de l'agrégateur = **aucune transition** + alerte (jamais « succès par défaut », jamais « échec par défaut »).

Les anomalies métier ne sont **pas** des statuts : elles vont dans une colonne `anomalie` (`montant_incorrect`, `devise_incorrecte`, `double_paiement`, `statut_inconnu`…). Le statut décrit ce que dit l'agrégateur ; la commande décrit ce que l'entreprise a livré.

## Transitions autorisées

| De \ Vers | processing | succeeded | failed | cancelled | expired | refunded |
| --- | --- | --- | --- | --- | --- | --- |
| `pending` | ✔ | ✔ | ✔ | ✔ | ✔ | |
| `processing` | | ✔ | ✔ | ✔ | ✔ | |
| `failed` | ✔ (nouvel essai) | ✔ (tardif) | | | | |
| `cancelled` | | ✔ (tardif + anomalie) | | | | |
| `expired` | | ✔ (tardif) | | | | |
| `succeeded` | | | | | | ✔ (remboursement confirmé) |
| `refunded` | | | | | | |

Tout le reste est **refusé et journalisé** (par exemple `succeeded → failed` à cause d'un webhook en retard).

`pending → succeeded` est autorisé pour le cas où la confirmation arrive avant qu'on ait enregistré `processing`.

## Règles de traitement

1. **On ne croit pas l'ordre des événements.** À chaque webhook ou passage du rattrapage, on demande le statut **actuel** à l'agrégateur (`getPaymentStatus`) et on applique la transition vers ce statut si elle est autorisée. Un vieil événement « échec » reçu après un succès produit une transition refusée : rien ne change.
2. **Doublons** : chaque événement est enregistré dans `webhook_events` avec `UNIQUE (provider, event_key)` avant tout traitement. Déjà vu → réponse 200, fin.
3. **Écriture atomique** : la transition est un `UPDATE ... WHERE id = :id AND status IN (<statuts de départ autorisés>)`. 0 ligne modifiée = quelqu'un est passé avant, ou transition interdite : on relit et on journalise (voir `fiabilite-paiements.md`).
4. **Paiement tardif** (`failed` / `cancelled` / `expired` → `succeeded`) : l'argent est reçu. Si la commande est encore payable → on la valide. Si elle a été annulée, revendue, ou payée par un autre paiement → `anomalie = 'double_paiement'` ou `'paiement_tardif'`, pas de livraison automatique, alerte pour remboursement.
5. **Remboursement** : `succeeded → refunded` seulement quand l'agrégateur **confirme** le remboursement. Pendant la demande, garde `succeeded` et suis la demande dans une table `refunds` (sa propre machine : `requested → processing → succeeded | failed`). Remboursement partiel : `refunds` porte le montant ; le paiement reste `succeeded` tant que le total remboursé est inférieur au montant.
6. **Journal** : chaque transition (acceptée ou refusée) écrit une ligne dans `payment_events` : `payment_id`, `from`, `to`, `source` (`webhook`, `rattrapage`, `api`, `admin`), `provider_status`, date, empreinte de la réponse brute. Ce journal ne se modifie jamais (ajout seulement).

## La commande suit le paiement, pas l'inverse

- La commande passe à « payée » **dans la même transaction de base** que la transition vers `succeeded`, avec sa propre garde (`WHERE status <> 'paid'`).
- Les effets (livraison, e-mail, crédit) partent **après le commit**, une seule fois (outbox ou file d'attente).
- Un remboursement confirmé met la commande à jour selon la règle métier du projet (annulée, à reprendre…) : demande-la à l'utilisateur si elle n'existe pas.

## Implémentation de référence

`outils/test-concurrence-postgres.js` contient la table des transitions, la fonction de transition atomique et les tests (événements en double, désordre, paiement tardif, double paiement, remboursement), exécutés sur un vrai PostgreSQL.

---

<!-- ===== FICHIER 13 : references/fiabilite-paiements.md ===== -->

# [13] references/fiabilite-paiements.md

# Fiabilité des paiements : concurrence, unicité, ordre des opérations

Vérifier le paiement auprès de l'agrégateur ne suffit pas. Deux webhooks peuvent arriver en même temps, le webhook et la tâche de rattrapage peuvent traiter le même paiement à la même seconde, un client peut payer deux fois. Cette fiche rend le traitement **sûr en parallèle**. Les statuts et transitions sont définis dans `machine-etats.md`.

Principe : **la base de données arbitre**, pas le code. Jamais « je lis le statut, puis j'écris » sans protection.

## 1. Contraintes en base (obligatoires)

| Contrainte | Pourquoi |
| --- | --- |
| `UNIQUE (provider, provider_ref)` sur `payments` | une transaction de l'agrégateur ne paie qu'un seul paiement interne |
| `UNIQUE (idempotency_key)` sur `payments` | un double clic ou une requête renvoyée ne crée pas deux paiements |
| Un seul paiement `succeeded` sans anomalie par commande | une commande n'est jamais payée deux fois |
| Un seul paiement `pending` / `processing` par commande | pas deux demandes de PIN en même temps |
| `UNIQUE (provider, event_key)` sur `webhook_events` | un même événement n'est traité qu'une fois |
| `CHECK (status IN (...))` | aucun statut inventé |

Index partiels :
- PostgreSQL / SQLite : `CREATE UNIQUE INDEX ... ON payments (order_id) WHERE status = 'succeeded' AND anomalie IS NULL;` et `... WHERE status IN ('pending','processing');`
- MySQL / MariaDB (pas d'index partiel) : colonne générée ou colonne `success_order_id` nullable et `UNIQUE`, remplie seulement quand la condition est vraie (plusieurs `NULL` sont permis).

`event_key` = identifiant d'événement de l'agrégateur s'il existe ; sinon `transactionId + type d'événement`, ou l'empreinte SHA-256 du corps brut.

## 2. Ordre impératif d'un traitement (webhook ou rattrapage)

1. **Hors transaction de base** :
   1. vérifier la signature / le secret du webhook (sinon `401`) ;
   2. enregistrer l'événement dans `webhook_events` (doublon → `200` et fin) ;
   3. appeler `getPaymentStatus` chez l'agrégateur.
   On n'appelle **jamais** une API externe en tenant un verrou ou une transaction ouverte : un appel lent bloquerait tout.
2. **Dans une transaction courte** : `appliquerTransition` (voir `machine-etats.md`) :
   ```sql
   UPDATE payments SET status = :vers, ...
    WHERE id = :id AND status = ANY(:statuts_de_depart_autorises);
   ```
   - 0 ligne modifiée → déjà traité ou transition interdite : journaliser, ne rien faire d'autre.
   - erreur d'unicité (index « un seul réussi par commande ») → un autre paiement a déjà payé la commande : annuler, puis enregistrer ce paiement `succeeded` avec `anomalie = 'double_paiement'` dans une nouvelle transaction. Codes : PostgreSQL `23505`, MySQL `1062`, Prisma `P2002`, Django `IntegrityError`, Laravel `UniqueConstraintViolationException` (10.21+) ou `QueryException`.
   - 1 ligne → mettre à jour la commande avec sa propre garde (`WHERE status = 'awaiting_payment'`), écrire `payment_events` et l'outbox.
3. **Après le commit seulement** : effets de bord (livraison, e-mail, crédit), une seule fois, via l'outbox ou une file d'attente (`DB::afterCommit` / `->afterCommit()` en Laravel, `transaction.on_commit` en Django, outbox lue par un worker en Node).

Avec un ORM, utilise la **mise à jour en masse filtrée** qui renvoie le nombre de lignes (`updateMany`, `->where()->update()`, `.filter().update()`), jamais « charger l'objet, modifier, sauvegarder ».
Alternative : `SELECT ... FOR UPDATE` sur la ligne, décision, écriture, dans la même transaction.

## 3. Créer un paiement sans doublon

1. L'appli génère une `idempotency_key` (UUID) **par tentative** et l'envoie avec la demande.
2. Transaction : verrouiller la commande (`SELECT ... FOR UPDATE`), refuser si elle est payée, réutiliser le paiement en cours s'il existe, sinon insérer un paiement `pending`. Clé déjà connue → renvoyer le paiement existant.
3. **Après le commit**, appeler `createPayment` en donnant notre identifiant interne comme référence marchand quand l'agrégateur le permet (pour retrouver le paiement si on plante entre l'appel et l'enregistrement).
4. Enregistrer `provider_ref` et passer à `processing`. Refus clair → `failed`. Délai dépassé / erreur réseau → **ne rien conclure** : le paiement reste `pending` et le rattrapage s'en occupe.

## 4. Payouts (versements sortants) : règles en plus

Un payout envoyé deux fois, c'est de l'argent perdu. En plus de tout ce qui précède :
- clé d'idempotence côté agrégateur si l'API en propose une ; sinon, enregistrer en base (et committer) le jeton / la référence de la demande **avant** de l'envoyer ;
- **jamais de nouvel essai automatique** d'un payout dont le résultat est inconnu (délai dépassé, erreur 5xx) : on vérifie d'abord son statut, puis un humain décide ;
- jamais de bascule automatique vers un autre agrégateur après une erreur sur un payout ;
- plafonds par opération et par jour, validation humaine au-delà ;
- vérifier le solde disponible avant d'envoyer.

## 5. Implémentation de référence testée

`outils/test-concurrence-postgres.js` implémente `appliquerTransition` et la teste sur un vrai PostgreSQL 16 : doublons en parallèle, désordre, webhook + rattrapage simultanés, paiement tardif, double paiement, montant faux, statut inconnu, remboursement concurrent, double clic. ✅ 10/10 tests passent (exécuté 4 fois le 31/10/2026). Traduis cette logique dans le langage du projet ; ne la réinvente pas.

---

<!-- ===== FICHIER 14 : references/reconciliation.md ===== -->

# [14] references/reconciliation.md

# Réconciliation et suivi financier

Un paiement « réussi » techniquement n'explique pas toujours pourquoi l'argent reçu ne correspond pas aux chiffres : frais différents selon le réseau, paiements tardifs, doubles paiements, remboursements, webhooks perdus, versements de l'agrégateur vers le compte du marchand. La réconciliation compare régulièrement **ta base** et **l'agrégateur**, et signale chaque écart.

## Deux mécanismes différents

| | Rattrapage (toutes les 2 à 5 min) | Réconciliation (1 fois par jour, ou à la demande) |
| --- | --- | --- |
| But | finir les paiements en cours | trouver les écarts |
| Périmètre | paiements `pending` / `processing` récents | toutes les transactions d'une période (la veille, J-2 par sécurité) |
| Action | applique les transitions | **n'écrit pas** de statut tout seul : produit un rapport et des alertes ; les corrections passent par `appliquerTransition` ou par un humain |

## Sources côté agrégateur

- API de liste / recherche des transactions si elle existe (voir la fiche de l'agrégateur).
- Sinon : export CSV du tableau de bord, importé par l'utilisateur (prévois une commande ou un écran d'import).
- Si rien n'est disponible : réconciliation par `getPaymentStatus` sur chaque paiement local de la période (ne détecte pas les paiements inconnus chez nous).

## Écarts à détecter

| Écart | Exemple | Gravité |
| --- | --- | --- |
| Chez l'agrégateur, absent chez nous | webhook perdu + crash | haute : argent reçu sans commande |
| Chez nous `succeeded`, absent ou non réussi chez l'agrégateur | bug, fraude, mauvais environnement | **critique** : livré sans être payé |
| Statuts différents | `processing` chez nous, `succeeded` chez lui | moyenne (le rattrapage aurait dû le voir) |
| Montant ou devise différents | 1 000 attendu, 200 reçu | haute |
| Frais différents de ceux prévus | frais plus élevés sur un réseau | moyenne : marge fausse |
| Double paiement d'une commande | deux `succeeded` | haute : à rembourser |
| Remboursement sans trace chez nous (ou l'inverse) | remboursé depuis le tableau de bord | moyenne |
| Total net du jour ≠ versement / solde | net attendu = Σ montants − Σ frais − Σ remboursements | haute |

## Stockage

- `reconciliation_runs` : période, source (API, export), date, nombre de lignes de chaque côté, totaux brut / frais / net, nombre d'écarts, statut.
- `reconciliation_items` : une ligne par écart : type, références locale et fournisseur, valeurs des deux côtés, gravité, statut de traitement (`ouvert`, `corrige`, `accepte`), commentaire, qui a traité.
- Le journal `payment_events` (ajout seulement) permet de rejouer l'histoire d'un paiement.

## Alertes

- Critique et haute : alerte immédiate (e-mail, Slack, WhatsApp, Telegram… selon ce que le projet utilise déjà).
- Résumé quotidien : totaux, nombre d'écarts ouverts.
- Alerte aussi si la réconciliation **ne tourne pas** (pas de run depuis 36 h) ou si le rattrapage voit des paiements bloqués trop longtemps.

## Journalisation sécurisée

- Jamais : clés, secrets, PIN, OTP, numéro de carte, en-têtes d'authentification.
- Masquer : numéros de téléphone (`2290166****00`), e-mails partiels.
- Garder les réponses brutes de l'agrégateur dans une colonne dédiée, avec accès restreint, et une durée de conservation définie.
- Les logs de paiement ne se modifient pas (ajout seulement) ; les corrections sont des nouvelles lignes.

## À livrer

- la tâche planifiée de réconciliation (voir le guide du framework pour la planification) ;
- une commande pour la lancer à la main sur une période ;
- un rapport lisible (page d'admin existante, export CSV, ou e-mail) ;
- si le projet n'a pas d'admin : ne construis pas une admin complète, un rapport par e-mail ou un CSV suffit.

---

<!-- ===== FICHIER 15 : references/tests.md ===== -->

# [15] references/tests.md

# Tests automatiques

Trois niveaux. Les deux premiers tournent sans clés ni réseau : ils doivent passer avant toute mise en production.

## Niveau 1 — Adaptateur (API simulée)

Simule l'agrégateur avec l'outil standard du langage :
- Node : `nock` ou `msw` · PHP / Laravel : `Http::fake()` (client HTTP Laravel) ou Guzzle `MockHandler` · Python : `responses` (requests) ou `respx` (httpx) · Dart / Flutter : `MockClient` de `package:http/testing.dart`.

Derrière un proxy d'entreprise, exclure les hôtes simulés du proxy (`NO_PROXY`), sinon la simulation est contournée.

Cas à couvrir pour `createPayment` et `getPaymentStatus` :
- [ ] réponse normale (succès, échec, en attente) → bon statut normalisé ;
- [ ] **erreur réseau** (connexion refusée, DNS) → `ErreurReseau`, aucun statut final ;
- [ ] **délai dépassé** → `DelaiDepasse`, le paiement reste `pending` / `processing` ;
- [ ] erreur 401 / 403 → message clair (clé ou IP non autorisée), pas de nouvel essai en boucle ;
- [ ] erreur 4xx avec message de l'agrégateur → `RefusFournisseur` avec le **message réel** ;
- [ ] erreur 5xx → nouvel essai limité (lecture seulement : jamais pour une création de payout) ;
- [ ] **réponse inattendue** : JSON invalide, champ manquant, statut inconnu, montant en texte → `ReponseInattendue` ou `inconnu`, **jamais** `succeeded` ;
- [ ] montant / devise de la réponse différents de la demande → anomalie.

Cas pour `verifyWebhook` :
- [ ] signature valide → accepté ;
- [ ] mauvaise signature, mauvais secret, en-tête absent, en-tête mal formé → refusé ;
- [ ] corps modifié d'un seul caractère → refusé ;
- [ ] horodatage trop ancien (si l'agrégateur en met un) → refusé ;
- [ ] corps déjà parsé passé par erreur → doit échouer (preuve que le corps **brut** est utilisé).
Pour produire des signatures valides : outil de test du SDK (FedaPay : `Webhook.generateTestHeaderString`) ou ton propre calcul à partir de la doc.

## Niveau 2 — Service et base de données (vraie base, sans réseau)

Sur le **même moteur** que la production (PostgreSQL, MySQL…) : SQLite en mémoire ne reproduit pas les verrous.
- [ ] machine à états : chaque transition autorisée passe, chaque transition interdite est refusée et journalisée ;
- [ ] le même webhook 10 fois **en parallèle** → une seule livraison ;
- [ ] webhook + rattrapage simultanés → une seule livraison ;
- [ ] événements dans le désordre (échec après succès) → reste `succeeded` ;
- [ ] paiement tardif après `expired` / `failed` → `succeeded` et règle métier appliquée ;
- [ ] deux paiements réussis pour une commande → une livraison + `anomalie = double_paiement` ;
- [ ] remboursement : seulement depuis `succeeded`, total ≤ montant, deux confirmations parallèles → une transition ;
- [ ] payout : délai dépassé → **aucun** nouvel envoi automatique ;
- [ ] double clic (même clé d'idempotence) → un seul paiement ;
- [ ] crash simulé entre l'appel à l'agrégateur et l'enregistrement → le rattrapage retrouve le paiement.
Référence exécutable : `outils/test-concurrence-postgres.js`.

## Niveau 3 — Sandbox de l'agrégateur (avec les clés de test de l'utilisateur)

À faire par l'utilisateur (ou par toi s'il a mis ses clés de test dans `.env`), avec un tunnel HTTPS pour le webhook :
- [ ] paiement réussi de bout en bout, webhook reçu, commande payée une fois ;
- [ ] paiement refusé / annulé ;
- [ ] client qui ne valide pas → expiration ;
- [ ] faux webhook envoyé à la main → refusé ;
- [ ] remboursement (si pris en charge) ;
- [ ] chaque réseau proposé dans l'appli (MTN, Moov, Celtiis…).

Ce que le sandbox ne sait pas reproduire (désordre, doublons, pannes, réponses étranges) est couvert par les niveaux 1 et 2. **Un test sandbox n'est pas un test en réel** : le rapport final le dit.

---

<!-- ===== FICHIER 16 : references/adaptation-projet.md ===== -->

# [16] references/adaptation-projet.md

# S'adapter au projet existant

Le but est d'ajouter le paiement **dans** le projet, pas de reconstruire le projet autour du paiement. Moins de code, mais du code au bon endroit.

## 1. Détecter avant d'écrire

| À détecter | Où regarder |
| --- | --- |
| Langage et version | `package.json`, `composer.json`, `pyproject.toml` / `requirements.txt`, `pubspec.yaml`, `go.mod` |
| Framework | dépendances + structure (`app/` Next.js, `routes/` Laravel, `manage.py` Django, `lib/` Flutter…) |
| Base de données et ORM | Prisma, Drizzle, TypeORM, Sequelize, Eloquent, Django ORM, SQLAlchemy ; moteur réel (PostgreSQL, MySQL, SQLite) dans la config |
| Migrations | outil existant (Prisma Migrate, migrations Laravel / Django, Knex…) |
| Hébergement | `vercel.json`, `netlify.toml`, `Dockerfile`, `ecosystem.config.js` (PM2), `Procfile`, configuration Nginx, CI |
| Tâches de fond | file existante (BullMQ, Laravel Queue, Celery, RQ), cron, planificateur |
| Authentification | middleware / guard / décorateur existant pour protéger les routes |
| Conventions | nommage, dossiers, style des contrôleurs et services, gestion des erreurs, client HTTP utilisé, tests existants |
| Paiement existant | ancien code d'agrégateur, tables `payments` / `transactions`, webhooks déjà déclarés |

Résume ce que tu as trouvé à l'utilisateur en quelques lignes avant de coder.

## 2. Règles d'adaptation

- **Réutilise** : le client HTTP, l'ORM, le système de migrations, la file d'attente, le logger, le système d'alerte, les composants d'interface déjà présents.
- **Respecte** la structure : si les services sont dans `src/services/`, l'adaptateur y va aussi ; si le projet n'utilise pas de classes, n'en introduis pas.
- **Étends** l'existant : une table `payments` existe déjà → migration qui ajoute les colonnes manquantes, pas une deuxième table.
- **N'ajoute pas** de dépendance si le projet a déjà l'équivalent. Une nouvelle dépendance doit être justifiée (SDK officiel de l'agrégateur, par exemple).
- **Pas de refonte** non demandée (changement d'ORM, de framework, de structure de dossiers, de style). Si l'existant est dangereux (clé secrète dans l'appli, validation du paiement côté client), corrige **ce point** et explique pourquoi.
- **Hébergement** :
  - serverless (Vercel, Netlify, Lambda) : pas de tâche en arrière-plan qui tourne en continu → cron de la plateforme ou cron externe appelant une route protégée ; attention aux appels longs (certains agrégateurs attendent la validation du client) ;
  - serveur classique (VPS, PM2, Docker) : cron système, worker de file, ou planificateur du framework ;
  - plusieurs instances : le rattrapage et la réconciliation ne tournent qu'une fois à la fois (verrou).
- **Changement minimal mesurable** : à la fin, liste les fichiers créés et modifiés. Si la liste est longue, vérifie que chaque fichier est nécessaire.

## 3. Projet en production

Si l'appli est déjà utilisée par de vrais clients :
- migrations **additives** seulement (ajout de colonnes / tables, pas de suppression ni de renommage) ;
- l'ancien flux de paiement continue de marcher pendant la transition, ou la bascule est contrôlée par une variable de configuration ;
- travaille sur une branche, et propose une pull request plutôt qu'un changement direct sur la branche principale si le projet utilise Git ;
- ne déploie rien toi-même sans accord explicite.

## 4. Guides par framework

- Express / Node.js → `frameworks/express.md`
- Next.js → `frameworks/nextjs.md`
- Laravel → `frameworks/laravel.md`
- Django → `frameworks/django.md`
- Flutter (appli mobile) → `frameworks/flutter.md`

Autre framework (NestJS, FastAPI, Rails, Spring, Go…) : applique les mêmes principes en cherchant, dans la doc du framework, comment : lire le corps brut d'une requête, exclure une route de la protection CSRF, faire une transaction avec mise à jour filtrée, exécuter du code après le commit, planifier une tâche.

---

<!-- ===== FICHIER 17 : references/detection-agregateur.md ===== -->

# [17] references/detection-agregateur.md

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

---

<!-- ===== FICHIER 18 : references/verifications.md ===== -->

# [18] references/verifications.md

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

---

<!-- ===== FICHIER 19 : references/exemples/fedapay.md ===== -->

# [19] references/exemples/fedapay.md

# FedaPay — fiche d'intégration (pay-in)

Doc officielle : https://docs.fedapay.com (index pour IA : https://docs.fedapay.com/llms.txt)
Légende : ✅ vérifié · 🟡 indicatif · ❓ non confirmé (voir SKILL.md, « Niveaux de confiance »).
Versions testées le 31/10/2026 : SDK Node `fedapay` **1.2.5**, SDK PHP `fedapay/fedapay-php` **0.4.9**. Si le projet utilise une autre version, relance `outils/test-sdk-fedapay-*.js`.

## Environnements et authentification

- ✅ Sandbox `https://sandbox-api.fedapay.com/v1` · Live `https://api.fedapay.com/v1` (constantes du SDK Node).
- ✅ En-tête `Authorization: Bearer <CLÉ_SECRÈTE>` (requête observée depuis le SDK).
- 🟡 Clés publique et secrète, en test et en live, dans le tableau de bord.

## Parcours 1 — Page de paiement FedaPay

✅ Requêtes vérifiées avec le SDK Node (réponses simulées) :
```js
const { FedaPay, Transaction } = require('fedapay');
FedaPay.setApiKey(process.env.FEDAPAY_SECRET_KEY);
FedaPay.setEnvironment(process.env.FEDAPAY_ENV);            // 'sandbox' ou 'live'

const transaction = await Transaction.create({               // POST /v1/transactions
  description: `Commande ${order.id}`,
  amount: order.amount,                                      // entier, lu en base
  currency: { iso: 'XOF' },
  callback_url: `${process.env.APP_URL}/paiement/retour`,
  customer: { firstname, lastname, email, phone_number: { number: '0166000000', country: 'bj' } },
});
const token = await transaction.generateToken();             // POST /v1/transactions/{id}/token -> { token, url }
// rediriger le client vers token.url ; garder transaction.id comme provider_ref
const t = await Transaction.retrieve(transaction.id);        // fetchStatus
```
- 🟡 Le champ `customer` et son format viennent de la doc ; vérifie les champs obligatoires dans la référence API « Create a transaction ».
- 🟡 Au retour sur `callback_url`, **ne crois pas** le statut dans l'URL : revérifie avec `Transaction.retrieve`.

## Parcours 2 — Paiement direct (demande de PIN)

✅ Signature réelle du SDK : `sendNowWithToken(mode, token, params)` — le numéro va **dans `params`** :
```js
const token = await transaction.generateToken();
await transaction.sendNowWithToken(mode, token.token, { phone_number: { number: '0166000001', country: 'bj' } });
// envoie POST /v1/{mode} avec { phone_number, token }
// raccourci : await transaction.sendNow(mode, { phone_number: {...} })
```
❓ **Le nom exact du `mode` par réseau.** La doc a utilisé selon les versions `mtn`, `mtn_open`, `mtn_benin` (MTN Bénin), `moov` / `moov_benin` (Moov Bénin), `sbin` (Celtiis Bénin), `moov_tg`, `mtn_ci`… Ne choisis pas au hasard : lis la page « méthodes de paiement » à jour, ou teste chaque mode en sandbox. Sans confirmation, propose le parcours 1 (page FedaPay), qui n'a pas besoin du mode.

## Statuts

🟡 D'après la doc : `pending` (expire après 24 h), `approved`, `declined`, `canceled`, `expired`, `refunded`, `transferred`.
Correspondance vers les 7 statuts : `pending` (côté FedaPay) → `processing` · `approved` / `transferred` → `succeeded` · `declined` / `canceled` → `failed` (ni l'un ni l'autre ne sont définitifs : le client peut réessayer sur la même transaction ; `cancelled` reste réservé aux annulations faites par ton appli) · `expired` → `expired` · `refunded` → `refunded` · autre → `inconnu`.

## Webhook

- 🟡 Configuré dans le tableau de bord ; un secret par webhook (`wh_sandbox...` en test), **différent en live** ; FedaPay attend une réponse 2xx et réessaie sinon.
- ✅ En-tête `X-FEDAPAY-SIGNATURE`, format `t=<horodatage>,s=<signature>`. Signature = HMAC-SHA256(secret, `"<t>.<corps brut>"`) en hexadécimal. Tolérance par défaut du SDK : 300 s (anti-rejeu).
- ✅ Node (testé : signature valide acceptée ; mauvais secret, corps modifié, signature vieille d'1 h rejetés) :
  ```js
  const { Webhook } = require('fedapay');
  // le corps doit être BRUT (Buffer ou string) : express.raw, req.text() (Next.js)…
  const event = Webhook.constructEvent(rawBody, req.headers['x-fedapay-signature'], process.env.FEDAPAY_WEBHOOK_SECRET);
  ```
  ✅ Passer un objet JSON déjà parsé fait **échouer** la vérification (testé).
- ✅ PHP (testé, SDK 0.4.9) : `\FedaPay\Webhook::constructEvent($request->getContent(), $request->header('X-FEDAPAY-SIGNATURE'), $secret)` ; erreur levée : `\FedaPay\Error\SignatureVerification`.
- ✅ Python (pas de SDK officiel utilisé) : `outils/fedapay_signature.py`, portage du SDK testé contre des signatures générées par le SDK officiel.
- 🟡 Le nom des événements (`transaction.approved`, `transaction.canceled`, `transaction.declined`…) et la place de l'identifiant de transaction dans le corps : lis l'exemple de la doc. Dans tous les cas, l'identifiant sert seulement à appeler `Transaction.retrieve` : c'est **cette réponse** qui décide (règles d'or 3 et 4).

## Tests

🟡 Clés et compte sandbox. Les numéros mobile money de test (succès / échec) sont dans la doc « mode test » ; ils peuvent changer, consulte-la.

## Opérations prises en charge

| Opération | Niveau | Détail |
| --- | --- | --- |
| Pay-in mobile money | ✅ / ❓ | page de paiement ✅ ; paiement direct ✅ mais nom du `mode` ❓ |
| Carte | 🟡 | proposée sur la page de paiement d'après la doc (cartes de test dans la doc « mode test ») |
| Payout | 🟡 | API « Payouts » documentée (`https://api.fedapay.com/v1/payouts/...`) ; champs à lire dans la référence API |
| Remboursement | ❓ | le statut `refunded` existe et la doc dit qu'un remboursement part de `approved` ou `transferred`, mais l'appel API n'est pas confirmé ici : vérifie la référence API avant de coder `refundPayment` |
| Récurrent | ❓ | rien de confirmé : ne pas proposer sans doc |
| Liste des transactions (réconciliation) | 🟡 | « Search your transactions » dans la référence API |

---

<!-- ===== FICHIER 20 : references/exemples/feexpay.md ===== -->

# [20] references/exemples/feexpay.md

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

---

<!-- ===== FICHIER 21 : references/exemples/kkiapay.md ===== -->

# [21] references/exemples/kkiapay.md

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

---

<!-- ===== FICHIER 22 : frameworks/express.md ===== -->

# [22] frameworks/express.md

# Express / Node.js

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Webhook : corps brut

✅ (testé avec express + SDK fedapay 1.2.5) La route du webhook lit le corps **brut**. Déclare-la **avant** `app.use(express.json())`, ou donne-lui son propre parseur :
```js
app.post('/webhooks/fedapay', express.raw({ type: 'application/json' }), async (req, res) => {
  const v = await adaptateurs.fedapay.verifyWebhook(req.body, req.headers);   // req.body est un Buffer
  if (!v.valide) return res.status(401).end();
  const nouveau = await enregistrerEvenement('fedapay', v.eventKey);
  if (!nouveau) return res.status(200).json({ ok: true });                   // doublon
  res.status(200).json({ ok: true });                                         // répondre vite…
  traiterEnArrierePlan('fedapay', v.referenceFournisseur);                    // …puis getPaymentStatus + appliquerTransition
});
app.use(express.json()); // pour le reste de l'API
```
Si le projet doit répondre seulement après traitement, traite d'abord puis réponds, mais reste sous quelques secondes.

Comparaison de secret à temps constant (KkiaPay) :
```js
const crypto = require('crypto');
function egal(a, b) {
  const x = Buffer.from(String(a || '')), y = Buffer.from(String(b || ''));
  return x.length === y.length && crypto.timingSafeEqual(x, y);   // timingSafeEqual lève une erreur si les longueurs diffèrent
}
```

## Base de données

🟡 Mise à jour atomique selon l'outil du projet :
- `pg` / Knex : `UPDATE ... WHERE id = $1 AND status = ANY($2)` puis `rowCount` (✅ testé avec `pg` dans `outils/test-concurrence-postgres.js`).
- Prisma : `const r = await tx.payment.updateMany({ where: { id, status: { in: depuis } }, data: { status: vers } }); if (r.count === 1) {...}` dans `prisma.$transaction(async (tx) => {...})`. Unicité : `@@unique([provider, providerRef])` ; index partiel : migration SQL manuelle. Erreur d'unicité : code `P2002`.
- Sequelize / TypeORM : `update(..., { where })` renvoie le nombre de lignes ; idem.

## Tâches de fond

🟡 Réutilise ce qui existe (BullMQ, Agenda, worker maison). Sinon :
- un seul processus : `node-cron` pour le rattrapage et la réconciliation ;
- plusieurs instances (PM2 en cluster, plusieurs conteneurs) : un seul planificateur, ou un verrou (`pg_try_advisory_lock`, verrou Redis) pour éviter les exécutions doubles.
- effets après commit : table outbox lue par le worker.

## Configuration

`process.env` + `.env` (dotenv) côté serveur seulement. Valide au démarrage que toutes les variables de paiement existent (le projet a peut-être déjà un validateur d'env : réutilise-le).

## Tests

✅ `nock` pour simuler l'agrégateur (ajoute les hôtes simulés à `NO_PROXY` derrière un proxy) ; `supertest` ou `http` natif pour appeler la route du webhook ; vraie base pour les tests de concurrence.

---

<!-- ===== FICHIER 23 : frameworks/nextjs.md ===== -->

# [23] frameworks/nextjs.md

# Next.js

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Où mettre le code

- Le code de paiement (adaptateurs, clés) ne vit **que** côté serveur : Route Handlers (`app/api/.../route.ts`), Server Actions ou routes API (`pages/api`). Marque les modules sensibles avec `import 'server-only'` pour qu'un import accidentel côté client échoue au build.
- 🟡 Variables d'environnement : les clés secrètes **sans** préfixe `NEXT_PUBLIC_`. Tout ce qui commence par `NEXT_PUBLIC_` est envoyé au navigateur : seule une clé **publique** (widget KkiaPay, par exemple) peut l'avoir.
- Création du paiement : Route Handler ou Server Action appelée par le client, avec l'utilisateur authentifié.
- **Webhook : toujours un Route Handler**, jamais une Server Action (une Server Action n'est pas une URL stable appelable par un service externe).

## Webhook : corps brut

🟡 App Router :
```ts
// app/api/webhooks/fedapay/route.ts
export const runtime = 'nodejs';        // crypto Node et SDK officiels ; pas le runtime edge
export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  const corpsBrut = await req.text();   // AVANT tout req.json()
  const v = await adaptateurs.fedapay.verifyWebhook(corpsBrut, Object.fromEntries(req.headers));
  if (!v.valide) return new Response('signature invalide', { status: 401 });
  // enregistrer l'événement, getPaymentStatus, appliquerTransition…
  return Response.json({ ok: true });
}
```
🟡 Pages Router : désactive le parseur (`export const config = { api: { bodyParser: false } }`) et lis le flux toi-même (paquet `raw-body` ou lecture des chunks).

Vérifie que le **middleware** d'authentification (`middleware.ts`) laisse passer `/api/webhooks/*`.

## Hébergement serverless (Vercel, Netlify…)

- Pas de tâche qui tourne en continu : le rattrapage et la réconciliation sont des routes protégées (secret dans un en-tête, par exemple `Authorization: Bearer ${CRON_SECRET}`) appelées par le cron de la plateforme (Vercel Cron Jobs) ou un cron externe.
- Durée maximale d'une fonction : un appel d'agrégateur qui attend la validation du client (FeexPay, par exemple) peut dépasser la limite. Mets un délai côté client plus court que la limite, traite le dépassement comme « en cours », et laisse le rattrapage conclure.
- Pas d'effet après réponse garanti sans outil dédié : traite le webhook **avant** de répondre (rapidement), ou utilise une file (Inngest, QStash, etc.) si le projet en a une.

## Base de données

🟡 Prisma / Drizzle : mêmes règles que `express.md` (mise à jour filtrée qui renvoie le nombre de lignes, transaction courte, unicité). En serverless, utilise le pooler de connexions prévu par l'hébergeur de la base.

## Interface

Composant client qui appelle la route de création, puis interroge `GET /api/payments/[id]` toutes les 3 à 5 s (arrêt au démontage et après le délai). La page de retour (`callback_url`) affiche le statut **de ta base**, jamais celui de l'URL.

---

<!-- ===== FICHIER 24 : frameworks/laravel.md ===== -->

# [24] frameworks/laravel.md

# Laravel

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Configuration

🟡 Les clés vont dans `.env`, lues **uniquement** dans `config/services.php` :
```php
'fedapay' => [
    'secret' => env('FEDAPAY_SECRET_KEY'),
    'webhook_secret' => env('FEDAPAY_WEBHOOK_SECRET'),
    'env' => env('FEDAPAY_ENV', 'sandbox'),
],
```
Dans le code : `config('services.fedapay.secret')`, jamais `env()` (qui renvoie `null` après `php artisan config:cache`).

## Webhook

🟡 Route dans `routes/api.php` (pas de protection CSRF sur les routes API). Si elle doit être dans `routes/web.php`, exclus-la du CSRF :
- Laravel 11 et + : `bootstrap/app.php` → `->withMiddleware(function (Middleware $middleware) { $middleware->validateCsrfTokens(except: ['webhooks/*']); })`
- Laravel 10 et - : tableau `$except` de `app/Http/Middleware/VerifyCsrfToken.php`.
(Laravel 11 : les routes API demandent `php artisan install:api` si `routes/api.php` n'existe pas.)

✅ Vérification FedaPay (SDK `fedapay/fedapay-php` 0.4.9, testée) :
```php
public function __invoke(Request $request)
{
    try {
        $event = \FedaPay\Webhook::constructEvent(
            $request->getContent(),                       // corps BRUT
            $request->header('X-FEDAPAY-SIGNATURE'),
            config('services.fedapay.webhook_secret')
        );
    } catch (\FedaPay\Error\SignatureVerification $e) {
        return response()->json(['ok' => false], 401);
    }
    // enregistrer l'événement (doublon -> 200), getPaymentStatus, appliquerTransition...
    return response()->json(['ok' => true]);
}
```
Comparaison de secret (KkiaPay) : `hash_equals($attendu, (string) $request->header('x-kkiapay-secret'))`.

## Base de données

🟡 Transition atomique :
```php
DB::transaction(function () use ($payment, $vers, $depuis) {
    $n = Payment::whereKey($payment->id)->whereIn('status', $depuis)->update(['status' => $vers]);
    if ($n === 1) {
        Order::whereKey($payment->order_id)->where('status', 'awaiting_payment')->update(['status' => 'paid']);
        DB::afterCommit(fn () => LivrerCommande::dispatch($payment->order_id));
    }
});
```
Alternative : `Payment::whereKey($id)->lockForUpdate()->first()` dans la transaction.
Unicité dans la migration : `$table->unique(['provider', 'provider_ref']);`. Index partiel (PostgreSQL) : `DB::statement("CREATE UNIQUE INDEX ... WHERE status = 'succeeded' AND anomalie IS NULL")`. Erreur d'unicité : `Illuminate\Database\UniqueConstraintViolationException` (Laravel 10.21+), sinon `QueryException`.

## Tâches de fond

🟡 Jobs dans la file existante (`ShouldQueue`), lancés `->afterCommit()`.
Planification :
- Laravel 11 et + : `routes/console.php` → `Schedule::job(new RattraperPaiements)->everyFiveMinutes()->withoutOverlapping();`
- Laravel 10 et - : `app/Console/Kernel.php`, méthode `schedule()`.
Et la ligne cron du serveur : `* * * * * php /chemin/artisan schedule:run`. Plusieurs serveurs : `->onOneServer()` (cache partagé requis).

## SDK

✅ FedaPay : `fedapay/fedapay-php` (webhook testé). ✅ FeexPay : `feexpay/feexpay-php` 3.x (signatures des méthodes lues ; voir `feexpay.md`). KkiaPay : SDK Admin PHP de la doc, ou appel HTTP avec `Http::withHeaders([...])->post(...)` (voir `kkiapay.md`).

## Tests

🟡 `Http::fake([...])` pour simuler l'agrégateur, `Http::preventStrayRequests()` pour interdire tout appel réel, `$this->postJson()` / `$this->call()` avec un corps brut pour le webhook, base PostgreSQL / MySQL de test pour la concurrence.

---

<!-- ===== FICHIER 25 : frameworks/django.md ===== -->

# [25] frameworks/django.md

# Django

Légende : ✅ testé · 🟡 API standard du framework, non exécutée ici.

## Configuration

🟡 Clés lues depuis l'environnement dans `settings.py` (`os.environ[...]`, ou `django-environ` si le projet l'utilise déjà). Jamais de clé en dur ni dans un fichier versionné.

## Webhook

✅ Vue testée (Django 6.1, client de test avec CSRF actif, signature générée par le SDK officiel FedaPay) :
```python
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.conf import settings
from .fedapay_signature import verifier_signature_fedapay   # copie de outils/fedapay_signature.py

@csrf_exempt              # le webhook vient de l'agrégateur, pas d'un formulaire
@require_POST
def webhook_fedapay(request):
    corps_brut = request.body                               # bytes, AVANT json.loads
    entete = request.headers.get("X-Fedapay-Signature", "")
    if not verifier_signature_fedapay(corps_brut, entete, settings.FEDAPAY_WEBHOOK_SECRET):
        return JsonResponse({"ok": False}, status=401)
    # enregistrer l'événement (doublon -> 200), getPaymentStatus, appliquer_transition...
    return JsonResponse({"ok": True})
```
Comparaison de secret (KkiaPay) : `hmac.compare_digest(attendu, request.headers.get("X-Kkiapay-Secret", ""))`.
Django REST Framework : une `APIView` avec `authentication_classes = []`, `permission_classes = [AllowAny]`, et lecture de `request.body` avant tout accès à `request.data`.

## Base de données

✅ Mise à jour filtrée (testée avec Django 6.1 : renvoie 1, puis 0 au second passage) :
```python
from django.db import transaction, IntegrityError

with transaction.atomic():
    n = Payment.objects.filter(pk=pid, status__in=depuis).update(status=vers)
    if n == 1:
        Order.objects.filter(pk=order_id, status="awaiting_payment").update(status="paid")
        transaction.on_commit(lambda: livrer_commande.delay(order_id))   # Celery, ou la file du projet
```
Alternative : `Payment.objects.select_for_update().get(pk=pid)` dans `transaction.atomic()`.
🟡 Contraintes dans `Meta.constraints` :
```python
models.UniqueConstraint(fields=["provider", "provider_ref"], name="paiement_ref_unique"),
models.UniqueConstraint(fields=["order"], condition=Q(status="succeeded", anomalie__isnull=True), name="un_succes_par_commande"),
```
Les contraintes **conditionnelles** sont gérées par PostgreSQL et SQLite, **pas par MySQL** (Django les ignore) : sur MySQL, utilise la colonne `success_order_id` unique (voir `fiabilite-paiements.md`). Erreur d'unicité : `IntegrityError`.

## Tâches de fond

🟡 Réutilise Celery / RQ / Django-Q si présent (Celery beat pour la planification). Sinon : une commande de gestion (`python manage.py rattraper_paiements`) lancée par cron toutes les 5 minutes, et une autre pour la réconciliation quotidienne.

## Tests

🟡 `responses` (requests) ou `respx` (httpx) pour simuler l'agrégateur ; `Client().post(url, data=corps, content_type="application/json", HTTP_X_FEDAPAY_SIGNATURE=entete)` pour le webhook ; `TransactionTestCase` + PostgreSQL pour la concurrence (les `TestCase` classiques enveloppent tout dans une transaction et masquent les problèmes de verrou).

---

<!-- ===== FICHIER 26 : frameworks/flutter.md ===== -->

# [26] frameworks/flutter.md

# Flutter (appli mobile)

Légende : ✅ testé · 🟡 API standard, non exécutée ici.

L'appli mobile **ne parle jamais directement à l'API de l'agrégateur avec une clé secrète**. Elle parle à **ton serveur** (Express, Next.js, Laravel, Django… voir les autres guides), qui parle à l'agrégateur.

## Ce qui est interdit dans l'appli

- clé secrète, clé privée, secret de webhook ;
- même « cachés » : un fichier `.env` chargé par `flutter_dotenv` est **inclus dans l'appli** ; une valeur passée avec `--dart-define` est **lisible** dans le binaire ; l'obfuscation ne protège pas un secret ;
- décider qu'une commande est payée.

Autorisé : l'URL de ton serveur, et une clé **publique** si le SDK de l'agrégateur l'exige (widget KkiaPay, SDK FeexPay Flutter…).

## Parcours

🟡 Création :
```dart
final res = await api.post('/payments', body: {
  'order_id': orderId,
  'network': reseau,            // si paiement direct
  'phone': numero,              // si paiement direct
}, headers: {'Idempotency-Key': cleTentative});   // une clé (UUID) par tentative, gardée si on réessaie la même tentative
```
- La réponse contient une **URL de paiement** → l'ouvrir avec `url_launcher` (navigateur externe) ou une WebView ; au retour (deep link ou retour dans l'appli), **interroger le serveur**.
- Ou bien « demande envoyée » → écran « Confirme le paiement sur ton téléphone avec ton code PIN ».

🟡 Attente du résultat (interroger **ton** serveur) :
```dart
Timer? _minuteur;
void suivre(String paymentId) {
  final fin = DateTime.now().add(const Duration(minutes: 3));
  _minuteur = Timer.periodic(const Duration(seconds: 4), (t) async {
    final p = await api.get('/payments/$paymentId');
    if (p['status'] == 'succeeded' || p['status'] == 'failed' || p['status'] == 'cancelled' || p['status'] == 'expired') {
      t.cancel(); afficherResultat(p['status']);
    } else if (DateTime.now().isAfter(fin)) {
      t.cancel(); afficherDelaiDepasse();   // « Si tu as été débité, ton paiement sera confirmé automatiquement. »
    }
  });
}
@override
void dispose() { _minuteur?.cancel(); super.dispose(); }
```
- Quand l'appli revient au premier plan (`AppLifecycleState.resumed`), revérifie le statut une fois.
- Bouton « Payer » désactivé pendant la requête (double clic).

## SDK d'agrégateur dans Flutter

Si l'agrégateur fournit un widget Flutter (KkiaPay, `feexpay_flutter_v2`…), son callback de succès sert **seulement** à prévenir ton serveur (envoyer la référence). Le serveur vérifie avec `getPaymentStatus` avant toute livraison. La doc du SDK FeexPay v2 le dit elle-même : le résultat reçu dans l'appli peut être falsifié.

## États à afficher

En attente · Réussi · Échoué (avec « Réessayer », qui crée une **nouvelle** tentative) · Délai dépassé · Erreur réseau (« Vérifie ta connexion », sans conclure sur le paiement).

## Tests

🟡 `MockClient` (`package:http/testing.dart`) pour simuler ton serveur : réponses `processing` puis `succeeded`, erreur réseau, délai dépassé, réponse inattendue.

---

<!-- ===== FICHIER 27 : outils/README.md ===== -->

# [27] outils/README.md

# `outils/` — implémentations de référence

## État honnête de ce dossier

Le pack d'origine annonçait trois implémentations de référence **testées** (PostgreSQL 16, 10 scénarios de concurrence, 10/10) :

- `outils/test-concurrence-postgres.js`
- `outils/test-sdk-fedapay-requetes.js`
- `outils/fedapay_signature.py`

**Ces trois fichiers n'ont jamais été livrés.** Les fichiers reçus qui portaient ces noms contenaient en réalité de la documentation (`reconciliation.md`, un extrait du `SKILL.md`, etc.). Le contenu des tests n'est donc pas récupérable.

Conséquence, à assumer dans le rapport final :

> **Les niveaux 1 et 2 de `references/tests.md` ne peuvent pas être présentés comme « déjà testés ».** Ils doivent être écrits puis exécutés sur le projet de l'utilisateur, et le rapport doit le dire.

## Ce qui est présent ici

| Fichier | Rôle | Niveau |
| --- | --- | --- |
| `schema-paiement.sql` | schéma PostgreSQL : statuts, contraintes d'unicité, index partiels, journal d'événements, table de webhooks, outbox, réconciliation | 🟡 écrit et relu, **non exécuté** (pas d'instance PostgreSQL dans la session) |

## Ce qu'il faut écrire avant de dire « testé »

### Niveau 1 — API simulée (aucune base, aucun réseau)

Un faux serveur HTTP qui rejoue :

1. une création de paiement réussie ;
2. un timeout réseau à la création ;
3. un webhook avec une signature valide ;
4. un webhook avec une signature invalide → doit être rejeté **avant** tout traitement ;
5. un webhook avec un corps modifié après signature ;
6. un webhook rejoué 5 fois → un seul effet ;
7. un statut `PENDING` → **pas** un échec ;
8. une réponse 500 de l'opérateur → retry, pas de perte ;
9. un webhook arrivé **avant** la réponse de création ;
10. un montant incohérent → refus.

### Niveau 2 — vraie base

Sur PostgreSQL, avec `schema-paiement.sql` :

1. deux webhooks `succeeded` simultanés sur le même paiement → une seule transition ;
2. deux créations simultanées avec la même clé d'idempotence → un seul paiement ;
3. un `failed` qui arrive après un `succeeded` → refusé (transition interdite) ;
4. un `succeeded` qui arrive après un `failed` → accepté **une seule fois** ;
5. un `refunded` après `succeeded` → accepté ; après `pending` → refusé ;
6. deux paiements `succeeded` sur la même échéance → **la contrainte partielle doit refuser** ;
7. réutilisation d'un `provider_ref` → refus ;
8. outbox : effet métier appliqué une seule fois même si le worker redémarre ;
9. transaction annulée → aucun effet de bord visible ;
10. 50 paiements concurrents sur 50 commandes → exactement 50 lignes, aucun blocage.

### Niveau 3 — sandbox / réel

Nécessite les clés de l'utilisateur et, en Guinée, très probablement un **premier paiement réel de petit montant** (Orange ne fournit pas toujours de sandbox sur ce marché — ❓). C'est l'utilisateur qui l'exécute et le confirme.

## Rappel

Ne jamais écrire « testé » pour du code seulement écrit. Voir `../SKILL.md`, règle d'or 7.

---

# Annexe - schema SQL de reference (outils/schema-paiement.sql)

```sql
-- Schema de reference : machine a etats et garde-fous (PostgreSQL 14+)
-- Non execute dans la session de redaction : a lancer et a valider avant de dire "teste".
-- Voir ../references/machine-etats.md et ../references/fiabilite-paiements.md

CREATE TABLE paiement (
  id                BIGSERIAL PRIMARY KEY,
  commande_id       BIGINT      NOT NULL,
  provider          TEXT        NOT NULL,          -- 'orange_money_gn' | 'mtn_momo_gn' | 'wave_gn' | 'paycard' ...
  provider_ref      TEXT,                          -- reference chez l'operateur (NULL avant creation)
  idempotency_key   TEXT        NOT NULL,          -- fournie par le client, rejouable sans risque
  montant_gnf       BIGINT      NOT NULL CHECK (montant_gnf > 0),
  devise            CHAR(3)     NOT NULL DEFAULT 'GNF' CHECK (devise = 'GNF'),
  statut            TEXT        NOT NULL DEFAULT 'pending',
  anomalie          TEXT,                          -- colonne separee : jamais dans statut
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT paiement_statut_valide CHECK (
    statut IN ('pending','processing','succeeded','failed','cancelled','expired','refunded')
  ),
  CONSTRAINT paiement_commande_chaine CHECK (char_length(commande_id::text) > 0)
);

-- Deux protections d'idempotence distinctes, ne pas en oublier une :
-- 1) le client qui rejoue sa requete ne cree pas un 2e paiement
CREATE UNIQUE INDEX paiement_idempotency_unique
  ON paiement (provider, idempotency_key);

-- 2) l'operateur qui renvoie deux fois la meme reference ne cree pas un 2e paiement
CREATE UNIQUE INDEX paiement_provider_ref_unique
  ON paiement (provider, provider_ref)
  WHERE provider_ref IS NOT NULL;

-- Un seul paiement reussi par commande (MySQL : pas d'index partiel -> colonne success_order_id)
CREATE UNIQUE INDEX paiement_commande_reussie_unique
  ON paiement (commande_id)
  WHERE statut = 'succeeded';

CREATE INDEX paiement_a_rattraper
  ON paiement (updated_at)
  WHERE statut IN ('pending','processing');

-- Journal ajout seul : aucune mise a jour, aucune suppression (droits a restreindre).
CREATE TABLE payment_events (
  id           BIGSERIAL PRIMARY KEY,
  paiement_id  BIGINT      NOT NULL REFERENCES paiement(id),
  source       TEXT        NOT NULL,      -- 'webhook' | 'status_check' | 'admin' | 'reconciliation' | 'client'
  statut_avant TEXT,
  statut_apres TEXT,
  detail       JSONB,                     -- reponse brute de l'operateur, acces restreint
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payment_events_paiement ON payment_events (paiement_id, created_at);

-- Doublons de webhook : la contrainte fait le travail, pas le code.
CREATE TABLE webhook_events (
  id            BIGSERIAL PRIMARY KEY,
  provider      TEXT NOT NULL,
  event_id      TEXT NOT NULL,            -- id d'evenement fourni par l'operateur
  provider_ref  TEXT,
  corps_sha256  CHAR(64) NOT NULL,        -- empreinte du corps brut, si pas d'event_id
  recu_le       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT webhook_events_unique UNIQUE (provider, event_id)
);
CREATE UNIQUE INDEX webhook_events_corps_unique
  ON webhook_events (provider, corps_sha256);

-- Outbox : aucun effet metier (recu, e-mail, passage de l'echeance a "payee")
-- ne part avant le COMMIT de la transition.
CREATE TABLE outbox (
  id           BIGSERIAL PRIMARY KEY,
  paiement_id  BIGINT NOT NULL REFERENCES paiement(id),
  type         TEXT   NOT NULL,           -- 'generer_recu' | 'notifier_parent' | 'maj_echeance'
  payload      JSONB  NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  traite_le    TIMESTAMPTZ,
  tentatives   INT NOT NULL DEFAULT 0
);
CREATE INDEX outbox_a_traiter ON outbox (created_at) WHERE traite_le IS NULL;
CREATE UNIQUE INDEX outbox_effet_unique ON outbox (paiement_id, type);

-- Reconciliation (voir ../references/reconciliation.md)
CREATE TABLE reconciliation_runs (
  id            BIGSERIAL PRIMARY KEY,
  periode_debut DATE NOT NULL,
  periode_fin   DATE NOT NULL,
  source        TEXT NOT NULL,            -- 'api' | 'csv' | 'status_checks'
  nb_local      INT, nb_provider INT,
  total_brut    BIGINT, total_frais BIGINT, total_net BIGINT,
  nb_ecarts     INT,
  statut        TEXT NOT NULL DEFAULT 'ouverte'
);

CREATE TABLE reconciliation_items (
  id           BIGSERIAL PRIMARY KEY,
  run_id       BIGINT NOT NULL REFERENCES reconciliation_runs(id),
  type_ecart   TEXT NOT NULL,             -- 'absent_local' | 'absent_provider' | 'statut' | 'montant' | 'frais' | 'double'
  paiement_id  BIGINT,
  provider_ref TEXT,
  valeur_locale   TEXT,
  valeur_provider TEXT,
  gravite      TEXT NOT NULL,             -- 'critique' | 'haute' | 'moyenne'
  statut       TEXT NOT NULL DEFAULT 'ouvert',   -- 'ouvert' | 'corrige' | 'accepte'
  commentaire  TEXT,
  traite_par   TEXT,
  traite_le    TIMESTAMPTZ
);

-- La seule fonction autorisee a ecrire "statut".
-- Atomicite : le WHERE teste le statut AVANT d'ecrire, en une seule instruction.
CREATE OR REPLACE FUNCTION appliquer_transition(
  p_id     BIGINT,
  p_attendu TEXT[],
  p_nouveau TEXT,
  p_source TEXT,
  p_detail JSONB DEFAULT NULL
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE v_avant TEXT;
BEGIN
  UPDATE paiement
     SET statut = p_nouveau, updated_at = now()
   WHERE id = p_id
     AND statut = ANY (p_attendu)              -- transitions autorisees uniquement
  RETURNING (SELECT statut FROM paiement WHERE id = p_id) INTO v_avant;

  IF NOT FOUND THEN
    RETURN NULL;                                -- deja traite : no-op, pas une erreur
  END IF;

  INSERT INTO payment_events (paiement_id, source, statut_avant, statut_apres, detail)
  VALUES (p_id, p_source, v_avant, p_nouveau, p_detail);

  RETURN p_nouveau;
END $$;
```
