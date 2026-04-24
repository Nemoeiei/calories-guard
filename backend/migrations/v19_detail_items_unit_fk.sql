-- v19: Add the remaining unit FK for meal/detail rows.
--
-- v18 includes this for fresh rebuilds. This separate idempotent migration
-- brings the already-migrated live Supabase database to the same state.

BEGIN;

UPDATE cleangoal.detail_items di
   SET unit_id = NULL
 WHERE di.unit_id IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM cleangoal.units u WHERE u.unit_id = di.unit_id
   );

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'cleangoal.detail_items'::regclass
          AND conname = 'detail_items_unit_id_fkey'
    ) THEN
        ALTER TABLE cleangoal.detail_items
            ADD CONSTRAINT detail_items_unit_id_fkey
            FOREIGN KEY (unit_id)
            REFERENCES cleangoal.units(unit_id)
            ON DELETE SET NULL;
    END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_detail_items_unit_id
    ON cleangoal.detail_items(unit_id);

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v19_detail_items_unit_fk')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

