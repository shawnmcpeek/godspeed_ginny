import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../content/models.dart';
import '../theme/app_theme.dart';

class PlayCardView extends StatelessWidget {
  const PlayCardView({super.key, required this.card, required this.strings});

  final PlayCard card;
  final Map<String, dynamic> strings;

  @override
  Widget build(BuildContext context) {
    final C = Map<String, dynamic>.from(strings['card'] as Map);
    final stations = Map<String, dynamic>.from(C['stations'] as Map);
    final station = (stations[card.station] as String?) ?? card.station;
    final bits = <String>[station];
    if (card.beatsSpent > 0) {
      bits.add(
        card.beatsSpent == 1
            ? fill(C['beat'] as String, {'n': card.beatsSpent})
            : fill(C['beats'] as String, {'n': card.beatsSpent}),
      );
    }
    if (card.ended) bits.add(C['ended'] as String);
    final eyebrow = dig(strings, 'log.skipperEyebrow') as String? ?? 'SKIPPER';
    final labels = Map<String, dynamic>.from(C['labels'] as Map);
    const order = ['threat', 'boiler', 'water', 'hull', 'sat', 'cargoHealth'];
    final chips = order.where((k) => card.deltas[k] != null).map((k) {
      final n = card.deltas[k]!;
      return Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${labels[k]} '.toUpperCase(),
                style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.inkSoft),
              ),
              TextSpan(
                text: n > 0 ? '+${n.round()}' : '−${n.abs().round()}',
                style: AppTheme.mono.copyWith(fontSize: 13, color: _deltaColor(k, n)),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.water, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bits.join(' · ').toUpperCase(),
            style: AppTheme.mono.copyWith(
              fontSize: 12,
              letterSpacing: 1.8,
              color: AppColors.stamp,
            ),
          ),
          const SizedBox(height: 8),
          ...card.lines.map((l) => _LogLine(line: l, eyebrow: eyebrow)),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.chartDeep),
            const SizedBox(height: 10),
            Wrap(children: chips),
          ],
        ],
      ),
    );
  }

  Color _deltaColor(String key, double n) {
    const badUp = {'boiler', 'water', 'hull', 'threat'};
    if (n > 0) return badUp.contains(key) ? AppColors.stamp : AppColors.brass;
    return badUp.contains(key) ? AppColors.brass : AppColors.stamp;
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.line, required this.eyebrow});

  final LogLine line;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    Color border;
    TextStyle style;
    switch (line.cls) {
      case 'skip':
        border = AppColors.ink;
        style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 19);
      case 'act':
        border = AppColors.water;
        style = Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.inkSoft);
      case 'bad':
        border = AppColors.stamp;
        style = Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.stamp);
      case 'good':
        border = AppColors.brass;
        style = Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.ink);
      case 'beat':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            line.text,
            style: AppTheme.mono.copyWith(fontSize: 16, color: AppColors.inkSoft),
          ),
        );
      default:
        border = AppColors.chartDeep;
        style = Theme.of(context).textTheme.bodyLarge!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.only(left: 16, top: 7, bottom: 7),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.cls == 'skip')
            Text(
              eyebrow.toUpperCase(),
              style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1.8),
            ),
          Text(line.text, style: style),
        ],
      ),
    );
  }
}
