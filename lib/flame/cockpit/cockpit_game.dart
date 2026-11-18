import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'cockpit_layout.dart';

/// What a dash button should look like right now.
enum CockpitButtonState { disabled, idle, urgent }

/// Everything the cockpit needs to draw one moment of the run. Gauge values are
/// fractions of full scale (0..1). The Flutter overlay builds one of these from
/// the real game state and hands it over; the cockpit never reads the engine.
class CockpitSnapshot {
  const CockpitSnapshot({
    this.boiler = 0,
    this.water = 0,
    this.hull = 0,
    this.room = 0.5,
    this.beatsLeft = 0,
    this.beatsTotal = 0,
    this.threat = 0,
    this.reduceMotion = false,
    this.repair = CockpitButtonState.idle,
    this.bail = CockpitButtonState.idle,
  });

  final double boiler;
  final double water;
  final double hull;
  final double room;
  final int beatsLeft;
  final int beatsTotal;
  final double threat;
  final bool reduceMotion;
  final CockpitButtonState repair;
  final CockpitButtonState bail;
}

/// First-person helm view: the scene ahead, the boat, and live instruments.
///
/// Layers, back to front: scene (swappable, crossfades), frame (boat with a
/// transparent window), needles, bar markers, beat pips, glass glare, lamps,
/// button states, wheel. Everything lives in a 1080 x 1920 design space that is
/// scaled onto the screen by [CockpitFit].
class CockpitGame extends FlameGame {
  CockpitGame();

  /// Scene id to asset. Add real art here; the game picks one per stretch.
  static const Map<String, String> sceneAssets = {
    'default': 'assets/cockpit/scene_placeholder.png',
  };

  static const String _dir = 'assets/cockpit/';

  CockpitSnapshot snapshot = const CockpitSnapshot();
  CockpitFit fit = const CockpitFit(1, 0, 0);

  final Map<String, Image> _images = {};
  PositionComponent? _root;
  _SceneLayer? _scene;
  _Wheel? _wheel;
  _ButtonOverlay? _repairOverlay;
  _ButtonOverlay? _bailOverlay;
  String _wantedScene = 'default';
  String? _shownScene;

  @override
  Color backgroundColor() => const Color(0xFF1B2F2C);

  Future<Image> _image(String path) async {
    final cached = _images[path];
    if (cached != null) return cached;
    final data = await rootBundle.load(path);
    final codec = await instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    return _images[path] = frame.image;
  }

  Future<Sprite> _sprite(String file) async => Sprite(await _image('$_dir$file'));

  @override
  Future<void> onLoad() async {
    final root = PositionComponent(
      size: Vector2(CockpitLayout.designW, CockpitLayout.designH),
    );
    _root = root;
    await add(root);
    _applyFit();

    final scene = _SceneLayer();
    _scene = scene;
    await root.add(scene);

    await root.add(
      SpriteComponent(
        sprite: await _sprite('frame.png'),
        size: Vector2(CockpitLayout.designW, CockpitLayout.designH),
        priority: 1,
      ),
    );

    final boilerNeedle = await _sprite('needle_boiler.png');
    final waterNeedle = await _sprite('needle_water.png');
    await root.add(_Needle(boilerNeedle, CockpitLayout.boilerCenter, (s) => s.boiler));
    await root.add(_Needle(waterNeedle, CockpitLayout.waterCenter, (s) => s.water));

    final marker = await _sprite('marker.png');
    await root.add(_Marker(marker, CockpitLayout.roomY, (s) => s.room));
    await root.add(_Marker(marker, CockpitLayout.damageY, (s) => s.hull));

    await root.add(_BeatPips());

    await root.add(
      SpriteComponent(
        sprite: await _sprite('glass_overlay.png'),
        position: Vector2(0, 1380),
        size: Vector2(CockpitLayout.designW, 400),
        priority: 5,
      ),
    );

    await root.add(
      _Lamp(
        await _sprite('lamp_heat_on.png'),
        CockpitLayout.heatLamp,
        (s, t) => s.boiler >= 0.8 ? _pulse(s, t, 2.2) : 0,
      ),
    );
    await root.add(
      _Lamp(
        await _sprite('lamp_leak_on.png'),
        CockpitLayout.leakLamp,
        (s, t) => s.water >= 0.8 ? _pulse(s, t, 2.2) : 0,
      ),
    );

    final repair = _ButtonOverlay(CockpitLayout.repairCenter, (s) => s.repair);
    final bail = _ButtonOverlay(CockpitLayout.bailCenter, (s) => s.bail);
    _repairOverlay = repair;
    _bailOverlay = bail;
    await root.add(repair);
    await root.add(bail);

    final wheel = _Wheel(await _sprite('wheel.png'));
    _wheel = wheel;
    await root.add(wheel);

    await _syncScene();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    fit = CockpitFit.forSize(size.x, size.y);
    _applyFit();
  }

