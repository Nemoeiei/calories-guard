"""
PDPA export + soft-delete route tests.

We mock psycopg2 at the router level rather than hitting a live DB; this
exercises the HTTP contract (ownership guard, JSON shape, attachment
headers, 404 on already-tombstoned) without a Supabase dependency.
"""
import json
from unittest.mock import MagicMock, patch


def _row(**kwargs):
    """Rows returned by RealDictCursor behave like dicts."""
    return dict(kwargs)


def test_export_returns_attachment_and_expected_keys(app_client):
    # 12 table queries + the initial users SELECT = 13 fetches; patch the
    # connection factory used inside users.py.
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur

    # fetchone -> the user profile; fetchall -> one-row dataset per child
    mock_cur.fetchone.return_value = _row(user_id=42, username="somying", email="s@x.com")
    mock_cur.fetchall.return_value = [_row(id=1, user_id=42)]

    with patch("app.routers.users.get_db_connection", return_value=mock_conn):
        r = app_client.get("/users/42/export")

    assert r.status_code == 200, r.text
    assert r.headers["content-disposition"].startswith("attachment")
    assert 'filename="calories_guard_export_42.json"' in r.headers["content-disposition"]

    body = json.loads(r.content)
    assert body["user_id"] == 42
    assert body["export_version"] == 1
    assert "exported_at" in body
    assert body["users"]["username"] == "somying"
    # every declared child table key is present
    for key in (
        "meals", "daily_summaries", "detail_items", "weight_logs",
        "water_logs", "exercise_logs", "notifications",
        "user_allergy_preferences", "user_favorites", "user_meal_plans",
        "temp_food", "food_requests",
    ):
        assert key in body, f"missing export key: {key}"


def test_export_blocks_other_users(app_client):
    # default fake user is user_id=42; asking for /users/99/export must 403
    r = app_client.get("/users/99/export")
    assert r.status_code == 403


def test_soft_delete_marks_deleted_at(app_client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur
    mock_cur.rowcount = 1  # the UPDATE hit one row

    with patch("app.routers.users.get_db_connection", return_value=mock_conn):
        r = app_client.delete("/users/42")

    assert r.status_code == 200
    assert r.json()["retention_days"] == 30
    # verify the UPDATE … deleted_at = NOW() query was the one we ran
    sent_sql = mock_cur.execute.call_args[0][0]
    assert "deleted_at = NOW()" in sent_sql
    assert "deleted_at IS NULL" in sent_sql  # guards against re-delete


def test_soft_delete_404_when_already_tombstoned(app_client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur
    mock_cur.rowcount = 0  # no live row matched

    with patch("app.routers.users.get_db_connection", return_value=mock_conn):
        r = app_client.delete("/users/42")

    assert r.status_code == 404


def test_soft_delete_blocks_other_users(app_client):
    r = app_client.delete("/users/99")
    assert r.status_code == 403
