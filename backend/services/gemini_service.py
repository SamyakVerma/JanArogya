"""Google Gemini AI integration — returns 4-language analysis."""
import json
import logging
import os
import re

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

logger = logging.getLogger(__name__)

_API_KEY = os.getenv("GEMINI_API_KEY", "")
if not _API_KEY:
    logger.warning("GEMINI_API_KEY is not set — Gemini calls will fail")
_client = genai.Client(api_key=_API_KEY)
_MODEL = "gemini-2.5-flash"

# ── Symptom questions ──────────────────────────────────────────────────────────

SYMPTOM_QUESTIONS = {
    "oral": [
        {
            "id": "duration",
            "hi": "यह समस्या कितने दिनों से है?",
            "en": "How many days have you had this problem?",
            "ta": "இந்தப் பிரச்சனை எத்தனை நாட்களாக உள்ளது?",
            "te": "ఈ సమస్య ఎన్ని రోజులనుండి ఉంది?",
            "options_hi": ["1-7 दिन", "1-4 हफ्ते", "1 महीने से ज्यादा"],
            "options_en": ["1-7 days", "1-4 weeks", "More than 1 month"],
        },
        {
            "id": "pain",
            "hi": "क्या मुँह में दर्द या जलन है?",
            "en": "Is there pain or burning sensation in the mouth?",
            "ta": "வாயில் வலி அல்லது எரிச்சல் உள்ளதா?",
            "te": "నోటిలో నొప్పి లేదా మంట ఉందా?",
            "options_hi": ["हाँ, बहुत", "थोड़ा", "नहीं"],
            "options_en": ["Yes, severe", "Mild", "No"],
        },
        {
            "id": "patches",
            "hi": "क्या सफेद, लाल, या काले धब्बे दिखते हैं?",
            "en": "Do you see white, red, or dark patches?",
            "ta": "வெள்ளை, சிவப்பு அல்லது கருப்பு திட்டுகள் தெரிகின்றனவா?",
            "te": "తెలుపు, ఎరుపు లేదా చీకటి మచ్చలు కనిపిస్తున్నాయా?",
            "options_hi": ["सफेद धब्बे", "लाल धब्बे", "दोनों", "कोई नहीं"],
            "options_en": ["White patches", "Red patches", "Both", "None"],
        },
    ],
    "skin": [
        {
            "id": "duration",
            "hi": "यह घाव/धब्बा कितने दिनों से है?",
            "en": "How long have you had this wound or spot?",
            "ta": "இந்த புண் அல்லது திட்டு எத்தனை நாட்களாக உள்ளது?",
            "te": "ఈ గాయం లేదా మచ్చ ఎంత కాలం నుండి ఉంది?",
            "options_hi": ["1-7 दिन", "1-4 हफ्ते", "1 महीने से ज्यादा"],
            "options_en": ["1-7 days", "1-4 weeks", "More than 1 month"],
        },
        {
            "id": "pain",
            "hi": "क्या इसमें दर्द, खुजली, या जलन है?",
            "en": "Is there pain, itching, or burning?",
            "ta": "வலி, அரிப்பு அல்லது எரிச்சல் உள்ளதா?",
            "te": "నొప్పి, దురద లేదా మంట ఉందా?",
            "options_hi": ["हाँ, बहुत", "थोड़ा", "नहीं"],
            "options_en": ["Yes, severe", "Mild", "No"],
        },
        {
            "id": "change",
            "hi": "क्या यह बढ़ रहा है या रंग बदल रहा है?",
            "en": "Is it growing in size or changing color?",
            "ta": "இது பெரிதாகுகிறதா அல்லது நிறம் மாறுகிறதா?",
            "te": "ఇది పెద్దదవుతుందా లేదా రంగు మారుతుందా?",
            "options_hi": ["हाँ, बढ़ रहा है", "रंग बदल रहा है", "दोनों", "नहीं"],
            "options_en": ["Yes, growing", "Color changing", "Both", "No change"],
        },
    ],
}

# ── Prompts ────────────────────────────────────────────────────────────────────