  void _applyFit() {
    final root = _root;
    if (root == null) return;
    root.position = Vector2(fit.dx, fit.dy);
    root.scale = Vector2.all(fit.scale);
  }

  /// Crossfade to the scene art for [key] (see [sceneAssets]). Safe to call every
  /// frame: it only does work when the key changes.
  Future<void> showScene(String key) {
    _wantedScene = key;
    return _syncScene();
  }

  Future<void> _syncScene() async {
    final scene = _scene;
    if (scene == null) return;
    final key = _wantedScene;
    if (key == _shownScene) return;
    _shownScene = key;
    final path = sceneAssets[key] ?? sceneAssets['default']!;
    final image = await _image(path);
    if (_wantedScene != key) return;
    scene.show(image, instant: !scene.hasImage);
  }

  /// Turn the wheel (alternates left and right so it stays near centre).
  void steerWheel() => _wheel?.spin();

  /// Flash a dash button when it is pressed.
  void pressButton({required bool repair}) {
    (repair ? _repairOverlay : _bailOverlay)?.flash();
  }
}

/// Soft 0..1 pulse for warning lamps. Steady when reduce-motion is on.
double _pulse(CockpitSnapshot s, double t, double hz) {
  if (s.reduceMotion) return 1;
  return 0.65 + 0.35 * math.sin(2 * math.pi * hz * t);
}

double _ease(double current, double target, double dt, double rate) =>
    current + (target - current) * (1 - math.exp(-rate * dt));

/// The view ahead. Two images crossfade on a scene change. A gentle sway moves
/// the world (not the boat) so the cockpit feels afloat; it grows with threat
/// and hull damage and is off under reduce-motion.
class _SceneLayer extends PositionComponent with HasGameReference<CockpitGame> {
  _SceneLayer()
      : super(
          size: Vector2(CockpitLayout.designW, CockpitLayout.designH),
          priority: 0,
        );

  Image? _current;
  Image? _incoming;
  double _fade = 1;
  double _t = 0;

  bool get hasImage => _current != null;

  void show(Image image, {bool instant = false}) {
    if (instant || _current == null) {
      _current = image;
      _incoming = null;
      _fade = 1;
    } else {
      _incoming = image;
      _fade = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_incoming != null) {
      _fade += dt / 0.9;
      if (_fade >= 1) {
        _current = _incoming;
        _incoming = null;
        _fade = 1;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final current = _current;
    if (current == null) return;
    final s = game.snapshot;
    final amp = s.reduceMotion ? 0.0 : 1.0 + math.min(s.threat, 20.0) * 0.05 + s.hull * 1.2;
    const w = CockpitLayout.designW;
    const h = CockpitLayout.designH;

    canvas.save();
    canvas.translate(w / 2 + math.sin(_t * 0.9) * 5 * amp, h / 2 + math.sin(_t * 1.3) * 4 * amp);
    canvas.rotate(math.sin(_t * 0.6) * 0.004 * amp);
    canvas.scale(1.08);
    canvas.translate(-w / 2, -h / 2);
    _draw(canvas, current, 1);
    final incoming = _incoming;
    if (incoming != null) _draw(canvas, incoming, _fade.clamp(0.0, 1.0).toDouble());
    canvas.restore();
  }

  void _draw(Canvas canvas, Image image, double alpha) {
    const w = CockpitLayout.designW;
    const h = CockpitLayout.designH;
    final paint = Paint()..color = Color.fromARGB((alpha * 255).round(), 255, 255, 255);
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, iw, ih), const Rect.fromLTWH(0, 0, w, h), paint);

    // Fill the area outside the design rectangle (tall or wide screens, plus sway
    // margin) by stretching the image's edge rows and columns outward.
    final f = game.fit;
    final extraTop = f.dy / f.scale + 200;
    final extraSide = f.dx / f.scale + 200;
    const extraBottom = 200.0;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, 2),
      Rect.fromLTRB(-extraSide, -extraTop, w + extraSide, 0),
      paint,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, ih - 2, iw, 2),
      Rect.fromLTRB(-extraSide, h, w + extraSide, h + extraBottom),
      paint,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, 2, ih),
      Rect.fromLTRB(-extraSide, 0, 0, h),
      paint,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(iw - 2, 0, 2, ih),
      Rect.fromLTRB(w, 0, w + extraSide, h),
      paint,
    );
  }
}

