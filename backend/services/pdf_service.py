"""
PDF report generator for JanArogya screening results.
Single-page A4 portrait layout with multi-language font support.
Fonts: Noto Sans (EN), Noto Sans Devanagari (HI), Noto Sans Tamil (TA), Noto Sans Telugu (TE).
"""
import base64
import io
import logging
import os
import urllib.request
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

logger = logging.getLogger(__name__)

# ── Page geometry ─────────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4          # 595.27 × 841.89 pt
MARGIN = 42.5                # ~15mm
CONTENT_W = PAGE_W - 2 * MARGIN

# ── Palette ───────────────────────────────────────────────────────────────────
C_NAVY     = colors.HexColor("#1E3A5F")
C_WHITE    = colors.white
C_BLACK    = colors.black
C_GRAY     = colors.HexColor("#616161")
C_LGRAY    = colors.HexColor("#F5F5F5")
C_YELLOW   = colors.HexColor("#FFF8E1")
C_YAMBER   = colors.HexColor("#F9A825")

RISK_COLORS = {
    "HIGH_RISK":  (colors.HexColor("#DC2626"), colors.HexColor("#FEE2E2")),  # border, bg
    "LOW_RISK":   (colors.HexColor("#059669"), colors.HexColor("#D1FAE5")),
    "INVALID":    (colors.HexColor("#D97706"), colors.HexColor("#FEF3C7")),
}
RISK_TEXT_COLORS = {
    "HIGH_RISK":  colors.HexColor("#DC2626"),
    "LOW_RISK":   colors.HexColor("#059669"),
    "INVALID":    colors.HexColor("#D97706"),
}
RISK_LABELS = {
    "HIGH_RISK": "HIGH RISK",
    "LOW_RISK":  "LOW RISK",
    "INVALID":   "INVALID",
}

# ── Font setup ────────────────────────────────────────────────────────────────
ASSETS_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "assets"))

FONTS = {
    "hi": {
        "name": "NotoDevanagari",
        "path": os.path.join(ASSETS_DIR, "NotoSansDevanagari.ttf"),
        "url":  "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansDevanagari/NotoSansDevanagari-Regular.ttf",
    },
    "ta": {
        "name": "NotoTamil",
        "path": os.path.join(ASSETS_DIR, "NotoSansTamil.ttf"),
        "url":  "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansTamil/NotoSansTamil-Regular.ttf",
    },
    "te": {
        "name": "NotoTelugu",
        "path": os.path.join(ASSETS_DIR, "NotoSansTelugu.ttf"),
        "url":  "https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansTelugu/NotoSansTelugu-Regular.ttf",
    },
}

_font_ready: dict[str, bool] = {}


def _setup_font(lang: str) -> bool:
    """Download and register a font. Returns True if ready."""
    if lang in _font_ready:
        return _font_ready[lang]
    if lang not in FONTS:
        return True  # English uses built-in Helvetica

    info = FONTS[lang]
    os.makedirs(ASSETS_DIR, exist_ok=True)

    if not os.path.exists(info["path"]):
        try:
            logger.info("Downloading font for lang=%s …", lang)
            urllib.request.urlretrieve(info["url"], info["path"])
            logger.info("Font saved: %s", info["path"])
        except Exception as exc:
            logger.warning("Font download failed for %s: %s — using fallback", lang, exc)
            _font_ready[lang] = False
            return False

    try:
        pdfmetrics.registerFont(TTFont(info["name"], info["path"]))
        _font_ready[lang] = True
        logger.info("Font registered: %s", info["name"])
    except Exception as exc:
        logger.warning("Font registration failed for %s: %s", lang, exc)
        _font_ready[lang] = False

    return _font_ready[lang]


def _get_font(lang: str) -> str:
    """Return the registered font name for a language."""
    if lang in FONTS and _setup_font(lang):
        return FONTS[lang]["name"]
    return "Helvetica"


# ── Text helpers ──────────────────────────────────────────────────────────────

