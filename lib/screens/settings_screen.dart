import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final S = controller.strings;
    final menu = Map<String, dynamic>.from(S['menu'] as Map);

    return ListView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Text(
          (menu['settingsTitle'] as String).toUpperCase(),
          style: AppTheme.mastTitleCompact,
        ),
        const SizedBox(height: 18),
        ChartButton(
          label: S['telemetryToggle'] as String,
          hint: controller.showTelemetry ? 'Open' : 'Closed',
          wide: true,
          onPressed: controller.toggleTelemetry,
        ),
        const SizedBox(height: 10),
        ChartButton(
          label: S['wipe'] as String,
          hint: S['wipeConfirm'] as String,
          wide: true,
          hot: true,
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
            if (ok == true) await controller.resetCareer();
          },
        ),
        const SizedBox(height: 22),
        ChartButton(
          label: menu['back'] as String,
          wide: true,
          onPressed: controller.openTitle,
        ),
      ],
    );
  }
}
