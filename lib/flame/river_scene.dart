import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../theme/app_theme.dart';

/// Simple 2D river under the Flutter UI. Boat drifts with gauge pressure.
class RiverScene extends FlameGame {
  RiverScene();

  late final RiverBackground _bg;
  late final BoatSprite _boat;

  double boiler = 15;
  double water = 10;
  double hull = 0;
  double threat = 0;
  bool playing = false;

  void syncGauges({
    required double boiler,
    required double water,
    required double hull,
    required double threat,
    required bool playing,
  }) {
    this.boiler = boiler;
    this.water = water;
    this.hull = hull;
    this.threat = threat;
    this.playing = playing;
  }

  @override
  Color backgroundColor() => AppColors.water;

  @override
  Future<void> onLoad() async {
    _bg = RiverBackground();
    _boat = BoatSprite();
    await add(_bg);
    await add(_boat);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bg.flowSpeed = playing ? 40 + boiler * 0.6 : 18;
    _bg.chop = playing ? water * 0.012 : 0.05;
    _boat.yaw = playing ? math.sin(DateTime.now().millisecondsSinceEpoch / 420) * (0.04 + threat * 0.004) : 0.02;
    _boat.list = playing ? (hull * 0.004).clamp(0, 0.35) : 0;
    _boat.steam = playing ? (boiler / 100).clamp(0.15, 1.0) : 0.2;
  }
}

class RiverBackground extends Component with HasGameReference<RiverScene> {
  double flowSpeed = 30;
  double chop = 0.1;
  double _offset = 0;

  @override
  void update(double dt) {
    _offset = (_offset + flowSpeed * dt) % 80;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final paint = Paint()..color = AppColors.water;
    canvas.drawRect(Offset.zero & size.toSize(), paint);

    final bank = Paint()..color = AppColors.chartDeep.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x * 0.18, size.y), bank);
    canvas.drawRect(Rect.fromLTWH(size.x * 0.82, 0, size.x * 0.18, size.y), bank);

    final ripple = Paint()
      ..color = const Color(0x33204040)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var y = -80.0; y < size.y + 80; y += 28) {
      final yy = y + _offset;
      final path = Path();
      path.moveTo(size.x * 0.2, yy);
      for (var x = size.x * 0.2; x < size.x * 0.8; x += 18) {
        final wave = math.sin((x + _offset) * 0.05) * (6 + chop * 40);
        path.lineTo(x, yy + wave);
      }
      canvas.drawPath(path, ripple);
    }

    final fog = Paint()
      ..shader = Gradient.linear(
        Offset(0, size.y * 0.55),
        Offset(0, size.y),
        [const Color(0x00DCDCCB), AppColors.chart.withValues(alpha: 0.55)],
      );
    canvas.drawRect(Offset.zero & size.toSize(), fog);
  }
}

class BoatSprite extends Component with HasGameReference<RiverScene> {
  double yaw = 0;
  double list = 0;
  double steam = 0.2;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final cx = size.x * 0.5;
    final cy = size.y * 0.42;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(yaw + list);

    final hull = Paint()..color = AppColors.ink;
    final cabin = Paint()..color = AppColors.chart;
    final trim = Paint()..color = AppColors.brass;
    final stamp = Paint()..color = AppColors.stamp;

    final hullPath = Path()
      ..moveTo(-42, 8)
      ..lineTo(48, 4)
      ..lineTo(36, 22)
      ..lineTo(-36, 24)
      ..close();
    canvas.drawPath(hullPath, hull);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -10, 34, 20), const Radius.circular(2)),
      cabin,
    );
    canvas.drawRect(const Rect.fromLTWH(-6, -28, 8, 20), trim);
    canvas.drawCircle(const Offset(-2, -32), 5, stamp);

    final steamPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 3; i++) {
      final t = (DateTime.now().millisecondsSinceEpoch / 400 + i).remainder(3);
      final oy = -36.0 - t * 18 * steam;
      final ox = -2.0 + math.sin(t + i) * 4;
      canvas.drawCircle(Offset(ox, oy), 4 + t * 3 * steam, steamPaint);
    }

    canvas.restore();
  }
}
