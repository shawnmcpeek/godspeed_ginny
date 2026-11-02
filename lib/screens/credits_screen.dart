import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final menu = Map<String, dynamic>.from(controller.strings['menu'] as Map);

    return ListView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Text(
          (menu['creditsTitle'] as String).toUpperCase(),
          style: AppTheme.mastTitleCompact,
        ),
        const SizedBox(height: 18),
        Text(
          menu['creditsBody'] as String,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          menu['creditsSignoff'] as String,
          style: AppTheme.mono.copyWith(
            fontSize: 13,
            letterSpacing: 1.8,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 28),
        ChartButton(
          label: menu['back'] as String,
          wide: true,
          onPressed: controller.openTitle,
        ),
      ],
    );
  }
}
