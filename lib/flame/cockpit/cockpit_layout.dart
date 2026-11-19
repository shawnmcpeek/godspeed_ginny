import 'dart:ui';

/// Flip to false to fall back to the original stacked node screen (no cockpit).
const bool kCockpitNodeView = true;

/// Design space of the dash group (portrait, 1080 x 1920). The dash, dials, bars,
/// lamps, buttons and wheel are all placed in this space and then mapped onto the
/// screen by [CockpitGeometry]; the shell (awning, poles, deck) adapts separately.
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

  // Lamps (lit sprites are 140 x 140, centred): heat and leak.
  static const Offset heatLamp = Offset(205, 1712);
  static const Offset leakLamp = Offset(875, 1712);
  static const double lampSpriteSize = 140;

  // Beat pips are drawn in code because stretches have 2 to 5 beats.
  static const Offset beatsCenter = Offset(540, 1628);
  static const double beatsSpacing = 46;
  static const int beatsMax = 5;

  // Dash buttons (the brass art is baked into the frame).
  static const Offset repairCenter = Offset(290, 1795);
  static const Offset bailCenter = Offset(790, 1795);
  static const double buttonHitRadius = 64;
}

/// How the cockpit sits on a real screen, for either orientation.
///
/// Portrait is width-locked: 1080 design units span the screen width and the
/// height flexes. The awning hangs from the top, the deck and dash sit on the
/// bottom, and the poles stretch between them, so a taller phone gets a taller
/// window rather than empty sky.
///
/// Landscape is height-locked: 1080 design units span the screen height and the
/// width flexes (1440 to 2520). The dash group shrinks to [landscapeGroupScale]
/// and stays centred; the deck and awning come in pre-rendered width buckets that
/// are stretched slightly to the exact width.
class CockpitGeometry {
  CockpitGeometry._({
    required this.size,
    required this.landscape,
    required this.s,
    required this.g,
  });

  factory CockpitGeometry.forSize(double width, double height) {
    final w = width <= 0 ? 1080.0 : width;
    final h = height <= 0 ? 1920.0 : height;
    final land = w > h;
    return CockpitGeometry._(
      size: Size(w, h),
      landscape: land,
      s: land ? h / 1080 : w / 1080,
      g: land ? landscapeGroupScale : 1.0,
    );
  }

  static const double landscapeGroupScale = 0.84;
  static const List<int> landscapeBuckets = [1440, 1728, 2088, 2520];

  static const double poleInset = 46; // pole centre from the screen edge (design units)
  static const double poleWidth = 26;
  static const double portraitAwningH = 200;
  static const double landscapeAwningH = 120;
  static const double portraitDeckH = 720;
  static const double landscapeDeckH = 540;

  final Size size;
  final bool landscape;

  /// Design units to screen pixels for the shell (awning, poles, deck).
  final double s;

  /// Extra scale applied to the dash group (1 in portrait).
  final double g;

  /// Design units to screen pixels for the dash group.
  double get k => s * g;

  /// Screen position of dash-group design point (0, 0).
  Offset get groupOrigin => Offset(size.width / 2 - 540 * k, size.height - 1920 * k);

  Offset toScreen(Offset p) => Offset(groupOrigin.dx + p.dx * k, groupOrigin.dy + p.dy * k);

  double toScreenY(double y) => groupOrigin.dy + y * k;

  /// Landscape width in design units (height is 1080).
  double get designWidth => size.width / s;

  int get bucket {
    final wd = designWidth;
    var best = landscapeBuckets.first;
    for (final b in landscapeBuckets) {
      if ((b - wd).abs() < (best - wd).abs()) best = b;
    }
    return best;
  }

  /// Asset-name suffix for the shell pieces: `p`, or `l1440` etc.
  String get shellKey => landscape ? 'l$bucket' : 'p';

  double get awningHeight => (landscape ? landscapeAwningH : portraitAwningH) * s;
  double get deckHeight => (landscape ? landscapeDeckH : portraitDeckH) * s;

  /// Lowest point of the awning's valance at screen centre.
  double get awningClear => (landscape ? 96 : 190) * s;

  /// Where the overlay window starts and ends vertically (screen pixels).
  double get windowTop => awningClear;
  double get windowBottom => toScreenY(1300);

  /// Pole centre x positions and the y where they meet the rail.
  double get poleLeftX => poleInset * s;
  double get poleRightX => size.width - poleInset * s;
  double get poleBaseY => toScreenY(1480);

  /// Horizontal room the overlay should keep clear of the poles.
  double get windowSideInset => (poleInset + poleWidth / 2 + 8) * s;
}
