import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanTypeCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   hint;
  final VoidCallback onTap;

  const ScanTypeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(hint,
                    style: TextStyle(
                        color: context.textSec, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textSec, size: 18),
        ]),
      ),
    );
  }
}