/// A dial needle. Sweeps to the target, and trembles when the gauge is in the red.
class _Needle extends SpriteComponent with HasGameReference<CockpitGame> {
  _Needle(Sprite sprite, Offset center, this._read)
      : super(
          sprite: sprite,
          position: Vector2(center.dx, center.dy),
          size: Vector2.all(CockpitLayout.needleSize),
          anchor: Anchor.center,
          priority: 2,
        );

  final double Function(CockpitSnapshot) _read;
  double _shown = 0;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final s = game.snapshot;
    final target = _read(s).clamp(0.0, 1.0).toDouble();
    _shown = _ease(_shown, target, dt, 7);
    _t += dt;
    var deg = CockpitLayout.dialStartDeg + _shown * CockpitLayout.dialSweepDeg;
    if (!s.reduceMotion && target >= 0.8) deg += math.sin(_t * 38) * 1.4;
    angle = deg * math.pi / 180;
  }
}

/// A slider cap riding on one of the linear scales.
class _Marker extends SpriteComponent with HasGameReference<CockpitGame> {
  _Marker(Sprite sprite, double y, this._read)
      : super(
          sprite: sprite,
          position: Vector2(CockpitLayout.barX0, y + 2),
          size: Vector2(CockpitLayout.markerSize.width, CockpitLayout.markerSize.height),
          anchor: Anchor.center,
          priority: 3,
        );

  final double Function(CockpitSnapshot) _read;
  double _shown = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    final target = _read(game.snapshot).clamp(0.0, 1.0).toDouble();
    _shown = _ease(_shown, target, dt, 6);
    position.x = CockpitLayout.barX0 + (CockpitLayout.barX1 - CockpitLayout.barX0) * _shown;
  }
}

/// Beat pips in the slot under the bars: one lamp per beat, lit while a beat remains.
class _BeatPips extends PositionComponent with HasGameReference<CockpitGame> {
  _BeatPips()
      : super(
          size: Vector2(CockpitLayout.designW, CockpitLayout.designH),
          priority: 4,
        );

  final List<double> _lit = List<double>.filled(CockpitLayout.beatsMax, 0);

  @override
  void update(double dt) {
    super.update(dt);
    final s = game.snapshot;
    for (var i = 0; i < _lit.length; i++) {
      _lit[i] = _ease(_lit[i], i < s.beatsLeft ? 1.0 : 0.0, dt, 9);
    }
  }

