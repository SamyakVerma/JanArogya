"""On-server TFLite inference — used by WhatsApp pipeline and /api/v1/analyze."""
import io
import logging
import os

import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

# Models live alongside the Flutter assets — resolve from project root
_BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_MODEL_PATHS = {
    "oral": os.path.join(_BASE, "..", "app", "assets", "models", "janarogya_oral_f32.tflite"),
    "skin": os.path.join(_BASE, "..", "app", "assets", "models", "janarogya_skin_int8.tflite"),
}
_LABELS = ["LOW_RISK", "HIGH_RISK", "INVALID"]
_interpreters: dict = {}


def _get_interpreter(scan_type: str):
    if scan_type not in _interpreters:
        path = os.path.normpath(_MODEL_PATHS[scan_type])
        if not os.path.exists(path):
            raise FileNotFoundError(f"TFLite model not found: {path}")
        import tensorflow as tf
        interp = tf.lite.Interpreter(model_path=path)
        interp.allocate_tensors()
        _interpreters[scan_type] = interp
        logger.info("Loaded TFLite model: %s (%s)", scan_type, path)
    return _interpreters[scan_type]


def run_inference(image_bytes: bytes, scan_type: str) -> tuple[str, float]:
    """Run TFLite model on image bytes. Returns (risk_label, confidence).
    Fails safe → HIGH_RISK 0.60 so the pipeline never silently skips a real case."""
    try:
        interp = _get_interpreter(scan_type)
        input_details  = interp.get_input_details()
        output_details = interp.get_output_details()

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((224, 224))
        arr = np.expand_dims(np.array(img, dtype=np.float32) / 255.0, axis=0)

        interp.set_tensor(input_details[0]["index"], arr)
        interp.invoke()

        output = interp.get_tensor(output_details[0]["index"])[0]
        idx    = int(np.argmax(output))
        conf   = float(output[idx])
        label  = _LABELS[idx] if idx < len(_LABELS) else "INVALID"

        logger.info("TFLite %s → %s (%.2f)", scan_type, label, conf)
        return label, conf

    except Exception as exc:
        logger.error("TFLite inference failed (%s): %s — using safe fallback", scan_type, exc)
        return "HIGH_RISK", 0.60
