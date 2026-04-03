import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/scan_result.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _all     = [];
  String           _filter  = 'all';
  bool             _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await DatabaseService().getHistory();
    if (mounted) setState(() { _all = rows; _loading = false; });
  }

  List<ScanResult> get _filtered {
    if (_filter == 'low')     return _all.where((r) => r.riskLevel == RiskLevel.low).toList();
    if (_filter == 'high')    return _all.where((r) => r.riskLevel == RiskLevel.high).toList();
    if (_filter == 'invalid') return _all.where((r) => r.riskLevel == RiskLevel.invalid).toList();
    return _all;
  }

  Color _riskColor(RiskLevel r) => switch (r) {
    RiskLevel.low     => context.success,
    RiskLevel.high    => context.danger,
    RiskLevel.invalid => context.warning,
  };

  String _riskLabel(RiskLevel r, AppStrings s) => switch (r) {
    RiskLevel.low     => s.resultLowRisk,
    RiskLevel.high    => s.resultHighRisk,
    RiskLevel.invalid => s.resultInvalid,
  };

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().langCode;
    final s    = AppStrings(lang);

    return Scaffold(
      backgroundColor: context.primaryBg,
      appBar: AppBar(
        title: Text(s.historyTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: context.textSec),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Chip(label: s.historyFilterAll,  value: 'all',     current: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _Chip(label: s.historyFilterLow,  value: 'low',     current: _filter, onTap: (v) => setState(() => _filter = v), color: context.success),
                const SizedBox(width: 8),
                _Chip(label: s.historyFilterHigh, value: 'high',    current: _filter, onTap: (v) => setState(() => _filter = v), color: context.danger),
                const SizedBox(width: 8),
                _Chip(label: s.historyFilterInv,  value: 'invalid', current: _filter, onTap: (v) => setState(() => _filter = v), color: context.warning),
              ]),
            ),
          ),
          Divider(height: 1, color: context.border),

          if (_loading)
            Expanded(child: Center(child: CircularProgressIndicator(color: context.accent)))
          else if (_filtered.isEmpty)
            Expanded(child: _EmptyState(s: s))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r       = _filtered[i];
                  final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(r.timestamp);
                  final rColor  = _riskColor(r.riskLevel);
                  final rLabel  = _riskLabel(r.riskLevel, s);

                  return Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: rColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          r.scanType == ScanType.oral
                              ? Icons.face_outlined
                              : Icons.back_hand_outlined,
                          color: rColor, size: 22,
                        ),
                      ),
                      title: Row(children: [
                        Text(r.scanLabel,
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: rColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(rLabel,
                              style: TextStyle(
                                  color: rColor, fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(dateStr,
                            style: TextStyle(
                                color: context.textSec, fontSize: 12)),
                      ),
                      trailing: Text(
                        '${(r.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: rColor, fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  final Color? color;

  const _Chip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final active      = current == value;
    final activeColor = color ?? context.accent;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? activeColor : context.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : context.textSec,
                fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_outlined,
              color: context.textSec.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          Text(s.historyEmpty,
              style: TextStyle(
                  color: context.textPrimary, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(s.historyEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSec, fontSize: 13)),
        ],
      ),
    );
  }
}