_QUESTIONS_PROMPT = """\
You are a medical AI screening assistant. Look at this {scan_type} scan image carefully.
Generate exactly 3 short, clear screening questions to ask this patient about their symptoms.
These must be specific to what you observe in THIS image.

Respond ONLY in this exact JSON format (no markdown):
{{
    "questions": [
        {{
            "id": "q1",
            "en": "English question?",
            "hi": "Hindi question?",
            "ta": "Tamil question?",
            "te": "Telugu question?",
            "options_en": ["Option A", "Option B", "Option C"],
            "options_hi": ["विकल्प A", "विकल्प B", "विकल्प C"],
            "options_ta": ["விருப்பம் A", "விருப்பம் B", "விருப்பம் C"],
            "options_te": ["ఎంపిక A", "ఎంపిక B", "ఎంపిక C"]
        }},
        {{ "id": "q2", ... }},
        {{ "id": "q3", ... }}
    ]
}}

Rules:
- Questions must be specific to what you observe in this image
- Each question must have exactly 3 options
- Options must be translations of each other
- Never mention cancer, tumor, or malignant
- Keep questions simple enough for rural patients
"""

_CHAT_SYSTEM = """\
You are JanArogya Health Assistant, a compassionate AI health guide for rural India.
You help people understand general health topics, symptoms, and when to seek care.
Rules:
- Never diagnose disease
- Never mention cancer, tumor, malignant directly — use "concerning growths" or "abnormal tissue"
- Always recommend seeing a real doctor for serious concerns
- Be warm, simple, and accessible — your users may have low health literacy
- Respond in {language} only
- Keep responses concise (max 4 sentences unless a list is clearly better)
- For emergency symptoms (chest pain, difficulty breathing, heavy bleeding) always say "call emergency services immediately"
"""

_QUALITY_PROMPT = (
    "Is this a clear photo suitable for medical screening? "
    "Look for: blur, poor lighting, wrong angle, not showing "
    "mouth/skin properly. Reply only: GOOD or BAD: [reason]"
)

_ANALYSIS_PROMPT = """\
You are a compassionate health guide helping a rural Indian understand their screening result.
Write like you are talking to a friend who has NO medical education. Use simple, everyday words.

INPUTS:
- Scan type: {scan_type} scan
- AI risk assessment: {risk_level} ({confidence}% confidence)
- What the patient told us:
{symptoms_text}

YOUR TASK: Write a kind, plain-language explanation of what the photo shows and what it means.

Respond ONLY in this exact JSON (no markdown, no extra text):
{{
    "en": "2-3 sentences in plain English. Start with 'Your photo shows...' or 'The area in your photo...'. Mention what the AI noticed, connect it to what they told us, and say one clear thing they should do. No medical words.",
    "hi": "2-3 सरल वाक्य हिंदी में। शुरुआत करें 'आपकी तस्वीर में...' से। बिल्कुल आसान भाषा, कोई मेडिकल शब्द नहीं। क्या दिखा और क्या करना चाहिए बताएं।",
    "ta": "2-3 எளிய தமிழ் வாக்கியங்கள். 'உங்கள் படத்தில்...' என தொடங்கவும். எளிய வார்த்தைகளில் என்ன தெரிந்தது மற்றும் என்ன செய்ய வேண்டும் என்று சொல்லவும்.",
    "te": "2-3 సరళమైన తెలుగు వాక్యాలు. 'మీ ఫోటోలో...' తో ప్రారంభించండి. వైద్య పరిభాష లేకుండా ఏమి కనుగొన్నారు మరియు ఏమి చేయాలో చెప్పండి.",
    "concern": "One plain-English sentence: the single most important thing this person should do now. Practical and calm. Example: 'Visit your local health centre in the next few days and show them this photo.'",
    "action_required": true
}}

Rules:
- NEVER say: cancer, tumor, malignant, lesion, biopsy, pathology, oncology, carcinoma
- Use words like: area, spot, patch, mark, change, tissue
- LOW_RISK: reassure, say it looks normal but advise monitoring — "Keep an eye on it and see a doctor if it changes"
- HIGH_RISK: urge doctor visit calmly — "We recommend seeing a doctor soon, within the next 1-2 days"
- INVALID: explain the photo quality issue simply — "The photo was not clear enough for a proper check"
- Reference their symptom answers naturally: "Since you mentioned it has been there for X weeks..."
- action_required: true if HIGH_RISK or symptoms show long duration or severe pain
"""

