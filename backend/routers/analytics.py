"""Analytics endpoints — trends, accuracy, geography, export."""
import csv
import io
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse

from middleware.auth import get_current_user, require_role
from services.scan_store import _scans

router = APIRouter(prefix="/analytics", tags=["analytics"])
logger = logging.getLogger(__name__)


def _get_week_label(dt: datetime) -> str:
    """Return 'YYYY-WNN' string for the ISO week containing dt."""
    iso = dt.isocalendar()
    return f"{iso[0]}-W{iso[1]:02d}"


@router.get("/trends")
def trends(user: dict = Depends(get_current_user)):
    """Return scan trends by week for the last 12 weeks."""
    now = datetime.now(timezone.utc)
    week_data: dict[str, dict] = {}

    for i in range(11, -1, -1):
        week_start = now - timedelta(weeks=i)
        label = _get_week_label(week_start)
        if label not in week_data:
            week_data[label] = {"week": label, "count": 0, "high_risk": 0, "low_risk": 0}

    for s in _scans:
        if s.get("deleted"):
            continue
        try:
            dt = datetime.fromisoformat(s["created_at"].replace("Z", "+00:00"))
        except Exception:
            continue
        if dt < now - timedelta(weeks=12):
            continue
        label = _get_week_label(dt)
        if label not in week_data:
            continue
        week_data[label]["count"] += 1
        if s.get("risk_level") == "HIGH_RISK":
            week_data[label]["high_risk"] += 1
        elif s.get("risk_level") == "LOW_RISK":
            week_data[label]["low_risk"] += 1

    return {"weeks": list(week_data.values()), "period": "last_12_weeks"}


@router.get("/accuracy")
def accuracy(user: dict = Depends(get_current_user)):
    """Return model performance metrics (mock values)."""
    return {
        "oral_accuracy": 0.923,
        "oral_precision": 0.918,
        "oral_recall": 0.931,
        "oral_f1": 0.924,
        "skin_accuracy": 0.887,
        "skin_precision": 0.879,
        "skin_recall": 0.896,
        "skin_f1": 0.887,
        "overall": 0.905,
        "dataset_size": 12480,
        "last_trained": "2024-11-15",
        "model_version": "1.0.0",
    }


@router.get("/geography")
def geography(user: dict = Depends(get_current_user)):
    """Return state and city breakdown of scans."""
    state_counts: dict[str, int] = {}
    city_counts: dict[str, int] = {}

    for s in _scans:
        if s.get("deleted"):
            continue
        state = s.get("state", "Unknown")
        city = s.get("city", "Unknown")
        state_counts[state] = state_counts.get(state, 0) + 1
        city_counts[city] = city_counts.get(city, 0) + 1

    states = sorted(
        [{"state": k, "count": v} for k, v in state_counts.items()],
        key=lambda x: x["count"],
        reverse=True,
    )
    cities = sorted(
        [{"city": k, "count": v} for k, v in city_counts.items()],
        key=lambda x: x["count"],
        reverse=True,
    )[:20]

    return {"states": states, "cities": cities}


@router.get("/export")
def export_csv(user: dict = Depends(require_role("admin"))):
    """Export all scans as CSV (admin only)."""
    active = [s for s in _scans if not s.get("deleted")]
    output = io.StringIO()
    fieldnames = [
        "id", "user_id", "scan_type", "risk_level", "confidence",
        "language", "city", "state", "lat", "lng", "created_at",
    ]
    writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(active)

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=janarogya_scans.csv"},
    )
