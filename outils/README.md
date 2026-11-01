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
