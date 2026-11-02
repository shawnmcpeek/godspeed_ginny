import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../theme/branding.dart';
import '../widgets/chart_button.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final S = controller.strings;
    final menu = Map<String, dynamic>.from(S['menu'] as Map);
    final g = controller.g;
    final careerLine = controller.hasCareerHistory
        ? fill(S['career'] as String, {
            'runs': g.career.runs,
            'purse': g.formatPurse(g.career.purse),
            'best': g.career.best.round(),
            'extra': '',
          })
        : menu['careerEmpty'] as String;

    final primaryLabel = controller.hasActiveRun
        ? menu['resume'] as String
        : menu['castOff'] as String;
    final primaryHint = controller.hasActiveRun
        ? menu['resumeHint'] as String
        : menu['castOffHint'] as String;

    return ListView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: Branding.titleHeroWidthFactor,
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
        ),
        const SizedBox(height: AppTheme.menuSectionGap),
        Text(
          (menu['titleTag'] as String).toUpperCase(),
          style: AppTheme.menuTag,
        ),
        const SizedBox(height: 6),
        Text(careerLine, style: AppTheme.menuMeta),
        const SizedBox(height: AppTheme.menuSectionGap),
        ChartButton(
          label: primaryLabel,
          hint: primaryHint,
          wide: true,
          hot: true,
          onPressed: controller.openPlay,
        ),
        const SizedBox(height: AppTheme.menuItemGap),
        ChartButton(
          label: menu['settings'] as String,
          hint: menu['settingsHint'] as String,
          wide: true,
          onPressed: controller.openSettings,
        ),
        const SizedBox(height: AppTheme.menuItemGap),
        ChartButton(
          label: menu['credits'] as String,
          hint: menu['creditsHint'] as String,
          wide: true,
          onPressed: controller.openCredits,
        ),
      ],
    );
  }
}