def _wrap(c: canvas.Canvas, text: str, max_w: float, font: str, size: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    cur: list[str] = []
    cur_w = 0.0
    for word in words:
        w = c.stringWidth(word, font, size)
        gap = c.stringWidth(" ", font, size) if cur else 0.0
        if cur and cur_w + gap + w > max_w:
            lines.append(" ".join(cur))
            cur, cur_w = [word], w
        else:
            cur.append(word)
            cur_w += gap + w
    if cur:
        lines.append(" ".join(cur))
    return lines or [""]


def _text_block(c: canvas.Canvas, text: str, x: float, y: float,
                max_w: float, font: str, size: float,
                leading: float = 14.0, color=colors.black) -> float:
    """Draw word-wrapped text, return y below last line."""
    if not text:
        return y
    c.setFillColor(color)
    c.setFont(font, size)
    for line in _wrap(c, text, max_w, font, size):
        c.drawString(x, y, line)
        y -= leading
    return y


def _text_height(c: canvas.Canvas, text: str, max_w: float,
                 font: str, size: float, leading: float = 14.0) -> float:
    if not text:
        return 0.0
    return len(_wrap(c, text, max_w, font, size)) * leading


# ── Main generator ────────────────────────────────────────────────────────────

def generate_report(data: dict) -> bytes:
    """
    Build a single-patient A4 screening report. Returns PDF bytes.

    Expected keys in data:
        report_id, user_name, phone_masked, scan_date, scan_time,
        scan_type, risk_level, confidence, explanation_en,
        explanation_local, local_language, concern,
        questions_and_answers (list of {question, answer}),
        image_bytes (bytes|None), nearest_centres (list of dicts)
    """
    # ── Setup fonts ────────────────────────────────────────────────────────────
    for lang in ("hi", "ta", "te"):
        _setup_font(lang)

    # ── Extract data ───────────────────────────────────────────────────────────
    report_id   = data.get("report_id", "CS-XXXXXXXX")
    user_name   = data.get("user_name", "Anonymous") or "Anonymous"
    phone       = data.get("phone_masked", "XXXXXXXXXX") or "XXXXXXXXXX"
    scan_date   = data.get("scan_date", datetime.now().strftime("%d/%m/%Y"))
    scan_time   = data.get("scan_time", datetime.now().strftime("%I:%M %p"))
    scan_type   = (data.get("scan_type") or "oral").title()
    risk_level  = data.get("risk_level", "INVALID")
    confidence  = float(data.get("confidence", 0.0))
    exp_en      = data.get("explanation_en", "")
    exp_local   = data.get("explanation_local", "")
    local_lang  = data.get("local_language", "en")
    concern     = data.get("concern", "")
    qas         = data.get("questions_and_answers", [])
    img_bytes   = data.get("image_bytes")
    centres     = data.get("nearest_centres", []) or []

    risk_border, risk_bg = RISK_COLORS.get(risk_level, RISK_COLORS["INVALID"])
    risk_text   = RISK_TEXT_COLORS.get(risk_level, C_GRAY)
    risk_label  = RISK_LABELS.get(risk_level, risk_level)
    local_font  = _get_font(local_lang)

    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    c.setTitle(f"JanArogya Screening Report — {report_id}")

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 1 — HEADER
    # ══════════════════════════════════════════════════════════════════════════
    HDR_H = 70.0
    c.setFillColor(C_NAVY)
    c.rect(0, PAGE_H - HDR_H, PAGE_W, HDR_H, fill=1, stroke=0)

    # Left: App name
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 22)
    c.drawString(MARGIN, PAGE_H - 26, "JanArogya")
    c.setFont("Helvetica", 10)
    c.drawString(MARGIN, PAGE_H - 41, "\u091C\u0928\u0906\u0930\u094B\u0917\u094D\u092F")  # जनआरोग्य
    c.setFont("Helvetica-Oblique", 8)
    c.drawString(MARGIN, PAGE_H - 55, "AI-Powered Cancer Screening")

    # Right: Report metadata
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 22, f"Report ID: {report_id}")
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 34, f"Scan Date: {scan_date}")
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 46, f"Scan Time: {scan_time}")
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 58, f"Scan Type: {scan_type}")

    # Divider
    y = PAGE_H - HDR_H - 4
    c.setStrokeColor(colors.HexColor("#E5E7EB"))
    c.setLineWidth(0.5)
    c.line(MARGIN, y, PAGE_W - MARGIN, y)
    y -= 8

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 2 — DISCLAIMER BOX
    # ══════════════════════════════════════════════════════════════════════════
    disc_text = (
        "IMPORTANT: This report is generated by an AI screening tool and is NOT a medical diagnosis. "
        "Always consult a qualified doctor before making any health decisions."
    )
    disc_font  = "Helvetica-Oblique"
    disc_size  = 7.5
    disc_lines = _wrap(c, disc_text, CONTENT_W - 24, disc_font, disc_size)
    disc_h     = len(disc_lines) * 11 + 14

    c.setFillColor(C_YELLOW)
    c.setStrokeColor(C_YAMBER)
    c.setLineWidth(1.0)
    c.roundRect(MARGIN, y - disc_h, CONTENT_W, disc_h, 4, fill=1, stroke=1)

    c.setFillColor(colors.HexColor("#92400E"))
    c.setFont("Helvetica-Bold", 8)
    c.drawString(MARGIN + 8, y - 10, "⚠  IMPORTANT DISCLAIMER")
    ty = y - 21
    c.setFont(disc_font, disc_size)
    for line in disc_lines:
        c.drawString(MARGIN + 8, ty, line)
        ty -= 11
    y = y - disc_h - 8

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 3 — TWO COLUMN LAYOUT
    # ══════════════════════════════════════════════════════════════════════════
    COL_L_W  = CONTENT_W * 0.60
    COL_R_W  = CONTENT_W * 0.40 - 8
    COL_R_X  = MARGIN + COL_L_W + 8
    col_y_l  = y
    col_y_r  = y

    # ── LEFT COLUMN ────────────────────────────────────────────────────────────

    # User Details box
    detail_lines = [
        f"Name:      {user_name}",
        f"Phone:     {phone}",
        f"Language:  {local_lang.upper()}",
        f"Generated: {scan_date} {scan_time}",
    ]
    box_h = len(detail_lines) * 13 + 16
    c.setFillColor(C_LGRAY)
    c.setStrokeColor(colors.HexColor("#E5E7EB"))
    c.setLineWidth(0.5)
    c.roundRect(MARGIN, col_y_l - box_h, COL_L_W, box_h, 4, fill=1, stroke=1)

    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(C_NAVY)
    c.drawString(MARGIN + 6, col_y_l - 10, "PATIENT DETAILS")
    ty = col_y_l - 22
    c.setFont("Helvetica", 8)
    c.setFillColor(C_BLACK)
    for line in detail_lines:
        c.drawString(MARGIN + 6, ty, line)
        ty -= 13
    col_y_l = col_y_l - box_h - 8

    # Risk Assessment box
    conf_pct = f"{confidence * 100:.1f}%"
    risk_box_h = 62.0
    c.setFillColor(risk_bg)
    c.setStrokeColor(risk_border)
    c.setLineWidth(2.0)
    c.roundRect(MARGIN, col_y_l - risk_box_h, COL_L_W, risk_box_h, 4, fill=1, stroke=1)

    c.setFillColor(risk_text)
    c.setFont("Helvetica-Bold", 18)
    c.drawString(MARGIN + 10, col_y_l - 24, risk_label)
    c.setFont("Helvetica", 9)
    c.drawString(MARGIN + 10, col_y_l - 38, f"Confidence: {conf_pct}")

    # Confidence progress bar
    bar_x   = MARGIN + 10
    bar_y   = col_y_l - 52
    bar_w   = COL_L_W - 20
    bar_h   = 6.0
    c.setFillColor(colors.HexColor("#E5E7EB"))
    c.roundRect(bar_x, bar_y, bar_w, bar_h, 3, fill=1, stroke=0)
    fill_w = bar_w * confidence
    if fill_w > 0:
        c.setFillColor(risk_text)
        c.roundRect(bar_x, bar_y, fill_w, bar_h, 3, fill=1, stroke=0)

    col_y_l = col_y_l - risk_box_h - 8

    # AI Explanation
    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(C_NAVY)
    c.drawString(MARGIN, col_y_l, "AI EXPLANATION")
    col_y_l -= 4
    c.setStrokeColor(C_NAVY)
    c.setLineWidth(0.5)
    c.line(MARGIN, col_y_l, MARGIN + COL_L_W, col_y_l)
    col_y_l -= 11

    if exp_en:
        col_y_l = _text_block(c, exp_en, MARGIN, col_y_l, COL_L_W,
                              "Helvetica", 8, leading=12)
        col_y_l -= 4

    if exp_local and local_lang != "en" and local_font != "Helvetica":
        col_y_l = _text_block(c, exp_local, MARGIN, col_y_l, COL_L_W,
                              local_font, 8, leading=12)
        col_y_l -= 4
    elif exp_local and local_lang == "hi":
        col_y_l = _text_block(c, exp_local, MARGIN, col_y_l, COL_L_W,
                              _get_font("hi"), 8, leading=12)
        col_y_l -= 4

    col_y_l -= 4

    # Concern box
    if concern:
        c.setFont("Helvetica-Bold", 8)
        c.setFillColor(C_NAVY)
        c.drawString(MARGIN, col_y_l, "WHAT THIS MEANS")
        col_y_l -= 4
        c.setStrokeColor(C_NAVY)
        c.setLineWidth(0.5)
        c.line(MARGIN, col_y_l, MARGIN + COL_L_W, col_y_l)
        col_y_l -= 11
        col_y_l = _text_block(c, concern, MARGIN, col_y_l, COL_L_W,
                              "Helvetica", 8, leading=12, color=C_GRAY)
        col_y_l -= 8

    # ── RIGHT COLUMN ───────────────────────────────────────────────────────────

    # Uploaded image
    img_display_h = 110.0
    if img_bytes:
        try:
            img_reader = ImageReader(io.BytesIO(img_bytes))
            img_y = col_y_r - img_display_h
            c.setStrokeColor(colors.HexColor("#E5E7EB"))
            c.setLineWidth(0.5)
            c.roundRect(COL_R_X, img_y, COL_R_W, img_display_h, 4, fill=0, stroke=1)
            c.drawImage(img_reader, COL_R_X + 2, img_y + 2,
                       COL_R_W - 4, img_display_h - 4,
                       preserveAspectRatio=True, mask="auto")
            c.setFont("Helvetica", 7)
            c.setFillColor(C_GRAY)
            c.drawCentredString(COL_R_X + COL_R_W / 2, img_y - 8, "Uploaded Image")
            col_y_r = img_y - 16
        except Exception as exc:
            logger.warning("Could not embed image: %s", exc)
            col_y_r -= 10
    else:
        col_y_r -= 10

    # Q&A
    if qas:
        c.setFont("Helvetica-Bold", 8)
        c.setFillColor(C_NAVY)
        c.drawString(COL_R_X, col_y_r, "PATIENT RESPONSES")
        col_y_r -= 4
        c.setStrokeColor(C_NAVY)
        c.setLineWidth(0.5)
        c.line(COL_R_X, col_y_r, COL_R_X + COL_R_W, col_y_r)
        col_y_r -= 10

        for qa in qas[:4]:
            q_text = f"Q: {qa.get('question', '')}"
            a_text = f"A: {qa.get('answer', '')}"
            c.setFont("Helvetica-Bold", 7.5)
            c.setFillColor(C_BLACK)
            col_y_r = _text_block(c, q_text, COL_R_X, col_y_r, COL_R_W,
                                  "Helvetica-Bold", 7.5, leading=10)
            c.setFont("Helvetica", 7.5)
            c.setFillColor(C_GRAY)
            col_y_r = _text_block(c, a_text, COL_R_X, col_y_r, COL_R_W,
                                  "Helvetica", 7.5, leading=10)
            col_y_r -= 4

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 4 — NEAREST CENTRES
    # ══════════════════════════════════════════════════════════════════════════
    section_y = min(col_y_l, col_y_r) - 12
    if section_y < MARGIN + 80:
        section_y = MARGIN + 80  # Guard against overflow

    if centres:
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(C_NAVY)
        c.drawString(MARGIN, section_y, "NEAREST SCREENING CENTRES")
        section_y -= 4
        c.setStrokeColor(C_NAVY)
        c.setLineWidth(0.5)
        c.line(MARGIN, section_y, PAGE_W - MARGIN, section_y)
        section_y -= 10

        centre_w = (CONTENT_W - 8) / 2
        cx = [MARGIN, MARGIN + centre_w + 8]

        for i, ctr in enumerate(centres[:2]):
            bx = cx[i]
            by = section_y
            bh = 52.0
            c.setFillColor(C_LGRAY)
            c.setStrokeColor(colors.HexColor("#E5E7EB"))
            c.setLineWidth(0.5)
            c.roundRect(bx, by - bh, centre_w, bh, 4, fill=1, stroke=1)

            c.setFont("Helvetica-Bold", 8)
            c.setFillColor(C_NAVY)
            name = (ctr.get("name") or "")[:35]
            c.drawString(bx + 6, by - 12, name)

            addr = (ctr.get("address") or "")[:45]
            c.setFont("Helvetica", 7.5)
            c.setFillColor(C_GRAY)
            c.drawString(bx + 6, by - 23, addr)

            dist = ctr.get("distance_km")
            if dist is not None:
                c.drawString(bx + 6, by - 34, f"Distance: {dist:.1f} km")

            phone = ctr.get("phone")
            if phone:
                c.drawString(bx + 6, by - 45, f"Phone: {phone}")

        section_y = section_y - 52 - 8

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 5 — FOOTER
    # ══════════════════════════════════════════════════════════════════════════
    FOOTER_H = 38.0
    c.setFillColor(C_LGRAY)
    c.rect(0, 0, PAGE_W, FOOTER_H, fill=1, stroke=0)
    c.setStrokeColor(colors.HexColor("#E5E7EB"))
    c.setLineWidth(0.5)
    c.line(0, FOOTER_H, PAGE_W, FOOTER_H)

    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(colors.HexColor("#DC2626"))
    c.drawString(MARGIN, FOOTER_H - 12, "Cancer Helpline: 1800-11-2345  (Toll-Free, 24/7)")

    c.setFont("Helvetica-Oblique", 7.5)
    c.setFillColor(C_GRAY)
    c.drawCentredString(PAGE_W / 2, FOOTER_H - 12,
                        "Consult a real doctor before taking any action")

    c.setFont("Helvetica", 7)
    c.setFillColor(C_GRAY)
    c.drawRightString(PAGE_W - MARGIN, FOOTER_H - 12,
                      "Generated by JanArogya | janarogya.health")

    c.setFont("Helvetica", 6.5)
    c.drawCentredString(PAGE_W / 2, FOOTER_H - 26,
                        "This report is for screening purposes only — not a clinical diagnosis")

    c.save()
    return buf.getvalue()
