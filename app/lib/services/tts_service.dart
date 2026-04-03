import 'package:flutter_tts/flutter_tts.dart';

/// TTS service.
/// - Never speaks automatically — only when explicitly called.
/// - stop() halts speech immediately.
/// - Fires onDone/onStart callbacks so UI can toggle icons.
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts    = FlutterTts();
  bool             _ready  = false;
  bool             _speaking = false;

  bool get isSpeaking => _speaking;

  /// Callbacks — set by the UI to update icons.
  void Function()? onStart;
  void Function()? onStop;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() {
      _speaking = true;
      onStart?.call();
    });
    _tts.setCompletionHandler(() {
      _speaking = false;
      onStop?.call();
    });
    _tts.setCancelHandler(() {
      _speaking = false;
      onStop?.call();
    });
    _ready = true;
  }

  Future<void> speak(String text, {String langCode = 'en'}) async {
    await _init();
    final ttsLang = switch (langCode) {
      'hi' => 'hi-IN',
      'ta' => 'ta-IN',
      'te' => 'te-IN',
      _    => 'en-US',
    };
    await _tts.setLanguage(ttsLang);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    onStop?.call();
  }

  void dispose() {
    _tts.stop();
    onStart = null;
    onStop  = null;
  }
}
