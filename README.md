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

## Paquets prêts à distribuer

Le dossier [`dist/`](dist/LIRE-MOI-DIST.md) contient des versions prêtes à l'emploi :

- [`dist/PAIEMENT-GUINEE-PACK.md`](dist/PAIEMENT-GUINEE-PACK.md) — tout le skill en un seul fichier, à téléverser dans un Projet ChatGPT.
- [`dist/INSTRUCTIONS-CHATGPT.md`](dist/INSTRUCTIONS-CHATGPT.md) — version condensée sous 8 000 caractères, pour le champ *Instructions* d'un GPT personnalisé.
- [`dist/skill-paiement-guinee.zip`](dist/skill-paiement-guinee.zip) — archive complète du skill.
- [`dist/skill-paiement-guinee.bundle`](dist/skill-paiement-guinee.bundle) — miroir Git pour republier le dépôt sur un autre compte.

## Niveaux de confiance

✅ vérifié (exécuté / source SDK) · 🟡 indicatif (doc, non exécuté) · 📄 doc recopiée · ❓ non confirmé · **NON TROUVÉ** aucune source.

Une information `❓` ou `NON TROUVÉ` n'est jamais transformée en code de production. C'est la règle qui évite les intégrations fantômes.

## Crédit

Structure, procédure en 10 étapes, 7 règles d'or et système de niveaux de confiance repris du skill **« Intégrer un agrégateur de paiement » — Eric Dev**. Fiches guinéennes, journal de vérifications, schéma SQL et cas d'usage scolaire ajoutés.

Fourni gratuitement, sans garantie. Les API des opérateurs changent : relis toujours l'intégration avant la mise en production.
