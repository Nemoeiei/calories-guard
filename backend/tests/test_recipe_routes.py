"""Recipe route registration regressions."""


def test_single_recipe_detail_route_registered(app_client):
    """There must be one owner for GET /recipes/{food_id}.

    The app chose the JSONB + LLM-cache recipe path in app.routers.foods.
    Keeping this assertion makes a future reintroduction of the old monolith
    route fail loudly instead of creating schema drift.
    """
    matches = [
        route
        for route in app_client.app.routes
        if getattr(route, "path", None) == "/recipes/{food_id}"
        and "GET" in getattr(route, "methods", set())
    ]

    assert len(matches) == 1
    assert matches[0].endpoint.__module__ == "app.routers.foods"
