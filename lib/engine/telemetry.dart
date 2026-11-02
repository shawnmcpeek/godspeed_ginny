import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/models.dart';

class Telemetry {
  Telemetry(this.config, this._prefs) {
    final raw = _prefs.getString(config.telemetryKey);
    if (raw != null) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          runs = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {
        runs = [];
      }
    }
  }

  final GameConfig config;
  final SharedPreferences _prefs;
  List<Map<String, dynamic>> runs = [];

  Future<void> commitRun(Map<String, dynamic> record) async {
    runs.add({'at': DateTime.now().millisecondsSinceEpoch, ...record});
    if (runs.length > config.telemetryKeep) {
      runs = runs.sublist(runs.length - config.telemetryKeep);
    }
    await _prefs.setString(config.telemetryKey, jsonEncode(runs));
  }

  List<Map<String, dynamic>> jokeBoard() {
    final map = <String, Map<String, dynamic>>{};
    for (final run in runs) {
      for (final j in (run['jokes'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(j as Map);
        final id = row['id'] as String;
        final cur = map.putIfAbsent(
          id,
          () => {'id': id, 'told': 0, 'scoreSum': 0.0, 'off': 0},
        );
        cur['told'] = (cur['told'] as int) + 1;
        cur['scoreSum'] = (cur['scoreSum'] as double) + (row['score'] as num).toDouble();
        if (row['offTopic'] == true) cur['off'] = (cur['off'] as int) + 1;
      }
    }
    final out = map.values.map((r) {
      final told = r['told'] as int;
      return {
        'id': r['id'],
        'told': told,
        'mean': told == 0 ? 0.0 : (r['scoreSum'] as double) / told,
        'offPct': told == 0 ? 0.0 : (100.0 * (r['off'] as int)) / told,
      };
    }).toList()
      ..sort((a, b) => (b['told'] as int).compareTo(a['told'] as int));
    return out;
  }

  List<Map<String, dynamic>> nodeReport() {
    final map = <String, Map<String, dynamic>>{};
    for (final run in runs) {
      for (final n in (run['nodes'] as List? ?? const [])) {
        final row = Map<String, dynamic>.from(n as Map);
        final id = row['id'] as String;
        final cur = map.putIfAbsent(
          id,
          () => {'id': id, 'count': 0, 'sat': 0.0, 'threat': 0.0, 'crises': 0},
        );
        cur['count'] = (cur['count'] as int) + 1;
        cur['sat'] = (cur['sat'] as double) + (row['satDelta'] as num).toDouble();
        cur['threat'] = (cur['threat'] as double) + (row['threatLeft'] as num).toDouble();
        cur['crises'] =
            (cur['crises'] as int) + ((row['crises'] as List?)?.length ?? 0);
      }
    }
    return map.values.map((r) {
      final count = r['count'] as int;
      return {
        'id': r['id'],
        'sat': count == 0 ? 0.0 : (r['sat'] as double) / count,
        'threat': count == 0 ? 0.0 : (r['threat'] as double) / count,
        'crises': r['crises'],
        'count': count,
      };
    }).toList();
  }

  Map<String, dynamic> stationSplit() {
    final totals = {'patter': 0, 'steer': 0, 'wrench': 0, 'bail': 0};
    for (final run in runs) {
      final b = Map<String, dynamic>.from(run['beatsSpent'] as Map? ?? {});
      for (final k in totals.keys) {
        totals[k] = totals[k]! + ((b[k] as num?)?.toInt() ?? 0);
      }
    }
    final sum = totals.values.fold<int>(0, (a, b) => a + b);
    final pct = <String, int>{};
    for (final k in totals.keys) {
      pct[k] = sum == 0 ? 0 : ((100 * totals[k]!) / sum).round();
    }
    return {'totals': totals, 'pct': pct, 'sum': sum};
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(runs);
}
