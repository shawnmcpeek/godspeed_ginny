import 'dart:math';

import '../content/models.dart';

final _rng = Random();

double clamp(double n, double a, double b) => n < a ? a : (n > b ? b : n);

T pick<T>(List<T> arr) => arr[_rng.nextInt(arr.length)];

List<T> pickUnique<T>(List<T> arr, int n) {
  final pool = List<T>.from(arr);
  final out = <T>[];
  while (out.length < n && pool.isNotEmpty) {
    final i = _rng.nextInt(pool.length);
    out.add(pool.removeAt(i));
  }
  return out;
}

JokeVariant pickWeighted(List<JokeVariant> variants) {
  final total = variants.fold<int>(0, (s, v) => s + v.weight);
  var r = _rng.nextDouble() * total;
  for (final v in variants) {
    r -= v.weight;
    if (r <= 0) return v;
  }
  return variants.first;
}

bool chance(double p) => _rng.nextDouble() < p;

String applyTypos(String text, List<Typo> typos, List<int> range) {
  final min = range[0];
  final max = range[1];
  final n = min + _rng.nextInt(max - min + 1);
  final available = typos.where((t) => text.contains(t.from)).toList();
  final chosen = pickUnique(available, n);
  var out = text;
  for (final t in chosen) {
    out = out.replaceFirst(t.from, t.to);
  }
  return out;
}

bool condMatch(Map<String, dynamic>? cond, Map<String, dynamic> ctx) {
  if (cond == null || cond['default'] == true) return true;
  if (cond['refunds_gte'] != null &&
      (ctx['refunds'] as num) >= (cond['refunds_gte'] as num)) {
    return true;
  }
  if (cond['net_lt'] != null && (ctx['net'] as num) < (cond['net_lt'] as num)) {
    return true;
  }
  if (cond['sat_gte'] != null && (ctx['sat'] as num) >= (cond['sat_gte'] as num)) {
    return true;
  }
  if (cond['cargo_lost'] != null &&
      ctx['cargoId'] == cond['cargo_lost'] &&
      (ctx['cargoHealth'] as num) == 0) {
    return true;
  }
  return false;
}

bool explainMatch(Map<String, dynamic>? cond, Map<String, dynamic> ctx) {
  if (cond == null) return true;
  if (cond['refunds_gte'] != null &&
      !((ctx['refunds'] as num) >= (cond['refunds_gte'] as num))) {
    return false;
  }
  if (cond['falls_unsold'] != null &&
      (ctx['fallsUnsold'] == true) != (cond['falls_unsold'] == true)) {
    return false;
  }
  if (cond['nowhere'] != null && ctx['nowhere'] != cond['nowhere']) return false;
  if (cond['repairs_gte'] != null &&
      !((ctx['repairs'] as num) >= (cond['repairs_gte'] as num))) {
    return false;
  }
  return true;
}
