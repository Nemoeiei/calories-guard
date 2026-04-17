"""Tests for AI scope guard in chatbot_agent and multi_agent_system."""
import os
import sys

import pytest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)


def test_coaching_agent_rejects_off_topic():
    """Asking about code/math/news must return polite rejection."""
    from chatbot_agent import _is_in_scope, _REJECT_MSG

    # Off-topic
    assert not _is_in_scope("เขียนโค้ด python ให้หน่อย")
    assert not _is_in_scope("what is 1 + 1?")
    assert not _is_in_scope("ข่าวการเมืองวันนี้")

    # Rejection message mentions scope
    assert "โภชนาการ" in _REJECT_MSG or "อาหาร" in _REJECT_MSG


def test_coaching_agent_accepts_nutrition_questions():
    from chatbot_agent import _is_in_scope

    assert _is_in_scope("ข้าวผัดกะเพรากี่แคล")
    assert _is_in_scope("แนะนำเมนูลดน้ำหนัก")
    assert _is_in_scope("BMI ของผม")
    assert _is_in_scope("how many calories in pad thai")
    assert _is_in_scope("วิ่งเผาผลาญเยอะไหม")


def test_multi_agent_scope_guard_exists():
    """The 3-agent system must also reject off-topic."""
    from ai_models.multi_agent_system import _is_in_scope, _REJECT_MSG

    assert not _is_in_scope("hack the mainframe")
    assert _is_in_scope("อยากกินอะไรดี")
    assert "โภชนาการ" in _REJECT_MSG or "อาหาร" in _REJECT_MSG
