# Skill « Intégrer un agrégateur de paiement » — par Eric Dev

Ce skill apprend à Claude à brancher ton appli sur un agrégateur de paiement (FeexPay, FedaPay, KkiaPay ou n'importe quel autre) pour encaisser le mobile money : MTN, Moov, Celtiis, Orange, Wave…
Claude fait l'intégration de A à Z. Toi, tu fournis tes clés et tu testes.

## Ce que Claude fait avec ce skill

- Il analyse ton projet (langage, framework, base de données, hébergement) et respecte ton code existant.
- Il lit la documentation officielle de l'agrégateur et te dit clairement ce qui est confirmé et ce qui ne l'est pas. Il n'invente pas.
- Il crée une interface commune avec un adaptateur par agrégateur, pour que tu puisses en changer plus tard.
- Il gère les paiements entrants et, si l'agrégateur le permet : remboursements, versements sortants (payouts), carte, paiements récurrents.
- Il sécurise les webhooks et met en place une vraie machine à états. Les doublons, les messages reçus dans le désordre et les paiements tardifs ne cassent pas tes commandes.
- Il ajoute la récupération des paiements bloqués, la réconciliation quotidienne et des alertes.
- Il écrit et lance des tests automatiques : erreurs réseau, délais dépassés, fausses signatures, paiements simultanés.
- À la fin, il te donne un rapport honnête : ce qui est fait, ce qui est testé, ce qui reste à tester avec tes vraies clés.

Guides inclus : Express, Next.js, Laravel, Django, Flutter. Fiches détaillées : FedaPay, KkiaPay, FeexPay.

## Installer

- **Claude Code** : copie le dossier `integrer-agregateur-paiement` dans `~/.claude/skills/` (pour tous tes projets), ou dans `.claude/skills/` à la racine de ton projet.
- **Claude (web ou application)** : ouvre les paramètres, va dans la partie Skills et importe le fichier `.zip`.

## Utiliser

Ouvre ton projet avec Claude et écris par exemple :

> Utilise le skill integrer-agregateur-paiement pour intégrer FedaPay dans mon appli. Je veux que le client paie sa commande avec MTN ou Moov.

## Avant de commencer

- Crée ton compte chez l'agrégateur et récupère tes **clés de test** (sandbox).
- Ne colle jamais ta clé secrète dans la conversation : mets-la toi-même dans le fichier `.env` de ton serveur.
- Pour passer en réel, ton compte marchand doit être vérifié (KYC) chez l'agrégateur.
- Fais toujours un premier paiement réel de petit montant avant d'ouvrir à tes clients.

Ce skill est fourni gratuitement, sans garantie. Les API des agrégateurs changent : relis toujours ton intégration avant la mise en production.
