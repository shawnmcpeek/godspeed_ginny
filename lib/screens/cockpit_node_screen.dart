import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/loader.dart';
import '../content/models.dart';
import '../engine/game_controller.dart';
import '../flame/cockpit/cockpit_game.dart';
import '../flame/cockpit/cockpit_layout.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/play_card_view.dart';
import 'branch_screen.dart';
import 'choice_screen.dart';
import 'node_screen.dart' show JokeButton, ScriptSect;

/// Which scene art to show for a stretch. Everything uses the placeholder for now;
/// this is where per-region kits and hero scenes get chosen (by node tags or type).
String cockpitSceneFor(NodeDef n) => 'default';

/// The Flame cockpit itself. HomeShell keeps this mounted (offstage when not in use)
/// so the game and its images load once and survive screen changes.
class CockpitStage extends StatelessWidget {
  const CockpitStage({super.key, required this.game});

  final CockpitGame game;

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: game,
      loadingBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, error) => const SizedBox.shrink(),
    );
  }
}

/// Everything Flutter draws on top of the cockpit: tap targets over the wheel and
/// dash buttons, and the window content. On a stretch that is the heading, card and
/// joke tabs; on branch and choice screens it is that screen inside one panel.
///
/// It also feeds the real game state to [game] as a [CockpitSnapshot] each build.
class CockpitNodeOverlay extends StatelessWidget {
  const CockpitNodeOverlay({
    super.key,
    required this.controller,
    required this.game,
  });

  final GameController controller;
  final CockpitGame game;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final r = g.run!;
    final n = g.nodes[r.node]!;
    final S = controller.strings;
    final nodeS = Map<String, dynamic>.from(S['node'] as Map);
    final menu = Map<String, dynamic>.from(S['menu'] as Map);
    final cargo = g.cargo[r.cargo]!;

    final max = g.cfg.gaugeDisplayMax;
    double frac(double v) => (v / max).clamp(0.0, 1.0).toDouble();
    final waiting = r.awaitingContinue;
    final isNode = g.screen == 'node';
    final canAct = isNode && !waiting && r.beat >= 1;
    final repairOn = canAct && r.hull > 0;
    final bailOn = canAct && r.water > 0;

    game.snapshot = CockpitSnapshot(
      boiler: frac(r.boiler),
      water: frac(r.water),
      hull: frac(r.hull),
      room: frac(r.sat),
      beatsLeft: r.beat,
      beatsTotal: n.beats,
      threat: r.threat,
      reduceMotion: MediaQuery.of(context).disableAnimations,
      repair: !repairOn
          ? CockpitButtonState.disabled
          : (r.hull >= 35 ? CockpitButtonState.urgent : CockpitButtonState.idle),
      bail: !bailOn
          ? CockpitButtonState.disabled
          : (r.water >= 80 ? CockpitButtonState.urgent : CockpitButtonState.idle),
    );
    unawaited(game.showScene(cockpitSceneFor(n)));

    String? threat;
    if (n.selling) {
      threat = nodeS['sellingThreat'] as String;
    } else if (n.threatLabel != null) {
      threat = fill(
        n.salvage ? nodeS['threatSalvage'] as String : nodeS['threatClear'] as String,
        {
          'label': n.threatLabel!.toUpperCase(),
          'threat': r.threat.round(),
          'max': g.cfg.salvageThreatMax.round(),
        },
      );
    }

    final here = <String>[];
    final anywhere = <String>[];
    final elsewhere = <String>[];
    for (final id in r.hand) {
      final j = g.jokes[id]!;
      if (g.jokeOnTopic(j)) {
        here.add(id);
      } else if (j.at.isEmpty) {
        anywhere.add(id);
      } else {
        elsewhere.add(id);
      }
    }
    int byScore(String a, String b) => g.scoreJoke(g.jokes[b]!) - g.scoreJoke(g.jokes[a]!);
    here.sort(byScore);
    anywhere.sort(byScore);
    elsewhere.sort(byScore);

    final ice = cargo.hasEffect('melt')
        ? fill(nodeS['iceLeft'] as String, {'pct': r.cargoHealth.round()})
        : '';
    final aboard = r.pax.map((p) => g.profiles[p]!.name).join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final geom = CockpitGeometry.forSize(size.width, size.height);
        final land = geom.landscape;
        final screen = Offset.zero & size;
        final pad = MediaQuery.of(context).padding;

        // Tap target: the art's radius, but never smaller than a thumb-friendly 28.
        Rect circle(Offset designCenter, double designRadius) => Rect.fromCircle(
              center: geom.toScreen(designCenter),
              radius: math.max(designRadius * geom.k, 28),
            ).intersect(screen);

