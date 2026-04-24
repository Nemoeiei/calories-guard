-- v16_a: AI-generated recipe enrichment columns.
--
-- The /recipes/{food_id} endpoint now falls back to an LLM when no
-- seeded recipe exists. The generated payload is stored in recipes so
-- each food only costs one LLM call (cached forever). We keep the
-- structured JSON next to the free-text `instructions` because the
-- Flutter RecipeDetailScreen expects discrete lists of ingredients,
-- tools, and tips — parsing those back out of prose would be lossy.

BEGIN;

ALTER TABLE cleangoal.recipes
  ADD COLUMN IF NOT EXISTS ingredients_json JSONB,
  ADD COLUMN IF NOT EXISTS tools_json JSONB,
  ADD COLUMN IF NOT EXISTS tips_json JSONB,
  ADD COLUMN IF NOT EXISTS generated_by VARCHAR(32);

-- Mark existing hand-entered rows so we can tell seeded vs LLM-generated
-- data apart in admin tools later.
UPDATE cleangoal.recipes SET generated_by = 'seed' WHERE generated_by IS NULL;

INSERT INTO cleangoal.schema_migrations(version) VALUES ('v16_a_recipes_ai_fields')
    ON CONFLICT (version) DO NOTHING;

COMMIT;
