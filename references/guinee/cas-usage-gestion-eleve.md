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
