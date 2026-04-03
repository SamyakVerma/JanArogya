import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../models/patient_info.dart';
import '../models/scan_result.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/risk_badge.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List    imageBytes;
  final ScanResult   result;
  final PatientInfo? patientInfo;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.result,
    this.patientInfo,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _speaking     = false;
  bool _loadingPdf   = false;
  bool _loadingShare = false;

  @override
  void initState() {
    super.initState();
    _saveLocally();
    // Setup TTS callbacks
    TtsService().onStart = () { if (mounted) setState(() => _speaking = true);  };
    TtsService().onStop  = () { if (mounted) setState(() => _speaking = false); };
  }

  @override
  void dispose() {
    TtsService().stop();
    TtsService().onStart = null;
    TtsService().onStop  = null;
    super.dispose();
  }

  Future<void> _saveLocally() async {
    try { await DatabaseService().saveScan(widget.result); } catch (_) {}
  }

  Future<void> _toggleTts() async {
    final lang = context.read<AppProvider>().langCode;
    if (_speaking) {
      await TtsService().stop();
    } else {
      final text = widget.result.explanationFor(lang);
      await TtsService().speak(text, langCode: lang);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=cancer+screening+hospital+near+me',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Map<String, dynamic> _buildPayload(String lang) {
    final result  = widget.result;
    final patient = widget.patientInfo;
    return {
      'scan_type':          result.scanType.name,
      'risk_level':         result.riskKey,
      'confidence':         result.confidence,
      'explanation_en':     result.explanationEn,
      'explanation_local':  result.explanationFor(lang),
      'local_language':     lang,
      'concern':            _concernText(result.riskLevel, lang),
      'image_base64':       base64Encode(widget.imageBytes),
      if (patient != null) ...{
        'user_name':    patient.name,
        'phone_masked': patient.phoneMasked,
      },
      if (result.symptoms != null && result.symptoms!.isNotEmpty)
        'questions_and_answers': result.symptoms!.entries
            .map((e) => {'question': e.key, 'answer': e.value})
            .toList(),
    };
  }

  Future<File?> _generateAndDownloadPdf(String lang) async {
    final s    = AppStrings(lang);
    final resp = await ApiService().generateReport(_buildPayload(lang));
    if (resp == null || resp['success'] != true) {
      _showSnack(s.errorPdfFailed);
      return null;
    }
    final reportId = resp['report_id'] as String;
    final bytes    = await ApiService().downloadReport(reportId);
    if (bytes == null) { _showSnack(s.errorPdfFailed); return null; }

    final dir      = await getTemporaryDirectory();
    final filename = resp['filename'] as String? ?? 'JanArogya_Report.pdf';
    final file     = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _downloadReport() async {
    setState(() => _loadingPdf = true);
    try {
      final lang = context.read<AppProvider>().langCode;
      final file = await _generateAndDownloadPdf(lang);
      if (file != null) await OpenFile.open(file.path);
    } catch (_) {
      if (mounted) {
        _showSnack(AppStrings(context.read<AppProvider>().langCode).errorPdfFailed);
      }
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  Future<void> _shareReport() async {
    setState(() => _loadingShare = true);
    try {
      final lang = context.read<AppProvider>().langCode;
      final file = await _generateAndDownloadPdf(lang);
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'JanArogya Screening Report',
          text: 'Screening result from JanArogya — shared for medical reference.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack(AppStrings(context.read<AppProvider>().langCode).errorPdfFailed);
      }
    } finally {
      if (mounted) setState(() => _loadingShare = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _concernText(RiskLevel risk, String lang) {
    final texts = {
      RiskLevel.low: {
        'en': 'No immediate action required. Continue regular health checkups.',
        'hi': 'तत्काल कार्रवाई आवश्यक नहीं है। नियमित स्वास्थ्य जांच जारी रखें।',
        'ta': 'உடனடி நடவடிக்கை தேவையில்லை. வழக்கமான சுகாதார பரிசோதனைகளை தொடரவும்.',
        'te': 'తక్షణ చర్య అవసరం లేదు. సాధారణ ఆరోగ్య తనిఖీలు కొనసాగించండి.',
      },
      RiskLevel.high: {
        'en': 'Please consult a doctor as soon as possible. Early consultation is important.',
        'hi': 'कृपया जल्द से जल्द डॉक्टर से मिलें। जल्दी परामर्श जरूरी है।',
        'ta': 'விரைவில் மருத்துவரை அணுகவும். ஆரம்ப ஆலோசனை முக்கியம்.',
        'te': 'వీలైనంత త్వరగా వైద్యుడిని సంప్రదించండి. ముందస్తు సంప్రదింపు ముఖ్యమైనది.',
      },
      RiskLevel.invalid: {
        'en': 'The image quality was insufficient. Please retake the photo in good lighting.',
        'hi': 'तस्वीर की गुणवत्ता अपर्याप्त थी। कृपया अच्छी रोशनी में फिर से लें।',
        'ta': 'படத்தின் தரம் போதுமானதாக இல்லை. நல்ல வெளிச்சத்தில் மீண்டும் எடுக்கவும்.',
        'te': 'చిత్రం నాణ్యత సరిపోలేదు. మంచి వెలుతురులో తిరిగి తీయండి.',
      },
    };
    return texts[risk]?[lang] ?? texts[risk]?['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final lang   = context.watch<AppProvider>().langCode;
    final s      = AppStrings(lang);
    final result = widget.result;
    final expl   = result.explanationFor(lang);

    return Scaffold(
      backgroundColor: context.primaryBg,
      appBar: AppBar(
        title: Text(s.resultTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanned image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.imageBytes,
                height: 160, width: double.infinity, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Risk badge
            RiskBadge(risk: result.riskLevel, confidence: result.confidence),
            const SizedBox(height: 16),

            // Explanation card with TTS button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.resultExplanation,
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      // TTS toggle button
                      IconButton(
                        icon: Icon(
                          _speaking ? Icons.stop_circle : Icons.volume_up_outlined,
                          color: context.accent,
                          size: 24,
                        ),
                        tooltip: _speaking ? 'Stop' : 'Listen',
                        onPressed: _toggleTts,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(expl,
                      style: TextStyle(
                          color: context.textSec,
                          fontSize: 14, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Symptoms summary
            if (result.symptoms != null && result.symptoms!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported Symptoms',
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...result.symptoms!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${e.key}: ${e.value}',
                          style: TextStyle(
                              color: context.textSec, fontSize: 13)),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: context.warning.withValues(alpha: 0.4)),
              ),
              child: Text(s.disclaimer,
                  style: TextStyle(
                      color: context.textSec, fontSize: 12,
                      fontStyle: FontStyle.italic, height: 1.5)),
            ),
            const SizedBox(height: 20),

            // Find clinic button
            ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(s.resultFindClinic),
            ),
            const SizedBox(height: 10),

            // Download report button
            OutlinedButton.icon(
              onPressed: _loadingPdf ? null : _downloadReport,
              icon: _loadingPdf
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.accent))
                  : const Icon(Icons.download_outlined),
              label: Text(_loadingPdf
                  ? AppStrings(lang).loadingReport
                  : s.resultDownload),
            ),
            const SizedBox(height: 10),

            // Share report button
            OutlinedButton.icon(
              onPressed: _loadingShare ? null : _shareReport,
              icon: _loadingShare
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.accent))
                  : const Icon(Icons.share_outlined),
              label: Text(s.resultShareReport),
            ),
            const SizedBox(height: 10),

            // Scan again
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Text(s.resultScanAgain,
                    style: TextStyle(color: context.textSec)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
