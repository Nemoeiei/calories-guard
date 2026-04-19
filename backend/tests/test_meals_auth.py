"""
Ownership-guard tests for the meals router.

These complement test_auth_guard.py: that file checks 401 without a
token, this file checks 403 when a token *is* present but for a
different user. All meal/log endpoints must enforce `check_ownership`.
"""
import pytest

# (method, path) where :user_id in the path is user 99 and the fake
# authenticated user (from conftest) is user 42.
OTHER_USER_ENDPOINTS = [
    ("GET", "/meals/99/detail?date_record=2026-04-19&meal_type=breakfast"),
    ("GET", "/daily_summary/99?date_record=2026-04-19"),
    ("GET", "/daily_logs/99?date_query=2026-04-19"),
    ("GET", "/daily_logs/99/weekly"),
    ("GET", "/daily_logs/99/calendar?month=4&year=2026"),
    ("DELETE", "/meals/clear/99?date_record=2026-04-19&meal_type=breakfast"),
]


@pytest.mark.parametrize("method,path", OTHER_USER_ENDPOINTS)
def test_meal_endpoints_block_cross_user_access(app_client, method, path):
    r = app_client.request(method, path)
    assert r.status_code == 403, f"{method} {path} should 403, got {r.status_code}"
