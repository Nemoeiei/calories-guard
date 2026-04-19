"""
Verify that protected endpoints reject unauthenticated requests with 401.

This is a critical regression test: before the Supabase Auth migration
(commit 4106a30), every endpoint was publicly accessible.
"""
import pytest


PROTECTED_ENDPOINTS = [
    ("GET", "/users/1"),
    ("GET", "/users/1/lifecycle_check"),
    ("GET", "/users/1/weight_logs"),
    ("GET", "/users/1/export"),
    ("DELETE", "/users/1"),
    ("GET", "/water_logs/1"),
    ("GET", "/notifications/1"),
    ("GET", "/insights/1"),
    ("GET", "/admin/temp-foods"),
    ("GET", "/admin/users"),
    ("GET", "/admin/temp-foods/pending-count"),
    ("GET", "/admin/foods/similar?name=test"),
    ("GET", "/admin/food-requests"),
]


@pytest.mark.parametrize("method,path", PROTECTED_ENDPOINTS)
def test_protected_endpoints_return_401_without_token(unauth_client, method, path):
    r = unauth_client.request(method, path)
    assert r.status_code == 401, f"{method} {path} should require auth, got {r.status_code}"


def test_public_endpoints_accessible_without_token(unauth_client):
    """/foods and /recommended-food are public (read-only)."""
    # These hit the DB which is None, so they'll 500, but NOT 401
    r = unauth_client.get("/foods")
    assert r.status_code != 401
    r = unauth_client.get("/recommended-food")
    assert r.status_code != 401
