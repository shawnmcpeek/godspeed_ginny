import 'dart:math' as math;
import 'dart:ui';

/// Flip to false to fall back to the original stacked node screen (no cockpit).
const bool kCockpitNodeView = true;

/// Fixed design space for the cockpit art (portrait, 1080 x 1920).
///
/// Every number here comes from `assets/cockpit/manifest.json`. If the art is
/// regenerated, update the manifest and this file together.
class CockpitLayout {
  const CockpitLayout._();

  static const double designW = 1080;
  static const double designH = 1920;

  // Round dials. Needle sprites are square and pivot at their centre.
  static const Offset boilerCenter = Offset(205, 1540);
  static const Offset waterCenter = Offset(875, 1540);
  static const double needleSize = 250;
  static const double dialStartDeg = -135; // 0 on the dial
  static const double dialSweepDeg = 270; // to full scale

  // Linear scales (room on top, damage below). Marker caps are centred on the tube.
  static const double barX0 = 375;
  static const double barX1 = 705;
  static const double roomY = 1478;
  static const double damageY = 1568;
  static const Size markerSize = Size(40, 56);

  // Helm. The lower part of the wheel runs off the bottom of the screen on purpose.
  static const Offset wheelCenter = Offset(540, 1830);
  static const double wheelSpriteSize = 370;
  static const double wheelHitRadius = 150;

  // Lamps (lit sprites are 140 x 140, centred).
  static const Offset heatLamp = Offset(205, 1712);
  static const Offset leakLamp = Offset(875, 1712);
  static const Offset hazardLamp = Offset(540, 1402);
  static const double lampSpriteSize = 140;

  // Beat pips are drawn in code because stretches have 2 to 5 beats.
  static const Offset beatsCenter = Offset(540, 1628);
  static const double beatsSpacing = 46;
  static const int beatsMax = 5;

  // Dash buttons (the brass art is baked into the frame).
  static const Offset repairCenter = Offset(290, 1795);
  static const Offset bailCenter = Offset(790, 1795);
  static const double buttonHitRadius = 64;

  // The part of the window the Flutter overlay may use for text and joke tabs.
  static const double windowTop = 190;
  static const double windowBottom = 1300;
}

/// How the 1080 x 1920 design space sits on a real screen.
///
/// Anchored to the bottom and centred. A screen taller than 9:16 shows extra sky
/// above the awning (the scene layer stretches to fill it). A wider screen
/// letterboxes at the sides for now. Landscape is a later pass.
class CockpitFit {
  const CockpitFit(this.scale, this.dx, this.dy);

  factory CockpitFit.forSize(double width, double height) {
    if (width <= 0 || height <= 0) return const CockpitFit(1, 0, 0);
    final scale = math.min(
      width / CockpitLayout.designW,
      height / CockpitLayout.designH,
    );
    return CockpitFit(
      scale,
      (width - CockpitLayout.designW * scale) / 2,
      height - CockpitLayout.designH * scale,
    );
  }

  final double scale;
  final double dx;
  final double dy;

  Offset toScreen(Offset p) => Offset(dx + p.dx * scale, dy + p.dy * scale);

  double toScreenY(double y) => dy + y * scale;
}
