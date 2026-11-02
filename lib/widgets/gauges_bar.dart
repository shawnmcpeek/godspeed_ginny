import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../theme/app_theme.dart';

/// Dashboard of boat instruments: boiler and water as round dials in the corners,
/// the room and hull as linear needle scales between them, and beat pips underneath.
///
/// Everything is painted in code, so brass bezels and faces can be swapped for art later.
class GaugesBar extends StatefulWidget {
  const GaugesBar({super.key, required this.game});

  final Game game;

  @override
  State<GaugesBar> createState() => _GaugesBarState();
}

class _GaugesBarState extends State<GaugesBar> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _syncShake(bool anyHot, bool reduceMotion) {
    final want = anyHot && !reduceMotion;
    if (want && !_shake.isAnimating) {
      _shake.repeat();
    } else if (!want && _shake.isAnimating) {
      _shake.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final r = game.run;
    if (r == null) return const SizedBox.shrink();

    final max = game.cfg.gaugeDisplayMax;
    final d = r.card?.deltas ?? const <String, double>{};
    final L = Map<String, dynamic>.from(game.S['gauges'] as Map);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final boilerHot = r.boiler >= 80;
    final waterHot = r.water >= 80;
    final hullHot = r.hull >= 50;
    final roomHot = r.sat <= 30;
    final anyHot = boilerHot || waterHot || hullHot || roomHot;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncShake(anyHot, reduceMotion);
    });

    final refundFloor = ((game.cfg['refundSatFloor'] as num?)?.toDouble() ?? 45) / max;
    final totalBeats = game.screen == 'node' ? (game.nodes[r.node]?.beats ?? 0) : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.brass, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RoundGauge(
            label: L['boiler'] as String,
            icon: Icons.local_fire_department,
            value: r.boiler,
            max: max,
            hot: boilerHot,
            shake: _shake,
            delta: d['boiler'],
            deltaKey: 'boiler',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LinearGauge(
                  label: L['sat'] as String,
                  value: r.sat,
                  max: max,
                  hot: roomHot,
                  shake: _shake,
                  delta: d['sat'],
                  deltaKey: 'sat',
                  zones: [
                    _Zone(0, refundFloor, AppColors.stamp.withValues(alpha: 0.35)),
                    _Zone(refundFloor, 1, AppColors.water.withValues(alpha: 0.35)),
                  ],
                  leftCaption: 'REFUNDS',
                  rightCaption: 'TIPS',
                ),
                const SizedBox(height: 6),
                _LinearGauge(
                  label: L['hull'] as String,
                  value: r.hull,
                  max: max,
                  hot: hullHot,
                  shake: _shake,
                  delta: d['hull'],
                  deltaKey: 'hull',
                  zones: [
                    _Zone(0, 0.5, AppColors.water.withValues(alpha: 0.18)),
                    _Zone(0.5, 1, AppColors.stamp.withValues(alpha: 0.4)),
                  ],
                ),
                if (totalBeats > 0) ...[
                  const SizedBox(height: 6),
                  _BeatPips(remaining: r.beat, total: totalBeats),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoundGauge(
            label: L['water'] as String,
            icon: Icons.water_drop,
            value: r.water,
            max: max,
            hot: waterHot,
            shake: _shake,
            delta: d['water'],
            deltaKey: 'water',
          ),
        ],
      ),
    );
  }
}

class _Zone {
  const _Zone(this.from, this.to, this.color);

  final double from;
  final double to;
  final Color color;
}

class _RoundGauge extends StatelessWidget {
  const _RoundGauge({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.hot,
    required this.shake,
    required this.deltaKey,
    this.delta,
  });

  final String label;
  final IconData icon;
  final double value;
  final double max;
  final bool hot;
  final Animation<double> shake;
  final String deltaKey;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final ghost = delta == null ? null : (value - delta!) / max;
    return Semantics(
      label: '$label ${value.round()} of ${max.round()}${hot ? ', danger' : ''}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 82,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: value / max),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (context, f, _) => AnimatedBuilder(
                          animation: shake,
                          builder: (context, _) => CustomPaint(
                            painter: _DialPainter(
                              fraction: f,
                              ghost: ghost,
                              redFrom: 0.8,
                              shake: shake.value,
                              hot: hot,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.62),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: AppColors.inkSoft),
                          Text(
                            '${value.round()}',
                            style: AppTheme.display.copyWith(
                              fontSize: 14,
                              color: hot ? AppColors.stamp : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              _LabelRow(label: label, delta: delta, deltaKey: deltaKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.delta, required this.deltaKey});

  final String label;
  final double? delta;
  final String deltaKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mono.copyWith(fontSize: 11, letterSpacing: 1.2),
          ),
        ),
        if (delta != null) ...[
          const SizedBox(width: 4),
          Text(
            _deltaText(delta!),
            style: AppTheme.mono.copyWith(fontSize: 11, color: _deltaColor(deltaKey, delta!)),
          ),
        ],
      ],
    );
  }
}

class _LinearGauge extends StatelessWidget {
  const _LinearGauge({
    required this.label,
    required this.value,
    required this.max,
    required this.hot,
    required this.shake,
    required this.deltaKey,
    required this.zones,
    this.delta,
    this.leftCaption,
    this.rightCaption,
  });

  final String label;
  final double value;
  final double max;
  final bool hot;
  final Animation<double> shake;
  final String deltaKey;
  final List<_Zone> zones;
  final double? delta;
  final String? leftCaption;
  final String? rightCaption;

