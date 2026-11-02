import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/loader.dart';
import '../engine/game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_button.dart';
import '../widgets/telegram_view.dart';

class TelemetryPanel extends StatefulWidget {
  const TelemetryPanel({super.key, required this.controller});

  final GameController controller;

  @override
  State<TelemetryPanel> createState() => _TelemetryPanelState();
}

class _TelemetryPanelState extends State<TelemetryPanel> {
  String? status;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final T = Map<String, dynamic>.from(c.strings['telemetry'] as Map);
    final telem = c.telemetry!;

    if (telem.runs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(T['title'] as String),
          Text(T['empty'] as String, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    final jokes = telem.jokeBoard();
    final nodes = telem.nodeReport();
    final split = telem.stationSplit();
    final pct = Map<String, dynamic>.from(split['pct'] as Map);

    return ListView(
      children: [
        SectionLabel(T['title'] as String),
        Text(
          fill(T['runs'] as String, {'n': telem.runs.length, 'keep': c.g.cfg.telemetryKeep}),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SectionLabel(T['jokes'] as String),
        Text((T['jokeCols'] as String).toUpperCase(), style: AppTheme.mono.copyWith(fontSize: 12)),
        ...jokes.map(
          (j) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('${j['id']}', style: AppTheme.mono.copyWith(fontSize: 13))),
                Text(
                  '${j['told']} · ${(j['mean'] as double).toStringAsFixed(1)} · ${(j['offPct'] as double).round()}%',
                  style: AppTheme.mono.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        SectionLabel(T['nodes'] as String),
        Text((T['nodeCols'] as String).toUpperCase(), style: AppTheme.mono.copyWith(fontSize: 12)),
        ...nodes.map(
          (n) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text('${n['id']}', style: AppTheme.mono.copyWith(fontSize: 13))),
                Text(
                  '${(n['sat'] as double).toStringAsFixed(1)} · ${(n['threat'] as double).toStringAsFixed(1)} · ${n['crises']}',
                  style: AppTheme.mono.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        SectionLabel(T['stations'] as String),
        Text(
          'patter ${pct['patter']}% · steer ${pct['steer']}% · wrench ${pct['wrench']}% · bail ${pct['bail']}%',
          style: AppTheme.mono.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        ChartButton(
          label: T['export'] as String,
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: telem.exportJson()));
              setState(() => status = T['copied'] as String);
            } catch (_) {
              setState(() => status = T['copyFail'] as String);
            }
          },
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(status!, style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    );
  }
}
