"""
Scheduled cleanup job.

Hard-deletes users whose `deleted_at` is older than the PDPA retention
window (30 days). Every child row follows via FK `ON DELETE CASCADE`.

Run manually:
    python -m backend.scripts.cleanup

Run via cron (Railway scheduled task, 04:00 Asia/Bangkok daily):
    0 21 * * *    python -m backend.scripts.cleanup

The 30-day window is a balance between:
  - PDPA gives us "reasonable time" to action a deletion request.
  - Support tickets after an accidental tap often arrive within a week.
  - Keeping tombstones around forever defeats the purpose of "delete".

If you change RETENTION_DAYS, update docs/PRIVACY.md and the response
body in `DELETE /users/{id}` so the user-facing number stays honest.
"""
from __future__ import annotations

import os
import sys
import logging
from datetime import datetime, timezone

# Allow `python backend/scripts/cleanup.py` to work from repo root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import get_db_connection  # noqa: E402

RETENTION_DAYS = int(os.getenv("PDPA_RETENTION_DAYS", "30"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("cleanup")


def hard_delete_tombstoned_users() -> int:
    conn = get_db_connection()
    if conn is None:
        log.error("DB unavailable; aborting cleanup")
        return 0
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT user_id, deleted_at
            FROM users
            WHERE deleted_at IS NOT NULL
              AND deleted_at < NOW() - (%s || ' days')::interval
            """,
            (RETENTION_DAYS,),
        )
        victims = cur.fetchall()
        if not victims:
            log.info("no tombstoned users past retention (%d days)", RETENTION_DAYS)
            return 0

        for user_id, deleted_at in victims:
            log.info("hard-deleting user_id=%s deleted_at=%s", user_id, deleted_at)

        cur.execute(
            """
            DELETE FROM users
            WHERE deleted_at IS NOT NULL
              AND deleted_at < NOW() - (%s || ' days')::interval
            """,
            (RETENTION_DAYS,),
        )
        conn.commit()
        return cur.rowcount or 0
    except Exception:
        conn.rollback()
        log.exception("cleanup failed")
        raise
    finally:
        conn.close()


def main() -> None:
    start = datetime.now(timezone.utc)
    deleted = hard_delete_tombstoned_users()
    elapsed = (datetime.now(timezone.utc) - start).total_seconds()
    log.info("cleanup done: %d users hard-deleted in %.2fs", deleted, elapsed)


if __name__ == "__main__":
    main()
