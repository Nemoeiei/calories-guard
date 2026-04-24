"""Recipe social route regressions."""
from datetime import datetime
from unittest.mock import MagicMock, patch


def test_recipe_reviews_resolve_food_id_to_recipe_id(app_client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur
    mock_cur.fetchone.return_value = {"recipe_id": 77}
    mock_cur.fetchall.return_value = [
        {
            "review_id": 1,
            "user_id": 42,
            "username": "somying",
            "rating": 5,
            "comment": "ดีมาก",
            "created_at": datetime(2026, 4, 24, 12, 0, 0),
            "review_count": 1,
            "avg_rating": 5,
            "five_star": 1,
            "four_star": 0,
            "three_star": 0,
            "two_star": 0,
            "one_star": 0,
        }
    ]

    with patch("app.routers.social.get_db_connection", return_value=mock_conn):
        response = app_client.get("/recipes/12/reviews")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["review_count"] == 1
    assert body["reviews"][0]["username"] == "somying"

    resolve_sql = mock_cur.execute.call_args_list[0].args[0]
    review_sql = mock_cur.execute.call_args_list[1].args[0]
    review_params = mock_cur.execute.call_args_list[1].args[1]
    assert "FROM recipes" in resolve_sql
    assert "WHERE food_id = %s" in resolve_sql
    assert "recipe_reviews WHERE recipe_id = %s" in review_sql
    assert review_params == (77, 77)


def test_recipe_review_upsert_writes_recipe_id(app_client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur
    mock_cur.fetchone.side_effect = [{"recipe_id": 77}, {"review_id": 9}]

    with patch("app.routers.social.get_db_connection", return_value=mock_conn):
        response = app_client.post(
            "/recipes/12/review",
            json={"user_id": 42, "rating": 4, "comment": "อร่อย"},
        )

    assert response.status_code == 200, response.text
    assert response.json()["review_id"] == 9

    insert_sql = mock_cur.execute.call_args_list[1].args[0]
    insert_params = mock_cur.execute.call_args_list[1].args[1]
    assert "INSERT INTO recipe_reviews (recipe_id, user_id, rating, comment)" in insert_sql
    assert "ON CONFLICT (recipe_id, user_id)" in insert_sql
    assert insert_params == (77, 42, 4, "อร่อย")
    mock_conn.commit.assert_called_once()


def test_recipe_reviews_404_when_recipe_missing(app_client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_conn.cursor.return_value = mock_cur
    mock_cur.fetchone.return_value = None

    with patch("app.routers.social.get_db_connection", return_value=mock_conn):
        response = app_client.get("/recipes/999/reviews")

    assert response.status_code == 404
    assert response.json()["detail"] == "Recipe not found"
