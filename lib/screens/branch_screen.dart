import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/gauges_bar.dart';
import '../widgets/play_card_view.dart';

class BranchScreen extends StatelessWidget {
  const BranchScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final S = controller.strings;
    final branchS = Map<String, dynamic>.from(S['branch'] as Map);
    final step = g.currentStep()!;
    final b = g.branches[step['id'] as String]!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GaugesBar(game: g),
        const SizedBox(height: 8),
        Text(branchS['title'] as String, style: AppTheme.display.copyWith(fontSize: 22)),
        Text(
          (branchS['sub'] as String).toUpperCase(),
          style: AppTheme.mono.copyWith(
            fontSize: 14,
            letterSpacing: 1.4,
            color: AppColors.stamp,
          ),
        ),
        if (g.run?.card != null) ...[
          const SizedBox(height: 8),
          PlayCardView(card: g.run!.card!, strings: S),
        ],
        const SizedBox(height: 8),
        Text(b.prompt, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        ...g.offeredEdges(b).map((o) {
          final note = g.career.notes[o.id];
          return ChartCardButton(
            title: o.charted.label,
            claim: o.charted.claim,
            claimPrefix: branchS['chartPrefix'] as String,
            annotation: note,
            onPressed: () => controller.chooseBranch(o.id),
          );
        }),
      ],
    );
  }
}
