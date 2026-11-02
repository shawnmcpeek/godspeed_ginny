import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

Future<GameContent> loadGameContent() async {
  Future<dynamic> load(String name) async {
    final raw = await rootBundle.loadString('assets/content/$name.json');
    return jsonDecode(raw);
  }

  final configRaw = Map<String, dynamic>.from(await load('config') as Map);
  final jokesRaw = await load('jokes') as List;
  final nodesRaw = await load('nodes') as List;
  final branchesRaw = await load('branches') as List;
  final cargoRaw = await load('cargo') as List;
  final profilesRaw = await load('profiles') as List;
  final telegramsRaw = Map<String, dynamic>.from(await load('telegrams') as Map);
  final stringsRaw = Map<String, dynamic>.from(await load('strings') as Map);

  return GameContent(
    config: GameConfig(configRaw),
    jokes: jokesRaw.map((e) => Joke.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    nodes: nodesRaw.map((e) => NodeDef.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    branches:
        branchesRaw.map((e) => BranchDef.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    cargo: cargoRaw.map((e) => CargoDef.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    profiles:
        profilesRaw.map((e) => Profile.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    telegrams: Telegrams.fromJson(telegramsRaw),
    strings: stringsRaw,
  );
}

String fill(String template, [Map<String, Object?>? vars]) {
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final key = m.group(1)!;
    final v = vars?[key];
    return v == null ? '' : '$v';
  });
}

dynamic dig(Map<String, dynamic> root, String path) {
  dynamic cur = root;
  for (final p in path.split('.')) {
    if (cur is! Map) return null;
    cur = cur[p];
  }
  return cur;
}
