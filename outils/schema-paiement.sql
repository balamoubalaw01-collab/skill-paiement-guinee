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
