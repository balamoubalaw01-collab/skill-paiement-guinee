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

> Utilise le skill integrer-paiement-guinee pour intégrer Orange Money Guinée dans mon appli de gestion des élèves. Le parent paie les frais de scolarité en GNF.

ou

> Utilise le skill integrer-paiement-guinee : je veux encaisser Orange Money, MTN et la carte Visa. Choisis l'agrégateur et dis-moi ce qui est confirmé.

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
