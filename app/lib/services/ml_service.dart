import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/scan_result.dart';

const int _inputSize = 224;

// Safe fallback messages in all 4 languages
const _messages = {
  RiskLevel.low: (
    en: 'No serious signs detected in this scan. Keep monitoring and do regular checkups.',
    hi: 'इस जांच में कोई गंभीर संकेत नहीं मिले। नियमित जांच करते रहें।',
    ta: 'இந்த ஸ்கேனில் தீவிரமான அறிகுறிகள் கண்டறியப்படவில்லை. தொடர்ந்து கண்காணிக்கவும்.',
    te: 'ఈ స్కాన్‌లో తీవ్రమైన సంకేతాలు కనుగొనబడలేదు. నిరంతరం పర్యవేక్షించండి.',
  ),
  RiskLevel.high: (
    en: 'Some signs need medical attention. Please see a doctor as soon as possible.',
    hi: 'इस तस्वीर में कुछ बातें हैं जिन पर ध्यान देना जरूरी है। जल्द डॉक्टर से मिलें।',
    ta: 'சில அறிகுறிகளுக்கு மருத்துவ கவனிப்பு தேவை. விரைவில் மருத்துவரை அணுகவும்.',
    te: 'కొన్ని సంకేతాలకు వైద్య శ్రద్ధ అవసరం. వీలైనంత త్వరగా వైద్యుడిని చూడండి.',
  ),
  RiskLevel.invalid: (
    en: 'Photo not suitable for screening. Please retake in good lighting.',
    hi: 'तस्वीर जांच के लिए उपयुक्त नहीं। कृपया अच्छी रोशनी में दोबारा लें।',
    ta: 'புகைப்படம் திரையிடலுக்கு ஏற்றதாக இல்லை. நல்ல வெளிச்சத்தில் மீண்டும் எடுக்கவும்.',
    te: 'ఫోటో స్క్రీనింగ్‌కి అనువుగా లేదు. మంచి వెలుతురులో తిరిగి తీయండి.',
  ),
};

class MLService {
  static final MLService _instance = MLService._();
  factory MLService() => _instance;
  MLService._();

  Interpreter? _skinInterpreter;
  Interpreter? _oralInterpreter;
  bool _skinLoaded = false;
  bool _oralLoaded = false;

  Future<void> loadModel(ScanType type) async {
    try {
      if (type == ScanType.skin && !_skinLoaded) {
        _skinInterpreter = await Interpreter.fromAsset(
          'assets/models/janarogya_skin_int8.tflite',
          options: InterpreterOptions()..threads = 2,
        );
        _skinLoaded = true;
      } else if (type == ScanType.oral && !_oralLoaded) {
        _oralInterpreter = await Interpreter.fromAsset(
          'assets/models/janarogya_oral_f32.tflite',
          options: InterpreterOptions()..threads = 2,
        );
        _oralLoaded = true;
      }
    } catch (_) {
      // Model not found — analyze() will use fallback
    }
  }

  Future<ScanResult> analyze(Uint8List imageBytes, ScanType scanType) async {
    await loadModel(scanType);

    final interpreter =
        scanType == ScanType.oral ? _oralInterpreter : _skinInterpreter;

    if (interpreter == null) {
      return _build(scanType, RiskLevel.invalid, 0.5);
    }

    try {
      final raw = img.decodeImage(imageBytes);
      if (raw == null) return _build(scanType, RiskLevel.invalid, 0.0);

      final resized = img.copyResize(raw, width: _inputSize, height: _inputSize);

      final inputTensor = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r.toDouble() / 255.0,
                pixel.g.toDouble() / 255.0,
                pixel.b.toDouble() / 255.0,
              ];
            },
          ),
        ),
      );

      final outputTensor = [List.filled(3, 0.0)];
      interpreter.run(inputTensor, outputTensor);

      final scores   = outputTensor[0];
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final classIdx = scores.indexOf(maxScore);

      final risk = switch (classIdx) {
        0 => RiskLevel.low,
        1 => RiskLevel.high,
        _ => RiskLevel.invalid,
      };

      return _build(scanType, risk, maxScore);
    } catch (_) {
      return _build(scanType, RiskLevel.invalid, 0.5);
    }
  }

  ScanResult _build(ScanType type, RiskLevel risk, double conf) {
    final m = _messages[risk]!;
    return ScanResult(
      scanType:      type,
      riskLevel:     risk,
      confidence:    conf,
      explanationEn: m.en,
      explanationHi: m.hi,
      explanationTa: m.ta,
      explanationTe: m.te,
      timestamp:     DateTime.now(),
    );
  }

  void dispose() {
    _skinInterpreter?.close();
    _oralInterpreter?.close();
  }
}
