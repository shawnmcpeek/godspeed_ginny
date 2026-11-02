import 'package:flutter/material.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/telegram_view.dart';

class SettleScreen extends StatelessWidget {
  const SettleScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.g;
    final t = g.settleResult!;
    final s = Map<String, dynamic>.from(controller.strings['settle'] as Map);

    Widget row(String label, int value, {bool neg = false}) {
      final showNeg = neg || value < 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.ink))),
            Text(
              '${showNeg ? '−' : ''}£${value.abs()}',
              style: AppTheme.mono.copyWith(
                fontSize: 13,
                color: showNeg ? AppColors.stamp : AppColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Text(s['title'] as String, style: AppTheme.display.copyWith(fontSize: 22)),
        Text(
          (s['sub'] as String).toUpperCase(),
          style: AppTheme.mono.copyWith(fontSize: 14, letterSpacing: 1.4, color: AppColors.stamp),
        ),
        const SizedBox(height: 8),
        Text(s['note'] as String, style: Theme.of(context).textTheme.bodyMedium),
        SectionLabel(s['sect'] as String),
        row(s['fares'] as String, t.base),
        Container(height: 1, color: AppColors.chartDeep),
        row(s['tips'] as String, t.tips),
        Container(height: 1, color: AppColors.chartDeep),
        row(t.cargoName, t.cargoPay, neg: t.cargoPay < 0),
        if (t.salvage != 0) ...[
          Container(height: 1, color: AppColors.chartDeep),
          row(s['salvage'] as String, t.salvage),
        ],
        if (t.refunds != 0) ...[
          Container(height: 1, color: AppColors.chartDeep),
          row(fill(s['refunds'] as String, {'n': t.refunds}), t.refundCost, neg: true),
        ],
        if (t.repairs != 0) ...[
          Container(height: 1, color: AppColors.chartDeep),
          row(s['repairs'] as String, t.repairs, neg: true),
        ],
        const SizedBox(height: 4),
        Container(height: 2, color: AppColors.ink),
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s['net'] as String,
                  style: AppTheme.mono.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${t.net < 0 ? '−' : ''}£${t.net.abs()}',
                style: AppTheme.mono.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.net < 0 ? AppColors.stamp : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        if (t.why.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(t.why, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        TelegramView(
          header: s['incomingHeader'] as String,
          body: t.wire,
          signoff: g.content.telegrams.office.signoff,
        ),
        Text(
          fill(s['summary'] as String, {
            'sat': g.run!.sat.round(),
            'told': g.run!.told,
            'leopard': g.career.leopardOut ? s['leopard'] as String : '',
          }),
          style: AppTheme.mono.copyWith(fontSize: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        ChartButton(
          label: s['again'] as String,
          wide: true,
          onPressed: controller.returnToOffice,
        ),
      ],
    );
  }
}
