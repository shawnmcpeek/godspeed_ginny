import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../flame/river_scene.dart';
import '../theme/app_theme.dart';
import '../theme/branding.dart';
import 'branch_screen.dart';
import 'choice_screen.dart';
import 'node_screen.dart';
import 'office_screen.dart';
import 'settle_screen.dart';
import 'telemetry_panel.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final GameController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final RiverScene _river;

  @override
  void initState() {
    super.initState();
    _river = RiverScene();
    widget.controller.addListener(_syncRiver);
    _syncRiver();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncRiver);
      widget.controller.addListener(_syncRiver);
      _syncRiver();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncRiver);
    super.dispose();
  }

  void _syncRiver() {
    final g = widget.controller.game;
    final r = g?.run;
    final playing = r != null &&
        (g!.screen == 'node' || g.screen == 'branch' || g.screen == 'choice') &&
        !widget.controller.showTelemetry;
    _river.syncGauges(
      boiler: r?.boiler ?? 15,
      water: r?.water ?? 10,
      hull: r?.hull ?? 0,
      threat: r?.threat ?? 0,
      playing: playing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFB8BEDB),
        body: Center(
          child: Image.asset(
            Branding.splash,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }
    if (c.loadError != null || c.game == null) {
      return Scaffold(
        backgroundColor: AppColors.chart,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load content.\n${c.loadError ?? ''}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final g = c.g;
    final S = c.strings;
    final office = Map<String, dynamic>.from(S['office'] as Map);
    final mastTitle = (S['mastTitle'] as List).cast<String>();
    final playing = g.run != null &&
        (g.screen == 'node' || g.screen == 'branch' || g.screen == 'choice') &&
        !c.showTelemetry;

    final career = fill(S['career'] as String, {
      'runs': g.career.runs,
      'purse': g.formatPurse(g.career.purse),
      'best': g.career.best.round(),
      'extra': g.career.leopardOut ? ' · ${office['leopardAtLarge']}' : '',
    });

    return Scaffold(
      backgroundColor: AppColors.chart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: playing ? 0.22 : 0,
                child: GameWidget(
                  game: _river,
                  loadingBuilder: (_) => const SizedBox.shrink(),
                  errorBuilder: (_, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          ColoredBox(
            color: playing ? AppColors.chart.withValues(alpha: 0.82) : AppColors.chart,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      height: constraints.maxHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _Mast(
                              title: mastTitle,
                              company: S['mastCompany'] as String,
                              tag: S['mastTag'] as String,
                              port: S['mastPort'] as String,
                              compact: playing,
                            ),
                            Expanded(
                              child: c.showTelemetry
                                  ? TelemetryPanel(controller: c)
                                  : _screenFor(c),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.chartDeep)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      career,
                                      style: AppTheme.mono.copyWith(
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: c.toggleTelemetry,
                                    child: Text(
                                      S['telemetryToggle'] as String,
                                      style: AppTheme.mono.copyWith(
                                        fontSize: 12,
                                        color: AppColors.stamp,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.chart,
                                          content: Text(S['wipeConfirm'] as String),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Keep'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: Text(
                                                S['wipe'] as String,
                                                style: const TextStyle(color: AppColors.stamp),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) await c.resetCareer();
                                    },
                                    child: Text(
                                      S['wipe'] as String,
                                      style: AppTheme.mono.copyWith(
                                        fontSize: 12,
                                        color: AppColors.stamp,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenFor(GameController c) {
    switch (c.g.screen) {
      case 'branch':
        return BranchScreen(controller: c);
      case 'choice':
        return ChoiceScreen(controller: c);
      case 'settle':
        return SettleScreen(controller: c);
      case 'node':
        return NodeScreen(controller: c);
      case 'office':
      default:
        return OfficeScreen(controller: c);
    }
  }
}

class _Mast extends StatelessWidget {
  const _Mast({
    required this.title,
    required this.company,
    required this.tag,
    required this.port,
    required this.compact,
  });

  final List<String> title;
  final String company;
  final String tag;
  final String port;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: compact ? 10 : 28, bottom: compact ? 8 : 12),
      margin: EdgeInsets.only(bottom: compact ? 8 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.water, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.join('\n').toUpperCase(),
            style: AppTheme.display.copyWith(
              fontSize: compact ? 22 : 40,
              letterSpacing: 3.2,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTheme.mono.copyWith(
                fontSize: 13,
                letterSpacing: 2.4,
                color: AppColors.inkSoft,
              ),
              children: [
                TextSpan(text: '${company.toUpperCase()}  ·  '),
                TextSpan(
                  text: tag.toUpperCase(),
                  style: const TextStyle(color: AppColors.stamp, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '  ·  ${port.toUpperCase()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
