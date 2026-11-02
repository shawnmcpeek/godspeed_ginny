import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../flame/river_scene.dart';
import '../theme/app_theme.dart';
import 'branch_screen.dart';
import 'choice_screen.dart';
import 'credits_screen.dart';
import 'node_screen.dart';
import 'office_screen.dart';
import 'settings_screen.dart';
import 'settle_screen.dart';
import 'telemetry_panel.dart';
import 'title_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.loading) {
      return const Scaffold(
        backgroundColor: AppColors.chart,
        body: Center(child: CircularProgressIndicator(color: AppColors.water)),
      );
    }
    if (c.loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.chart,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              c.loadError!,
              style: const TextStyle(color: AppColors.stamp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final g = c.g;
    final S = c.strings;
    final menu = Map<String, dynamic>.from(S['menu'] as Map);
    final mastTitle = (S['mastTitle'] as List).cast<String>();
    final playing = c.shell == AppShell.play &&
        g.run != null &&
        (g.screen == 'node' || g.screen == 'branch' || g.screen == 'choice') &&
        !c.showTelemetry;
    final showPlayFooter = c.shell == AppShell.play && !c.showTelemetry;
    final career = fill(S['career'] as String, {
      'runs': g.career.runs,
      'purse': g.formatPurse(g.career.purse),
      'best': g.career.best.round(),
      'extra': g.career.leopardOut
          ? ' · ${(S['office'] as Map)['leopardAtLarge']}'
          : '',
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
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.shellPadH),
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
                              child: c.showTelemetry && c.shell == AppShell.settings
                                  ? _settingsTelemetry(c, menu)
                                  : _shellBody(c),
                            ),
                            if (showPlayFooter)
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
                                        style: AppTheme.menuMeta,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: c.openTitle,
                                      child: Text(
                                        menu['toTitle'] as String,
                                        style: AppTheme.menuMeta.copyWith(
                                          color: AppColors.stamp,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w700,
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

  Widget _settingsTelemetry(GameController c, Map<String, dynamic> menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              if (c.showTelemetry) c.toggleTelemetry();
            },
            child: Text(
              menu['back'] as String,
              style: AppTheme.menuMeta.copyWith(
                color: AppColors.stamp,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(child: TelemetryPanel(controller: c)),
      ],
    );
  }

  Widget _shellBody(GameController c) {
    switch (c.shell) {
      case AppShell.title:
        return TitleScreen(controller: c);
      case AppShell.settings:
        return SettingsScreen(controller: c);
      case AppShell.credits:
        return CreditsScreen(controller: c);
      case AppShell.play:
        return _playScreen(c);
    }
  }

  Widget _playScreen(GameController c) {
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
    final metaStyle = compact ? AppTheme.mastMetaCompact : AppTheme.mastMeta;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: compact ? 8 : 16, bottom: compact ? 8 : 12),
      margin: EdgeInsets.only(bottom: compact ? 8 : 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.water, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.join('\n').toUpperCase(),
            style: compact ? AppTheme.mastTitleCompact : AppTheme.mastTitle,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: metaStyle,
              children: [
                TextSpan(text: '${company.toUpperCase()}  ·  '),
                TextSpan(
                  text: tag.toUpperCase(),
                  style: metaStyle.copyWith(
                    color: AppColors.stamp,
                    fontWeight: FontWeight.w700,
                  ),
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