# ── Fallbacks ──────────────────────────────────────────────────────────────────

_FALLBACK = {
    "en": "Your image has been reviewed. Some areas need attention. Please consult a qualified doctor for proper evaluation.",
    "hi": "आपकी तस्वीर देखी गई है। कुछ क्षेत्रों पर ध्यान देने की जरूरत है। कृपया एक योग्य डॉक्टर से मिलें।",
    "ta": "உங்கள் படம் பரிசீலிக்கப்பட்டது. சில பகுதிகளுக்கு கவனம் தேவை. தகுதியான மருத்துவரை அணுகவும்.",
    "te": "మీ చిత్రం సమీక్షించబడింది. కొన్ని ప్రాంతాలకు శ్రద్ధ అవసరం. అర్హత గల వైద్యుడిని సంప్రదించండి.",
    "action_required": True,
}

_ERROR = {
    "en": "Screening encountered an issue. Please consult a doctor.",
    "hi": "जांच में समस्या हुई। कृपया डॉक्टर से सलाह लें।",
    "ta": "திரையிடலில் சிக்கல் ஏற்பட்டது. மருத்துவரை அணுகவும்.",
    "te": "స్క్రీనింగ్‌లో సమస్య వచ్చింది. వైద్యుడిని సంప్రదించండి.",
    "action_required": True,
}

DISCLAIMER = {
    "en": "This is an AI screening tool, not a medical diagnosis. Please consult a qualified doctor.",
    "hi": "यह एक AI स्क्रीनिंग टूल है, कोई डॉक्टरी निदान नहीं। कृपया किसी योग्य डॉक्टर से मिलें।",
    "ta": "இது ஒரு AI திரையிடல் கருவி, மருத்துவ நோயறிதல் அல்ல. தயவுசெய்து ஒரு தகுதிவாய்ந்த மருத்துவரை அணுகவும்.",
    "te": "ఇది ఒక AI స్క్రీనింగ్ సాధనం, వైద్య నిర్ధారణ కాదు. దయచేసి అర్హత గల వైద్యుడిని సంప్రదించండి.",
}


# ── Helpers ────────────────────────────────────────────────────────────────────

def _extract_json(text: str) -> dict:
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if match:
        return json.loads(match.group(1))
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        return json.loads(match.group(0))
    raise ValueError(f"No JSON in Gemini response: {text!r}")


def _format_symptoms(symptoms: dict | None, scan_type: str) -> str:
    if not symptoms:
        return "  No symptom information provided."
    lines = []
    for question, answer in symptoms.items():
        if question and answer:
            lines.append(f"  - {question}: {answer}")
    return "\n".join(lines) if lines else "  No symptom information provided."


# ── Public API ─────────────────────────────────────────────────────────────────

async def check_image_quality(image_bytes: bytes) -> dict:
    """Returns {"quality": "GOOD"} or {"quality": "BAD", "reason": "..."}."""
    image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL,
            contents=[_QUALITY_PROMPT, image_part],
        )
        text = response.text.strip()
        if text.upper().startswith("GOOD"):
            return {"quality": "GOOD"}
        reason = text.split(":", 1)[1].strip() if ":" in text else text
        return {"quality": "BAD", "reason": reason}
    except Exception as exc:
        logger.error("Gemini quality check error: %s — failing open", exc)
        return {"quality": "GOOD"}


