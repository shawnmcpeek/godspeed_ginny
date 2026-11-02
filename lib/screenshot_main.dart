import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/legacy.dart';

import 'engine/game_controller.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

/// Phone frame used for Play Store phoneScreenshots (portrait).
const double kShotWidth = 1080;
const double kShotHeight = 1920;

/// Linux entrypoint: `flutter run -d linux -t lib/screenshot_main.dart`
/// Writes PNGs under fastlane metadata + Asc screenshots folders, then exits.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  await windowManager.ensureInitialized();
  const size = ui.Size(kShotWidth, kShotHeight);
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: size,
      minimumSize: size,
      maximumSize: size,
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Godspeed Ginny — screenshots',
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  runApp(const ScreenshotApp());
}

class ScreenshotApp extends StatefulWidget {
  const ScreenshotApp({super.key});

  @override
  State<ScreenshotApp> createState() => _ScreenshotAppState();
}

class _ScreenshotAppState extends State<ScreenshotApp> {
  final GlobalKey _shotKey = GlobalKey();
  late final GameController _controller;
  late final ThemeData _theme;
  String _status = 'Booting…';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _theme = AppTheme.build();
    _controller = GameController();
    _controller.boot().then((_) {
      if (!mounted) return;
      if (_controller.loadError != null) {
        setState(() => _status = 'Load error: ${_controller.loadError}');
        return;
      }
      _runCapture();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Directory _repoRoot() {
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
      dir = dir.parent;
    }
    return Directory.current;
  }

  Future<void> _settleFrames() async {
    for (var i = 0; i < 24; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      if (!mounted) return;
      setState(() {});
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _capture(String filename) async {
    await _settleFrames();
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Failed to encode $filename');
    }

    final root = _repoRoot();
    final targets = <File>[
      File(
        '${root.path}/fastlane/metadata/android/en-US/images/phoneScreenshots/$filename',
      ),
      File('${root.path}/fastlane/screenshots/en-US/$filename'),
    ];
    for (final file in targets) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
    setState(() => _status = 'Wrote $filename');
  }

  Future<void> _runCapture() async {
    if (_running) return;
    _running = true;
    final c = _controller;
    try {
      setState(() => _status = 'Title');
      c.openTitle();
      await _capture('01_title.png');

      setState(() => _status = 'Office');
      c.openPlay();
      await _capture('02_office.png');

      setState(() => _status = 'Passage');
      final cargoId = c.g.content.cargo.first.id;
      await c.startRun(cargoId);
      // Prefer a real stretch beat for the passage shot.
      final nodeIdx = c.g.run!.plan.indexWhere(
        (s) => s['kind'] == 'node' && (s['id'] != null || s['pool'] != null),
      );
      if (nodeIdx >= 0) {
        c.g.run!.step = nodeIdx;
        c.g.advanceToCurrent();
        c.refresh();
      }
      await _capture('03_passage.png');

      setState(() => _status = 'Fork');
      final branchIdx =
          c.g.run!.plan.indexWhere((s) => s['kind'] == 'branch');
      if (branchIdx < 0) {
        throw StateError('No branch step in run plan');
      }
      c.g.run!.step = branchIdx;
      c.g.advanceToCurrent();
      c.refresh();
      await _capture('04_fork.png');

      setState(() => _status = 'Choice');
      final choiceIdx =
          c.g.run!.plan.indexWhere((s) => s['kind'] == 'choice');
      if (choiceIdx < 0) {
        throw StateError('No choice step in run plan');
      }
      c.g.run!.step = choiceIdx;
      c.g.advanceToCurrent();
      c.refresh();
      await _capture('05_choice.png');

      setState(() => _status = 'Settle');
      c.g.settleResult = c.g.computeSettle();
      c.g.screen = 'settle';
      c.refresh();
      await _capture('06_settle.png');

      setState(() => _status = 'Done — exiting');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      exit(0);
    } catch (e, st) {
      setState(() => _status = 'Error: $e');
      stderr.writeln(e);
      stderr.writeln(st);
      await Future<void>.delayed(const Duration(seconds: 3));
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: RepaintBoundary(
                key: _shotKey,
                child: SizedBox(
                  width: kShotWidth,
                  height: kShotHeight,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      size: Size(kShotWidth, kShotHeight),
                      devicePixelRatio: 1,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: ColoredBox(
                      color: AppColors.chart,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) =>
                            HomeShell(controller: _controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                _status,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
