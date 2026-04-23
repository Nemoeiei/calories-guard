-- v14 Phase D — Rename units.conversion_factor -> quantity, seed standard units
-- Applied to Supabase cleangoal schema on 2026-04-18.
-- See docs/DB_V14_NORMALIZE_PROPOSAL.md for rationale and rollback plan.

BEGIN;

-- D.1 Rename column to match backend query in backend/app/routers/health.py:88
--     (SELECT unit_id, name, quantity FROM units)
ALTER TABLE cleangoal.units RENAME COLUMN conversion_factor TO quantity;

-- D.2 Seed a minimal standard unit catalogue. Gracefully no-op if rows exist.
INSERT INTO cleangoal.units (name, quantity) VALUES
    ('g',       1),
    ('kg',      1000),
    ('mg',      0.001),
    ('ml',      1),
    ('l',       1000),
    ('tsp',     5),
    ('tbsp',    15),
    ('cup',     240),
    ('oz',      28.3495),
    ('piece',   1),
    ('serving', 1),
    ('slice',   1),
    ('bowl',    1),
    ('plate',   1),
    ('glass',   1)
ON CONFLICT DO NOTHING;

-- D.3 Seed common unit -> unit conversions (stored as multiplicative factors)
-- Rows are idempotent via ON CONFLICT DO NOTHING if a uniqueness constraint
-- exists; otherwise this block should be run once.
INSERT INTO cleangoal.unit_conversions (from_unit_id, to_unit_id, multiplier)
SELECT f.unit_id, t.unit_id, m.multiplier
FROM (VALUES
    ('kg',   'g',  1000.0),
    ('l',    'ml', 1000.0),
    ('tbsp', 'g',  15.0),
    ('tsp',  'g',  5.0),
    ('cup',  'ml', 240.0)
) AS m(from_name, to_name, multiplier)
JOIN cleangoal.units f ON f.name = m.from_name
JOIN cleangoal.units t ON t.name = m.to_name
ON CONFLICT DO NOTHING;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v14_d_seed_units')
    ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ROLLBACK:
-- ALTER TABLE cleangoal.units RENAME COLUMN quantity TO conversion_factor;
-- DELETE FROM cleangoal.unit_conversions WHERE ...;  (select seeded rows by name join)
-- DELETE FROM cleangoal.units WHERE name IN ('g','kg','mg','ml','l','tsp','tbsp','cup','oz','piece','serving','slice','bowl','plate','glass');
-- DELETE FROM cleangoal.schema_migrations WHERE version = 'v14_d_seed_units';