        final windowTop = geom.windowTop;
        // Landscape has little room above the bow, so branch and choice screens
        // borrow the strip down to the dash panel.
        final windowBottom = (land && !isNode) ? geom.toScreenY(1405) : geom.windowBottom;
        final left = math.max(geom.windowSideInset, pad.left + 8);
        final right = math.max(geom.windowSideInset, pad.right + 8);

        final jokeLists = <Widget>[
          if (waiting)
            ChartButton(
              label: dig(S, 'card.continue') as String,
              wide: true,
              fill: AppColors.chart.withValues(alpha: 0.94),
              onPressed: controller.continueNode,
            )
          else ...[
            if (here.isNotEmpty) ...[
              ScriptSect(nodeS['scriptHere'] as String),
              ...here.map((id) => JokeButton(controller: controller, id: id)),
            ],
            if (anywhere.isNotEmpty) ...[
              ScriptSect(nodeS['scriptAnywhere'] as String),
              ...anywhere.map((id) => JokeButton(controller: controller, id: id)),
            ],
            if (elsewhere.isNotEmpty) ...[
              ScriptSect(nodeS['scriptElsewhere'] as String),
              ...elsewhere.map(
                (id) => JokeButton(controller: controller, id: id, cold: true),
              ),
            ],
          ],
        ];
        final manifest = _Manifest(
          text: '${nodeS['aboard']} $aboard\n${nodeS['hold']} ${cargo.name}$ice',
        );
        final heading = _Heading(name: n.name, sub: n.sub, threat: threat);
        final cardWidgets = <Widget>[
          if (r.card != null) ...[
            PlayCardView(card: r.card!, strings: S),
            const SizedBox(height: 6),
          ],
        ];

        Widget windowContent;
        if (!isNode) {
          windowContent = _Panel(
            child: g.screen == 'branch'
                ? BranchScreen(controller: controller, showGauges: false)
                : ChoiceScreen(controller: controller, showGauges: false),
          );
        } else if (land) {
          // Two columns: what is happening on the left, what you can do on the right.
          windowContent = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading,
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [...cardWidgets, if (!waiting) manifest],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: jokeLists,
                ),
              ),
            ],
          );
        } else {
          windowContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    ...cardWidgets,
                    ...jokeLists,
                    if (!waiting) ...[const SizedBox(height: 6), manifest],
                  ],
                ),
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Window content: stretch heading, card, joke tabs.
            Positioned(
              left: left,
              right: right,
              top: windowTop,
              height: (windowBottom - windowTop).clamp(0.0, size.height).toDouble(),
              child: windowContent,
            ),

            // Tap targets over the baked-in art. Steer is the wheel.
            _tap(
              rect: circle(CockpitLayout.wheelCenter, CockpitLayout.wheelHitRadius),
              label: nodeS['steer'] as String,
              onTap: canAct
                  ? () {
                      HapticFeedback.selectionClick();
                      game.steerWheel();
                      controller.doAction('steer');
                    }
                  : null,
            ),
            _tap(
              rect: circle(CockpitLayout.repairCenter, CockpitLayout.buttonHitRadius),
              label: 'Repair, spends one beat',
              onTap: repairOn
                  ? () {
                      HapticFeedback.selectionClick();
                      game.pressButton(repair: true);
                      controller.doAction('wrench');
                    }
                  : null,
            ),
            _tap(
              rect: circle(CockpitLayout.bailCenter, CockpitLayout.buttonHitRadius),
              label: 'Bail, spends one beat',
              onTap: bailOn
                  ? () {
                      HapticFeedback.selectionClick();
                      game.pressButton(repair: false);
                      controller.doAction('bail');
                    }
                  : null,
            ),

            // Way back to the title screen (the old footer is gone in cockpit view).
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              right: 8,
              child: IconButton(
                tooltip: menu['toTitle'] as String,
                onPressed: controller.openTitle,
                icon: const Icon(Icons.menu, color: AppColors.chart),
                style: IconButton.styleFrom(backgroundColor: const Color(0x66141C18)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tap({required Rect rect, required String label, required VoidCallback? onTap}) {
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// One translucent dialog panel behind a whole screen (branch and choice screens).
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.93),
        border: Border.all(color: AppColors.water, width: 1.5),
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.name, required this.sub, required this.threat});

  final String name;
  final String sub;
  final String? threat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.chart.withValues(alpha: 0.9),
        border: Border.all(color: AppColors.water, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppTheme.display.copyWith(fontSize: 20)),
          Text(
            sub.toUpperCase(),
            style: AppTheme.mono.copyWith(fontSize: 11, letterSpacing: 1.2, color: AppColors.stamp),
          ),
          if (threat != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(threat!, style: AppTheme.mono.copyWith(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _Manifest extends StatelessWidget {
  const _Manifest({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppColors.chart.withValues(alpha: 0.85),
      child: Text(
        text,
        style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.inkSoft),
      ),
    );
  }
}
