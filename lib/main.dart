import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'engine/game_controller.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GodspeedGinnyApp());
}

class GodspeedGinnyApp extends StatefulWidget {
  const GodspeedGinnyApp({super.key});

  @override
  State<GodspeedGinnyApp> createState() => _GodspeedGinnyAppState();
}

class _GodspeedGinnyAppState extends State<GodspeedGinnyApp> {
  late final GameController _controller;
  late final ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _theme = AppTheme.build();
    _controller = GameController()..boot();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Godspeed Ginny',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,
      theme: _theme,
      home: Title(
        title: 'Godspeed Ginny',
        color: AppColors.ink,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => HomeShell(controller: _controller),
        ),
      ),
    );
  }
}