async def analyze_image_with_gemini(
    image_bytes: bytes,
    risk_level: str,
    confidence: float,
    scan_type: str = "oral",
    symptoms: dict | None = None,
) -> dict:
    """Returns dict with keys: en, hi, ta, te, action_required."""
    symptoms_text = _format_symptoms(symptoms, scan_type)
    prompt = _ANALYSIS_PROMPT.format(
        scan_type=scan_type,
        risk_level=risk_level,
        confidence=round(confidence * 100),
        symptoms_text=symptoms_text,
    )
    image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL,
            contents=[prompt, image_part],
        )
        result = _extract_json(response.text)
        # Validate required keys
        for lang in ("en", "hi", "ta", "te"):
            if lang not in result or not result[lang]:
                result[lang] = _FALLBACK[lang]
        if "action_required" not in result:
            result["action_required"] = risk_level == "HIGH_RISK"
        if "concern" not in result or not result["concern"]:
            result["concern"] = (
                "Please visit a doctor soon." if risk_level == "HIGH_RISK"
                else "Monitor the area and see a doctor if anything changes."
            )
        logger.info("Gemini analysis: scan=%s risk=%s concern=%s",
                    scan_type, risk_level, result["concern"][:60])
        return result
    except (json.JSONDecodeError, ValueError) as exc:
        logger.warning("Gemini JSON parse failed (%s) — using fallback", exc)
        return _FALLBACK.copy()
    except Exception as exc:
        logger.error("Gemini API error: %s", exc)
        return _ERROR.copy()


async def generate_questions_for_image(
    image_bytes: bytes,
    scan_type: str = "oral",
) -> list[dict]:
    """Use Gemini vision to generate contextual symptom questions from the image.
    Returns list of question dicts with id, en/hi/ta/te text, and options."""
    prompt = _QUESTIONS_PROMPT.format(scan_type=scan_type)
    image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL,
            contents=[prompt, image_part],
        )
        data = _extract_json(response.text)
        questions = data.get("questions", [])
        if questions and len(questions) >= 2:
            logger.info("Gemini generated %d questions for %s scan", len(questions), scan_type)
            return questions
    except Exception as exc:
        logger.warning("Gemini question generation failed (%s) — using static fallback", exc)

    # Fallback to static questions if Gemini fails
    return SYMPTOM_QUESTIONS.get(scan_type, SYMPTOM_QUESTIONS["oral"])


async def chat_health(
    message: str,
    history: list[dict],
    language: str = "en",
) -> dict:
    """General health chat using Gemini. Returns {response, suggestions}.
    history: list of {role: 'user'|'assistant', content: str}
    """
    lang_names = {"en": "English", "hi": "Hindi", "ta": "Tamil", "te": "Telugu"}
    lang_name  = lang_names.get(language, "English")
    system     = _CHAT_SYSTEM.format(language=lang_name)

    # Build conversation for Gemini
    contents: list = [system]
    for turn in history[-10:]:  # last 10 turns max
        role    = turn.get("role", "user")
        content = turn.get("content", "")
        prefix  = "Patient: " if role == "user" else "Assistant: "
        contents.append(prefix + content)
    contents.append(f"Patient: {message}")
    contents.append("Assistant:")

    try:
        response = await _client.aio.models.generate_content(
            model=_MODEL,
            contents=contents,
        )
        reply = response.text.strip()
        # Remove leading "Assistant:" if Gemini echoes it
        if reply.startswith("Assistant:"):
            reply = reply[len("Assistant:"):].strip()
        logger.info("Health chat: lang=%s tokens~=%d", language, len(reply.split()))
        return {"response": reply, "error": None}
    except Exception as exc:
        logger.error("Health chat error: %s", exc)
        fallback = {
            "en": "I'm having trouble responding right now. Please try again.",
            "hi": "मुझे अभी जवाब देने में परेशानी हो रही है। कृपया दोबारा कोशिश करें।",
            "ta": "எனக்கு இப்போது பதிலளிக்க சிக்கல் உள்ளது. மீண்டும் முயற்சிக்கவும்.",
            "te": "నాకు ఇప్పుడు సమాధానం ఇవ్వడంలో సమస్య ఉంది. దయచేసి మళ్ళీ ప్రయత్నించండి.",
        }
        return {"response": fallback.get(language, fallback["en"]), "error": str(exc)}
