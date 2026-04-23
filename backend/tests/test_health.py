"""Health + liveness + static routing tests."""


def test_root_returns_message(unauth_client):
    r = unauth_client.get("/")
    assert r.status_code == 200
    assert "message" in r.json()


def test_health_endpoint_ok(unauth_client):
    r = unauth_client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["api_version"]  # non-empty — matches API_VERSION constant
    # header stamped by add_api_version_header middleware
    assert r.headers.get("x-api-version") == body["api_version"]
