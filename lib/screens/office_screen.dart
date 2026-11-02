import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../theme/branding.dart';
import '../widgets/chart_button.dart';
import '../widgets/telegram_view.dart';

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final S = controller.strings;
    final office = Map<String, dynamic>.from(S['office'] as Map);
    final t = g.officeTelegram();
    final notes = g.career.notes.entries.toList();
    final salvage = g.career.salvage
        .map((id) => g.jokes[id]?.title)
        .whereType<String>()
        .toList();

    return ListView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                Branding.titleArt,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        TelegramView(
          header: t['header']!,
          body: t['body']!,
          signoff: t['signoff'],
        ),
        Text(office['note'] as String, style: Theme.of(context).textTheme.bodyMedium),
        SectionLabel(office['manifest'] as String),
        ...g.content.cargo.map(
          (c) => ChartCardButton(
            title: c.name,
            subtitle: fill(office['pays'] as String, {'pay': c.pay}),
            annotation: c.note,
            onPressed: () => controller.startRun(c.id),
          ),
        ),
        if (notes.isNotEmpty) ...[
          SectionLabel(office['chartSect'] as String),
          ...notes.map((e) {
            BranchEdgeLookup? edge;
            for (final b in g.content.branches) {
              for (final edgeItem in b.edges) {
                if (edgeItem.id == e.key) {
                  edge = BranchEdgeLookup(edgeItem.charted.label);
                }
              }
            }
            return ChartCardButton(
              title: edge?.label ?? e.key,
              annotation: e.value,
            );
          }),
        ],
        if (salvage.isNotEmpty) ...[
          SectionLabel(office['salvageSect'] as String),
          Text(
            salvage.join(' · '),
            style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.ink),
          ),
        ],
      ],
    );
  }
}

class BranchEdgeLookup {
  BranchEdgeLookup(this.label);
  final String label;
}
