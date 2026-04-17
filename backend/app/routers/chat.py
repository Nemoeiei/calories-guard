"""
Chat endpoints for AI Coach + 3-agent nutrition pipeline.

Hardening:
- Input sanitization (trim, strip control chars, cap at 2000 chars)
- 30s timeout so a wedged Gemini call doesn't tie up a worker
- Rate limit: 10 requests/hour per remote IP
"""
import re
import concurrent.futures

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

_AI_TIMEOUT_SEC = 30
_MAX_MSG_LEN = 2000
# strip control chars except tab/newline
_CONTROL_CHAR_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


def _sanitize_message(msg: str) -> str:
    s = (msg or "").strip()
    s = _CONTROL_CHAR_RE.sub("", s)
    if len(s) > _MAX_MSG_LEN:
        s = s[:_MAX_MSG_LEN]
    return s


def _run_with_timeout(fn, *args, **kwargs):
    """Run a blocking AI call in a thread and enforce _AI_TIMEOUT_SEC."""
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as ex:
        future = ex.submit(fn, *args, **kwargs)
        try:
            return future.result(timeout=_AI_TIMEOUT_SEC)
        except concurrent.futures.TimeoutError:
            raise HTTPException(status_code=504, detail="AI ตอบช้าเกินไป กรุณาลองใหม่")


@router.post("/api/chat/coach")
@limiter.limit("10/hour")
def chat_with_coach(request: Request, payload: ChatMessage):
    """พูดคุยกับ AI Coach ที่วิเคราะห์ประวัติการกินของคุณ"""
    msg = _sanitize_message(payload.message)
    if not msg:
        raise HTTPException(status_code=400, detail="ข้อความว่างเปล่า")
    try:
        response_text = _run_with_timeout(
            coach_agent.generate_response, payload.user_id, msg
        )
        return {"response": response_text}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Coach Error: {str(e)}")


@router.post("/api/chat/multi")
@limiter.limit("10/hour")
def chat_multi_agent(request: Request, payload: ChatMessage):
    """
    3-Agent AI pipeline:
      Agent1 (DataOrchestrator) -> Agent2 (NutritionAnalysis) -> Agent3 (ResponseComposer/Gemini)
    """
    msg = _sanitize_message(payload.message)
    if not msg:
        raise HTTPException(status_code=400, detail="ข้อความว่างเปล่า")
    try:
        response_text = _run_with_timeout(
            _multi_agent.run,
            payload.user_id, msg,
            lat=payload.lat, lng=payload.lng,
        )
        return {"response": response_text, "agent": "multi_3"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Multi-Agent Error: {str(e)}")
