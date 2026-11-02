import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../theme/app_theme.dart';

class GaugesBar extends StatelessWidget {
  const GaugesBar({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final r = game.run;
    if (r == null) return const SizedBox.shrink();
    final max = game.cfg.gaugeDisplayMax;
    final d = r.card?.deltas ?? const <String, double>{};
    final L = Map<String, dynamic>.from(game.S['gauges'] as Map);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.water),
      ),
      child: Row(
        children: [
          _Gauge(
            label: L['boiler'] as String,
            value: r.boiler,
            max: max,
            hot: r.boiler >= 80,
            delta: d['boiler'],
            deltaKey: 'boiler',
            barColor: AppColors.brass,
          ),
          const SizedBox(width: 8),
          _Gauge(
            label: L['water'] as String,
            value: r.water,
            max: max,
            hot: r.water >= 80,
            delta: d['water'],
            deltaKey: 'water',
            barColor: AppColors.water,
          ),
          const SizedBox(width: 8),
          _Gauge(
            label: L['hull'] as String,
            value: r.hull,
            max: max,
            hot: r.hull >= 50,
            delta: d['hull'],
            deltaKey: 'hull',
            barColor: AppColors.stamp,
          ),
          const SizedBox(width: 8),
          _Gauge(
            label: L['sat'] as String,
            value: r.sat,
            max: max,
            hot: r.sat <= 30,
            delta: d['sat'],
            deltaKey: 'sat',
            barColor: AppColors.ink,
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.max,
    required this.hot,
    required this.deltaKey,
    required this.barColor,
    this.delta,
  });

  final String label;
  final double value;
  final double max;
  final bool hot;
  final double? delta;
  final String deltaKey;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final w = (value / max).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1.6),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${value.round()}',
                style: AppTheme.display.copyWith(
                  fontSize: 21,
                  color: hot ? AppColors.stamp : AppColors.ink,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 4),
                Text(
                  delta! > 0 ? '+${delta!.round()}' : '−${delta!.abs().round()}',
                  style: AppTheme.mono.copyWith(
                    fontSize: 12,
                    color: _deltaColor(deltaKey, delta!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(color: AppColors.chartDeep),
                FractionallySizedBox(
                  widthFactor: w,
                  child: Container(color: barColor),
                ),
              ],
            ),
          ),
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
