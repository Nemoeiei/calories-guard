from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from chatbot_agent import CoachingAgent
from ai_models.multi_agent_system import NutritionMultiAgent
from app.models.schemas import ChatMessage

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

coach_agent = CoachingAgent()
_multi_agent = NutritionMultiAgent()


@router.post("/api/chat/coach")
@limiter.limit("10/hour")
def chat_with_coach(request: Request, payload: ChatMessage):
    """พูดคุยกับ AI Coach ที่วิเคราะห์ประวัติการกินของคุณ"""
    try:
        response_text = coach_agent.generate_response(payload.user_id, payload.message)
        return {"response": response_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Coach Error: {str(e)}")


@router.post("/api/chat/multi")
@limiter.limit("10/hour")
def chat_multi_agent(request: Request, payload: ChatMessage):
    """
    3-Agent AI pipeline:
      Agent1 (DataOrchestrator) -> Agent2 (NutritionAnalysis) -> Agent3 (ResponseComposer/Gemini)
    """
    try:
        response_text = _multi_agent.run(
            payload.user_id, payload.message,
            lat=payload.lat, lng=payload.lng)
        return {"response": response_text, "agent": "multi_3"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Multi-Agent Error: {str(e)}")