  @override
  Widget build(BuildContext context) {
    final ghost = delta == null ? null : (value - delta!) / max;
    final captionStyle = AppTheme.mono.copyWith(fontSize: 9, letterSpacing: 1.0);
    return Semantics(
      label: '$label ${value.round()} of ${max.round()}${hot ? ', danger' : ''}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTheme.mono.copyWith(fontSize: 11, letterSpacing: 1.2),
                ),
                const Spacer(),
                if (delta != null) ...[
                  Text(
                    _deltaText(delta!),
                    style: AppTheme.mono.copyWith(
                      fontSize: 11,
                      color: _deltaColor(deltaKey, delta!),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${value.round()}',
                  style: AppTheme.display.copyWith(
                    fontSize: 14,
                    color: hot ? AppColors.stamp : AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 21,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: value / max),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (context, f, _) => AnimatedBuilder(
                  animation: shake,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _BarPainter(
                      fraction: f,
                      ghost: ghost,
                      zones: zones,
                      hot: hot,
                      shake: shake.value,
                    ),
                  ),
                ),
              ),
            ),
            if (leftCaption != null || rightCaption != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(leftCaption ?? '', style: captionStyle),
                  Text(rightCaption ?? '', style: captionStyle),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BeatPips extends StatelessWidget {
  const _BeatPips({required this.remaining, required this.total});

  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final count = math.max(total, remaining);
    return Semantics(
      label: '$remaining of $count beats left',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < remaining ? AppColors.brass : Colors.transparent,
                  border: Border.all(color: AppColors.brass, width: 1.2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.fraction,
    required this.ghost,
    required this.redFrom,
    required this.shake,
    required this.hot,
  });

  final double fraction;
  final double? ghost;
  final double redFrom;
  final double shake;
  final bool hot;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;

    canvas.drawCircle(c, radius, Paint()..color = AppColors.chart.withValues(alpha: 0.9));
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = AppColors.brass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final arcRect = Rect.fromCircle(center: c, radius: radius - 8);
    canvas.drawArc(
      arcRect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.chartDeep,
    );
    canvas.drawArc(
      arcRect,
      _start + _sweep * redFrom,
      _sweep * (1 - redFrom),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.stamp.withValues(alpha: 0.85),
    );

    final tick = Paint()..color = AppColors.ink;
    for (var i = 0; i <= 10; i++) {
      final a = _start + _sweep * i / 10;
      final long = i % 5 == 0;
      final dir = Offset(math.cos(a), math.sin(a));
      tick.strokeWidth = long ? 1.6 : 1;
      canvas.drawLine(c + dir * (radius - 14), c + dir * (radius - (long ? 20 : 17)), tick);
    }

    void needle(double f, Paint p, double len) {
      final a = _start + _sweep * math.min(1.05, math.max(0.0, f));
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * len, p);
    }

    if (ghost != null) {
      needle(
        ghost!,
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.25)
          ..strokeWidth = 2,
        radius - 12,
      );
    }
    final jitter = hot ? math.sin(shake * 2 * math.pi) * 0.025 : 0.0;
    needle(
      fraction + jitter,
      Paint()
        ..color = hot ? AppColors.stamp : AppColors.ink
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
      radius - 10,
    );
    canvas.drawCircle(c, 4, Paint()..color = AppColors.brass);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.fraction != fraction ||
      old.ghost != ghost ||
      old.shake != shake ||
      old.hot != hot ||
      old.redFrom != redFrom;
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.fraction,
    required this.ghost,
    required this.zones,
    required this.hot,
    required this.shake,
  });

  final double fraction;
  final double? ghost;
  final List<_Zone> zones;
  final bool hot;
  final double shake;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(4, 0);
    final w = size.width - 8;

    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, w, 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = AppColors.chartDeep);
    canvas.save();
    canvas.clipRRect(track);
    for (final z in zones) {
      canvas.drawRect(Rect.fromLTRB(w * z.from, 8, w * z.to, 14), Paint()..color = z.color);
    }
    canvas.restore();
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.brass,
    );

    final tick = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final x = w * i / 10;
      canvas.drawLine(Offset(x, 15), Offset(x, i % 5 == 0 ? 20 : 18), tick);
    }

    double xFor(double f) => w * math.min(1.0, math.max(0.0, f));

    if (ghost != null) {
      final gx = xFor(ghost!);
      canvas.drawLine(
        Offset(gx, 2),
        Offset(gx, 15),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.3)
          ..strokeWidth = 1.5,
      );
    }

    final jitter = hot ? math.sin(shake * 2 * math.pi) * 1.5 : 0.0;
    final x = xFor(fraction) + jitter;
    final color = hot ? AppColors.stamp : AppColors.ink;
    final pointer = Path()
      ..moveTo(x - 4, 0)
      ..lineTo(x + 4, 0)
      ..lineTo(x, 8)
      ..close();
    canvas.drawPath(pointer, Paint()..color = color);
    canvas.drawLine(
      Offset(x, 8),
      Offset(x, 15),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.ghost != ghost ||
      old.shake != shake ||
      old.hot != hot ||
      old.zones != zones;
}

String _deltaText(double n) => n > 0 ? '+${n.round()}' : '−${n.abs().round()}';

Color _deltaColor(String key, double n) {
  const badUp = {'boiler', 'water', 'hull', 'threat'};
  if (n > 0) return badUp.contains(key) ? AppColors.stamp : AppColors.brass;
  return badUp.contains(key) ? AppColors.brass : AppColors.stamp;
}
