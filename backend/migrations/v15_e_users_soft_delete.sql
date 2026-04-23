-- v15_e: PDPA soft-delete column on cleangoal.users
--
-- Why: #16 requires `DELETE /users/me` to set a tombstone so we keep an
-- auditable window before hard-delete (30-day retention, cleaned by
-- backend/scripts/cleanup.py cron). ON DELETE CASCADE on every child FK
-- handles the eventual hard-delete.
--
-- Contract:
--   deleted_at IS NULL           → account active
--   deleted_at IS NOT NULL       → tombstoned; treat as logged-out on the
--                                   application layer; hidden from /users/me
--                                   endpoints; removed by cleanup job after 30 days

BEGIN;

ALTER TABLE cleangoal.users
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Partial index: only the live rows are hot; tombstones are rare.
CREATE INDEX IF NOT EXISTS users_deleted_at_idx
    ON cleangoal.users (deleted_at)
    WHERE deleted_at IS NOT NULL;

INSERT INTO cleangoal.schema_migrations (version)
VALUES ('v15_e_users_soft_delete')
ON CONFLICT (version) DO NOTHING;

COMMIT;