  @override
  void render(Canvas canvas) {
    final s = game.snapshot;
    final n = s.beatsTotal.clamp(0, CockpitLayout.beatsMax);
    if (n == 0) return;
    const amber = Color(0xFFFFB82E);
    const unlit = Color(0xFF3A2A10);

    for (var i = 0; i < n; i++) {
      final lit = _lit[i];
      final c = Offset(
        CockpitLayout.beatsCenter.dx + (i - (n - 1) / 2) * CockpitLayout.beatsSpacing,
        CockpitLayout.beatsCenter.dy,
      );
      canvas.drawCircle(c + const Offset(0, 2), 18, Paint()..color = const Color(0x66000000));
      canvas.drawCircle(c, 17, Paint()..color = const Color(0xFFB8862A));
      canvas.drawCircle(c, 13.5, Paint()..color = const Color(0xFF150E06));
      canvas.drawCircle(c, 11, Paint()..color = Color.lerp(unlit, amber, lit)!);
      if (lit > 0.01) {
        final glow = Paint()
          ..blendMode = BlendMode.plus
          ..shader = Gradient.radial(
            c,
            44,
            [
              Color.fromRGBO(255, 190, 60, 0.85 * lit),
              const Color.fromRGBO(255, 190, 60, 0),
            ],
          );
        canvas.drawCircle(c, 44, glow);
        canvas.drawOval(
          Rect.fromCenter(center: c + const Offset(-3, -4), width: 8, height: 5),
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * lit),
        );
      }
    }
  }
}

/// A warning lamp: its lit sprite (lens plus glow) fades in over the dark lens
/// that is already part of the frame art.
class _Lamp extends SpriteComponent with HasGameReference<CockpitGame> {
  _Lamp(Sprite sprite, Offset center, this._level)
      : super(
          sprite: sprite,
          position: Vector2(center.dx, center.dy),
          size: Vector2.all(CockpitLayout.lampSpriteSize),
          anchor: Anchor.center,
          priority: 6,
        ) {
    opacity = 0;
  }

  final double Function(CockpitSnapshot, double) _level;
  double _t = 0;
  double _shown = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _shown = _ease(_shown, _level(game.snapshot, _t).clamp(0.0, 1.0).toDouble(), dt, 14);
    opacity = _shown;
  }
}

/// State drawn over a baked-in brass button: dimmed when nothing to do, a pulsing
/// ring when the gauge is in the red, and a flash on press.
class _ButtonOverlay extends PositionComponent with HasGameReference<CockpitGame> {
  _ButtonOverlay(Offset center, this._read)
      : super(
          position: Vector2(center.dx, center.dy),
          size: Vector2.all(CockpitLayout.buttonHitRadius * 2),
          anchor: Anchor.center,
          priority: 7,
        );

  final CockpitButtonState Function(CockpitSnapshot) _read;
  double _t = 0;
  double _flash = 0;

  void flash() => _flash = 1;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flash = math.max(0.0, _flash - dt * 3.5);
  }

  @override
  void render(Canvas canvas) {
    final s = game.snapshot;
    final state = _read(s);
    final c = Offset(size.x / 2, size.y / 2);
    if (state == CockpitButtonState.disabled) {
      canvas.drawCircle(c, 62, Paint()..color = const Color(0x8010181A));
    } else if (state == CockpitButtonState.urgent) {
      final a = s.reduceMotion ? 0.75 : 0.4 + 0.35 * math.sin(_t * 6);
      canvas.drawCircle(
        c,
        61,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Color.fromRGBO(255, 170, 60, a),
      );
    }
    if (_flash > 0) {
      canvas.drawCircle(
        c,
        56,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = Color.fromRGBO(255, 235, 190, _flash * 0.45),
      );
    }
  }
}

/// The helm. Turns when you steer and shudders while a hazard is live.
class _Wheel extends SpriteComponent with HasGameReference<CockpitGame> {
  _Wheel(Sprite sprite)
      : super(
          sprite: sprite,
          position: Vector2(CockpitLayout.wheelCenter.dx, CockpitLayout.wheelCenter.dy),
          size: Vector2.all(CockpitLayout.wheelSpriteSize),
          anchor: Anchor.center,
          priority: 8,
        );

  double _target = 0;
  double _shown = 0;
  double _dir = 1;
  double _t = 0;

  void spin() {
    _target += _dir * 80 * math.pi / 180;
    _dir = -_dir;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _shown = _ease(_shown, _target, dt, 6);
    final s = game.snapshot;
    final shudder = s.reduceMotion ? 0.0 : math.sin(_t * 9) * 0.012 * math.min(s.threat, 10.0) / 10;
    angle = _shown + shudder;
  }
}
