import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TelegramView extends StatelessWidget {
  const TelegramView({
    super.key,
    required this.header,
    required this.body,
    this.signoff,
  });

  final String header;
  final String body;
  final String? signoff;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatTelegram(body);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.stamp, width: 5),
          left: BorderSide(color: AppColors.stamp),
          right: BorderSide(color: AppColors.stamp),
          bottom: BorderSide(color: AppColors.stamp),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: AppTheme.stamp.copyWith(fontSize: 15, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.chartDeep),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(children: _stopSpans(formatted)),
            style: AppTheme.mono.copyWith(
              fontSize: 17,
              height: 1.65,
              color: AppColors.ink,
              letterSpacing: 0.3,
            ),
          ),
          if (signoff != null) ...[
            const SizedBox(height: 16),
            Text(
              signoff!,
              style: AppTheme.mono.copyWith(fontSize: 17, color: AppColors.ink),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTelegram(String raw) {
    final chunks = raw.split(RegExp(r'\s*STOP\s*')).where((p) => p.isNotEmpty).toList();
    if (chunks.isEmpty) return raw;
    var out = chunks.join(' - STOP - ');
    if (RegExp(r'STOP\s*$').hasMatch(raw)) out += ' - STOP';
    return out;
  }

  List<InlineSpan> _stopSpans(String text) {
    final parts = text.split('STOP');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: 'STOP',
            style: AppTheme.mono.copyWith(
              color: AppColors.stamp,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
    }
    return spans;
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text.toUpperCase(),
            style: AppTheme.mono.copyWith(
              fontSize: 13,
              letterSpacing: 2.2,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 5),
          Container(height: 1, color: AppColors.chartDeep),
        ],
      ),
    );
  }
}
