import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../content/models.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/gauges_bar.dart';
import '../widgets/play_card_view.dart';
import '../widgets/telegram_view.dart';

class NodeScreen extends StatelessWidget {
  const NodeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final r = g.run!;
    final n = g.nodes[r.node]!;
    final S = controller.strings;
    final nodeS = Map<String, dynamic>.from(S['node'] as Map);
    final waiting = r.awaitingContinue;
    final cargo = g.cargo[r.cargo]!;

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

    final beatLabel = r.beat == 1
        ? fill(nodeS['beatsLeft'] as String, {'n': r.beat})
        : fill(nodeS['beatsLeftPlural'] as String, {'n': r.beat});

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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GaugesBar(game: g),
        const SizedBox(height: 8),
        Text(n.name, style: AppTheme.display.copyWith(fontSize: 22)),
        Text(
          n.sub.toUpperCase(),
          style: AppTheme.mono.copyWith(
            fontSize: 14,
            letterSpacing: 1.4,
            color: AppColors.stamp,
          ),
        ),
        if (threat != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(threat, style: AppTheme.mono.copyWith(fontSize: 12)),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            ...List.generate(n.beats, (i) {
              final spent = i >= r.beat;
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: spent ? AppColors.ink.withValues(alpha: 0.25) : Colors.transparent,
                  border: Border.all(
                    color: spent ? Colors.transparent : AppColors.ink,
                    width: 2,
                  ),
                ),
              );
            }),
            Flexible(
              child: Text(
                '${beatLabel.toUpperCase()} · ${(nodeS['beatHint'] as String).toUpperCase()}',
                style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1.4),
              ),
            ),
          ],
        ),
        if (r.card != null) ...[
          const SizedBox(height: 8),
          PlayCardView(card: r.card!, strings: S),
        ],
        const SizedBox(height: 8),
        if (waiting)
          ChartButton(
            label: dig(S, 'card.continue') as String,
            wide: true,
            onPressed: controller.continueNode,
          )
        else ...[
          SectionLabel(nodeS['doSomething'] as String),
          Row(
            children: [
              Expanded(
                child: ChartButton(
                  label: nodeS['steer'] as String,
                  hint: n.selling
                      ? fill(nodeS['steerHintSelling'] as String, {
                          'b': g.cfg.steerBoilerReduce.round(),
                        })
                      : fill(nodeS['steerHint'] as String, {
                          'n': g.cfg.steerThreatReduce.round(),
                          'b': g.cfg.steerBoilerReduce.round(),
                        }),
                  onPressed: r.beat < 1 ? null : () => controller.doAction('steer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChartButton(
                  label: nodeS['wrench'] as String,
                  hint: fill(nodeS['wrenchHint'] as String, {
                    'n': g.cfg.wrenchHullReduce.round(),
                  }),
                  onPressed: r.beat < 1 ? null : () => controller.doAction('wrench'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChartButton(
                  label: nodeS['bail'] as String,
                  hint: fill(nodeS['bailHint'] as String, {
                    'n': g.cfg.bailWaterReduce.round(),
                  }),
                  onPressed: r.beat < 1 ? null : () => controller.doAction('bail'),
                ),
              ),
            ],
          ),
          SectionLabel(nodeS['orSay'] as String),
          if (here.isNotEmpty) ...[
            _ScriptSect(nodeS['scriptHere'] as String),
            ...here.map((id) => _JokeButton(controller: controller, id: id)),
          ],
          if (anywhere.isNotEmpty) ...[
            _ScriptSect(nodeS['scriptAnywhere'] as String),
            ...anywhere.map((id) => _JokeButton(controller: controller, id: id)),
          ],
          if (elsewhere.isNotEmpty) ...[
            _ScriptSect(nodeS['scriptElsewhere'] as String),
            ...elsewhere.map(
              (id) => _JokeButton(controller: controller, id: id, cold: true),
            ),
          ],
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.inkSoft),
              children: [
                TextSpan(text: '${nodeS['aboard']} '),
                ...r.pax.expand(
                  (p) => [
                    TextSpan(
                      text: g.profiles[p]!.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.water,
                      ),
                    ),
                    const TextSpan(text: ' · '),
                  ],
                ),
                TextSpan(text: '\n${nodeS['hold']} '),
                TextSpan(
                  text: cargo.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.water,
                  ),
                ),
                TextSpan(text: ice),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ScriptSect extends StatelessWidget {
  const _ScriptSect(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1.8),
      ),
    );
  }
}

class _JokeButton extends StatelessWidget {
  const _JokeButton({
    required this.controller,
    required this.id,
    this.cold = false,
  });

  final GameController controller;
  final String id;
  final bool cold;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final j = g.jokes[id]!;
    final r = g.run!;
    final times = r.used[id] ?? 0;
    final est = g.scoreJoke(j);
    final waiting = r.awaitingContinue;
    final disabled = waiting || r.beat < j.attentionCost;
    final meta = _jokeMeta(g, j, times, est);
    final border = j.risk != null
        ? AppColors.stamp
        : cold
            ? AppColors.inkSoft
            : AppColors.water;

    return Opacity(
      opacity: disabled ? 0.35 : (times > 0 ? 0.45 : (cold ? 0.72 : 1)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => controller.tellJoke(id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.chart.withValues(alpha: 0.92),
                border: Border(
                  top: const BorderSide(color: AppColors.water, width: 1.5),
                  right: const BorderSide(color: AppColors.water, width: 1.5),
                  bottom: const BorderSide(color: AppColors.water, width: 1.5),
                  left: BorderSide(color: border, width: 5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    j.title,
                    style: AppTheme.display.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta.toUpperCase(),
                    style: AppTheme.mono.copyWith(fontSize: 12, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _jokeMeta(dynamic g, Joke j, int times, int est) {
    final S = g.S as Map<String, dynamic>;
    final meta = Map<String, dynamic>.from(S['jokeMeta'] as Map);
    final cfg = g.cfg;
    final bits = <String>[];
    final cost = j.attentionCost;
    bits.add(
      cost == 1
          ? fill(meta['beats'] as String, {'n': cost})
          : fill(meta['beatsPlural'] as String, {'n': cost}),
    );
    if (times > 0) bits.add(fill(meta['told'] as String, {'n': times}));
    if (j.risk != null) bits.add(meta['risky'] as String);
    if (j.deadpan) bits.add(meta['deadpan'] as String);
    final read = est >= cfg.jokeStrongAt
        ? meta['readsStrong']
        : est >= cfg.jokeFairAt
            ? meta['readsFair']
            : meta['readsFlat'];
    bits.add(read as String);
    return '${j.flavors.join(' / ')} · ${bits.join(' · ')}';
  }
}
