"""General health chat + dynamic image question endpoints."""
import base64
import logging
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

from services.gemini_service import chat_health, generate_questions_for_image

router  = APIRouter()
logger  = logging.getLogger(__name__)


# ── /image-questions ──────────────────────────────────────────────────────────

class ImageQuestionsRequest(BaseModel):
    image_base64: str
    scan_type: str = "oral"   # "oral" | "skin" | "other"


@router.post("/image-questions")
async def image_questions(req: ImageQuestionsRequest):
    """Send image to Gemini and get contextual symptom questions back.

    Response: { "questions": [ {id, en, hi, ta, te, options_en, options_hi, options_ta, options_te} ] }
    """
    scan_type = req.scan_type if req.scan_type in ("oral", "skin") else "oral"

    try:
        image_bytes = base64.b64decode(req.image_base64)
        if len(image_bytes) < 100:
            raise ValueError("Image too small")
    except Exception:
        # If image is bad, return static fallback questions
        from services.gemini_service import SYMPTOM_QUESTIONS
        return {"questions": SYMPTOM_QUESTIONS.get(scan_type, []), "source": "static"}

    questions = await generate_questions_for_image(image_bytes, scan_type)
    return {"questions": questions, "source": "gemini"}


# ── /chat ─────────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str     # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []
    language: str = "en"


@router.post("/chat")
async def chat(req: ChatRequest):
    """General health chat powered by Gemini.

    Response: { "response": str, "error": str|null }
    """
    if not req.message.strip():
        return {"response": "", "error": "Empty message"}

    history = [{"role": m.role, "content": m.content} for m in req.history]
    result  = await chat_health(
        message=req.message.strip(),
        history=history,
        language=req.language,
    )
    return result
