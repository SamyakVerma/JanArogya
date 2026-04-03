import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/scan_result.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'patient_info_screen.dart';

class ScanEntryScreen extends StatefulWidget {
  const ScanEntryScreen({super.key});

  @override
  State<ScanEntryScreen> createState() => _ScanEntryScreenState();
}

class _ScanEntryScreenState extends State<ScanEntryScreen> {
  ScanType   _scanType      = ScanType.oral;
  Uint8List? _imageBytes;
  bool       _picking = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _proceed() {
    if (_imageBytes == null) {
      final lang = context.read<AppProvider>().langCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings(lang).errorNoImage)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientInfoScreen(
          imageBytes: _imageBytes!,
          scanType:   _scanType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().langCode;
    final s    = AppStrings(lang);

    return Scaffold(
      backgroundColor: context.primaryBg,
      appBar: AppBar(
        title: Text(s.scanTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan type selector
            Text(s.scanTypeLabel,
                style: TextStyle(
                    color: context.textSec, fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(children: [
              _TypeChip(
                label:    s.scanOral,
                icon:     Icons.face_outlined,
                selected: _scanType == ScanType.oral,
                onTap:    () => setState(() => _scanType = ScanType.oral),
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label:    s.scanSkin,
                icon:     Icons.back_hand_outlined,
                selected: _scanType == ScanType.skin,
                onTap:    () => setState(() => _scanType = ScanType.skin),
              ),
            ]),
            const SizedBox(height: 20),

            // Image preview / placeholder
            GestureDetector(
              onTap: _picking ? null : () => _pickImage(ImageSource.camera),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imageBytes != null
                        ? context.accent
                        : context.border,
                    width: _imageBytes != null ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.memory(_imageBytes!, fit: BoxFit.cover),
                        // Clear button
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageBytes = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        // Gemini badge on image
                        Positioned(
                          bottom: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: context.accentSec, size: 14),
                                const SizedBox(width: 4),
                                const Text('AI will analyze this',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: context.textSec, size: 48),
                          const SizedBox(height: 12),
                          Text(s.scanInstruction,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.textSec, fontSize: 13,
                                  height: 1.5)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Gallery button
            if (_imageBytes == null)
              OutlinedButton.icon(
                onPressed: _picking ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(s.scanPickImage),
              ),

            // Retake button
            if (_imageBytes != null)
              OutlinedButton.icon(
                onPressed: _picking ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(s.scanRetake),
              ),

            const SizedBox(height: 16),

            // Analyze button
            ElevatedButton(
              onPressed: (_imageBytes != null && !_picking) ? _proceed : null,
              child: Text(s.scanAnalyze),
            ),

            const SizedBox(height: 20),
            Text(s.disclaimer,
                style: TextStyle(
                    color: context.textSec, fontSize: 11,
                    fontStyle: FontStyle.italic, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:  selected ? context.accent : context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? context.accent : context.border),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? Colors.white : context.textSec, size: 22),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected ? Colors.white : context.textSec,
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
