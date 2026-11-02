import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/gauges_bar.dart';
import '../widgets/play_card_view.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return controller.g.choiceId == 'boulder'
        ? _BoulderChoice(controller: controller)
        : _DucksChoice(controller: controller);
  }
}

class _DucksChoice extends StatelessWidget {
  const _DucksChoice({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final d = Map<String, dynamic>.from(controller.strings['ducks'] as Map);
    final done = g.choiceDone;
    final title = g.run!.goose ? d['titleGoose'] as String : d['title'] as String;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GaugesBar(game: g),
        const SizedBox(height: 8),
        Text(title, style: AppTheme.display.copyWith(fontSize: 22)),
        Text(
          (d['sub'] as String).toUpperCase(),
          style: AppTheme.mono.copyWith(fontSize: 14, letterSpacing: 1.4, color: AppColors.stamp),
        ),
        const SizedBox(height: 8),
        if (done && g.run?.card != null)
          PlayCardView(card: g.run!.card!, strings: controller.strings)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.chart.withValues(alpha: 0.94),
              border: Border.all(color: AppColors.water, width: 1.5),
            ),
            child: Text(d['note'] as String, style: Theme.of(context).textTheme.bodyMedium),
          ),
        const SizedBox(height: 8),
        if (done)
          ChartButton(
            label: d['carryOn'] as String,
            wide: true,
            onPressed: controller.continueAfterChoice,
          )
        else
          Row(
            children: [
              Expanded(
                child: ChartButton(
                  label: d['fast'] as String,
                  hint: d['fastHint'] as String,
                  onPressed: () => controller.chooseDucks('fast'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChartButton(
                  label: d['funny'] as String,
                  hint: d['funnyHint'] as String,
                  hot: true,
                  onPressed: () => controller.chooseDucks('funny'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BoulderChoice extends StatelessWidget {
  const _BoulderChoice({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final b = Map<String, dynamic>.from(controller.strings['boulder'] as Map);
    final done = g.choiceDone;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GaugesBar(game: g),
        const SizedBox(height: 8),
        Text(b['title'] as String, style: AppTheme.display.copyWith(fontSize: 22)),
        Text(
          (b['sub'] as String).toUpperCase(),
          style: AppTheme.mono.copyWith(fontSize: 14, letterSpacing: 1.4, color: AppColors.stamp),
        ),
        const SizedBox(height: 8),
        if (done && g.run?.card != null)
          PlayCardView(card: g.run!.card!, strings: controller.strings)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.chart.withValues(alpha: 0.94),
              border: Border.all(color: AppColors.water, width: 1.5),
            ),
            child: Text(b['note'] as String, style: Theme.of(context).textTheme.bodyMedium),
          ),
        const SizedBox(height: 8),
        if (done)
          ChartButton(
            label: b['carryOn'] as String,
            wide: true,
            onPressed: controller.continueAfterChoice,
          )
        else
          Row(
            children: [
              Expanded(
                child: ChartButton(
                  label: b['left'] as String,
                  hint: b['leftHint'] as String,
                  onPressed: () => controller.chooseBoulder('left'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChartButton(
                  label: b['right'] as String,
                  hint: b['rightHint'] as String,
                  onPressed: () => controller.chooseBoulder('right'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
