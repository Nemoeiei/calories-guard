import ai_models.multi_agent_system as mas


def test_llm_extracts_unknown_food_when_dictionary_misses(monkeypatch):
    agent = mas.NutritionAnalysisAgent()
    monkeypatch.setattr(agent, "_load_food_dictionary", lambda: [])
    monkeypatch.setattr(mas, "llm_is_configured", lambda: True)
    monkeypatch.setattr(
        mas,
        "llm_generate",
        lambda system, user: '{"items":[{"name":"โรตีชีสภูเขาไฟ","quantity":1}]}',
    )

    result = agent._extract_foods("กินโรตีชีสภูเขาไฟ 1 จาน")

    assert result == [
        {"name": "โรตีชีสภูเขาไฟ", "quantity": 1.0, "source": "llm_extract"}
    ]


def test_unknown_food_estimate_queues_temp_food(monkeypatch):
    agent = mas.NutritionAnalysisAgent()
    queued = []
    monkeypatch.setattr(mas, "llm_is_configured", lambda: True)
    monkeypatch.setattr(
        mas,
        "llm_generate",
        lambda system, user: '{"calories":420,"protein":12,"carbs":55,"fat":16}',
    )
    monkeypatch.setattr(
        agent,
        "_auto_add_temp_food",
        lambda name, nutrition, user_id=None: queued.append((name, nutrition, user_id)),
    )

    result = agent._estimate_food_llm("โรตีชีสภูเขาไฟ", user_id=123)

    assert result["source"] == "llm_estimate"
    assert result["calories"] == 420
    assert queued[0][0] == "โรตีชีสภูเขาไฟ"
    assert queued[0][2] == 123
