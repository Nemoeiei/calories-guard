# Integration tests

Talks to a real Postgres. Skipped by default.

## Running

**Local docker-compose** (preferred):

```bash
docker-compose up -d db             # from repo root
# wait ~5s for the DB to come up, then:
cd backend
python run_migrations.py            # seeds schema + v8..v15 migrations
python -m pytest tests/integration -m integration -v
```

**Point at a throwaway Supabase branch** (read-only CI without docker):

```bash
DB_MODE=supabase \
SUPABASE_HOST=... SUPABASE_USER=... SUPABASE_PASSWORD=... \
python -m pytest tests/integration -m integration -v
```

## Adding a new flow

1. Put it in `tests/integration/test_<feature>.py`.
2. Decorate the module with `pytestmark = pytest.mark.integration`.
3. Prefer the `test_user_id` fixture — it seeds a throwaway user that's
   rolled back at teardown. Don't hand-craft user rows.
4. Use `client_as_user` (see test_e2e_meal.py) to override
   `get_current_user` so the router believes you're authenticated.

## What NOT to integration-test

- Pydantic schema validation (unit-test covers it faster).
- Auth guard 401/403 branches (also unit-testable).
- Gemini / third-party APIs — mock those even here.

Integration tests should catch migration drift, wrong column names, and
trigger regressions (e.g. daily_summaries totals). Anything else is
overkill.
