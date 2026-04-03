import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/scan_result.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel risk;
  final double    confidence;

  const RiskBadge({super.key, required this.risk, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().langCode;
    final s    = AppStrings(lang);

    final (borderColor, bgColor, label) = switch (risk) {
      RiskLevel.low     => (context.success, context.success.withValues(alpha: 0.08), s.resultLowRisk),
      RiskLevel.high    => (context.danger,  context.danger.withValues(alpha: 0.08),  s.resultHighRisk),
      RiskLevel.invalid => (context.warning, context.warning.withValues(alpha: 0.08), s.resultInvalid),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: borderColor,
                  fontSize: 22, fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            Text('${s.resultConfidence}:  ',
                style: TextStyle(
                    color: context.textSec, fontSize: 13)),
            Text('${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.border,
              valueColor: AlwaysStoppedAnimation<Color>(borderColor),
            ),
          ),
        ],
      ),
    );
  }
}
