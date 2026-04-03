"""REST endpoint used by the Flutter app for combined TFLite + Gemini analysis."""
import base64
import logging
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from services.gemini_service import (
    DISCLAIMER,
    SYMPTOM_QUESTIONS,
    analyze_image_with_gemini,
    check_image_quality,
)
from services.ml_service import run_inference

router = APIRouter()
logger = logging.getLogger(__name__)


class AnalyzeRequest(BaseModel):
    image_base64: str
    scan_type: str          # "oral" | "skin" | "other"
    symptoms: Optional[dict] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


@router.post("/analyze")
async def analyze(req: AnalyzeRequest):
    """
    Analyze an image and return risk level with 4-language explanation.

    Response:
    {
        "risk_level": "LOW_RISK" | "HIGH_RISK" | "INVALID",
        "confidence": 0.0-1.0,
        "explanation": {"en": "...", "hi": "...", "ta": "...", "te": "..."},
        "nearest_centers": [],
        "disclaimer": {"en": "...", "hi": "...", "ta": "...", "te": "..."}
    }
    """
    # Validate scan type
    scan_type = req.scan_type if req.scan_type in ("oral", "skin") else "oral"

    # Decode image
    try:
        image_bytes = base64.b64decode(req.image_base64)
        if len(image_bytes) < 100:
            return _error_response("Image data is too small or invalid.")
    except Exception:
        return _error_response("Invalid base64 image data.")

    # TFLite on-server inference
    risk_level, confidence = run_inference(image_bytes, scan_type)

    # Gemini holistic analysis (image + model result + symptoms)
    explanation = await analyze_image_with_gemini(
        image_bytes=image_bytes,
        risk_level=risk_level,
        confidence=confidence,
        scan_type=scan_type,
        symptoms=req.symptoms,
    )

    # Build 4-language explanation dict
    explanation_dict = {
        "en": explanation.get("en", ""),
        "hi": explanation.get("hi", ""),
        "ta": explanation.get("ta", ""),
        "te": explanation.get("te", ""),
    }

    # Nearest centers (requires lat/lng — return empty if not provided)
    nearest_centers = []
    if req.latitude and req.longitude:
        try:
            from services.maps_service import find_nearest_cancer_center
            nearest_centers = await find_nearest_cancer_center(
                req.latitude, req.longitude
            )
        except Exception as exc:
            logger.warning("Maps lookup failed: %s", exc)

    return {
        "risk_level": risk_level,
        "confidence": round(confidence, 4),
        "explanation": explanation_dict,
        "nearest_centers": nearest_centers,
        "disclaimer": DISCLAIMER,
    }


@router.get("/symptoms/{scan_type}")
def get_symptom_questions(scan_type: str):
    """Return the bilingual symptom questionnaire for a given scan type."""
    if scan_type not in ("oral", "skin"):
        raise HTTPException(400, "scan_type must be 'oral' or 'skin'")
    return {"questions": SYMPTOM_QUESTIONS[scan_type]}


def _error_response(message: str) -> dict:
    """Return a safe error response that never crashes the app."""
    return {
        "risk_level": "INVALID",
        "confidence": 0.0,
        "explanation": {
            "en": f"Analysis failed: {message} Please retake the photo and try again.",
            "hi": f"जांच विफल: {message} कृपया फोटो दोबारा लें।",
            "ta": f"பகுப்பாய்வு தோல்வியடைந்தது: {message} மீண்டும் புகைப்படம் எடுக்கவும்.",
            "te": f"విశ్లేషణ విఫలమైంది: {message} దయచేసి ఫోటో తిరిగి తీయండి.",
        },
        "nearest_centers": [],
        "disclaimer": DISCLAIMER,
    }
