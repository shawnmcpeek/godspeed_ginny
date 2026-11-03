import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../content/loader.dart';
import '../content/models.dart';
import 'telemetry.dart';
import 'util.dart';

class RunState {
  RunState({
    required this.boiler,
    required this.water,
    required this.hull,
    required this.sat,
    required this.cargo,
    required this.cargoHealth,
    required this.pax,
    required this.hand,
    required this.goose,
    required this.forkOffer,
    required this.plan,
  });

  double boiler;
  double water;
  double hull;
  double sat;
  String cargo;
  double cargoHealth;
  List<String> pax;
  List<String> hand;
  Map<String, int> used = {};
  PlayCard? card;
  bool awaitingContinue = false;
  int step = 0;
  int beat = 0;
  double threat = 0;
  String? node;
  bool goose;
  int salvageGot = 0;
  double fallsScore = 0;
  int told = 0;
  String? nowhere;
  Map<String, List<String>> forkOffer;
  List<Map<String, dynamic>> plan;
  Map<String, int> nodeBeats = {'patter': 0, 'steer': 0, 'wrench': 0, 'bail': 0};
  double nodeSatStart = 0;
  List<String> nodeCrises = [];
  bool nodeBailed = false;
  String? boulderScrape;
  Map<String, int> beatsSpent = {'patter': 0, 'steer': 0, 'wrench': 0, 'bail': 0};
  Map<String, dynamic> record = {
    'cargo': '',
    'branches': <String>[],
    'nodes': <Map<String, dynamic>>[],
    'jokes': <Map<String, dynamic>>[],
  };
}

class Game {
  Game(this.content, this.telemetry, this._prefs) {
    cfg = content.config;
    S = content.strings;
    jokes = {for (final j in content.jokes) j.id: j};
    nodes = {for (final n in content.nodes) n.id: n};
    branches = {for (final b in content.branches) b.id: b};
    cargo = {for (final c in content.cargo) c.id: c};
    profiles = {for (final p in content.profiles) p.id: p};
    career = _loadCareer();
  }

  final GameContent content;
  final Telemetry telemetry;
  final SharedPreferences _prefs;

  late final GameConfig cfg;
  late final Map<String, dynamic> S;
  late final Map<String, Joke> jokes;
  late final Map<String, NodeDef> nodes;
  late final Map<String, BranchDef> branches;
  late final Map<String, CargoDef> cargo;
  late final Map<String, Profile> profiles;

  late Career career;
  RunState? run;
  SettleResult? settleResult;
  String screen = 'office';
  String? choiceId;
  bool choiceDone = false;
  Map<String, String>? officeWire;

  Map<String, double>? _before;
  List<LogLine>? _turnLines;

  Career _loadCareer() {
    final raw = _prefs.getString(cfg.storageKey);
    if (raw == null) return Career.fresh();
    try {
      return Career.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return Career.fresh();
    }
  }

  Future<void> persist() async {
    await _prefs.setString(cfg.storageKey, jsonEncode(career.toJson()));
  }

  Future<void> resetCareer() async {
    career = Career.fresh();
    await persist();
    run = null;
    settleResult = null;
    screen = 'office';
    officeWire = null;
  }

  String fmt(String keyPath, [Map<String, Object?>? vars]) {
    final cur = dig(S, keyPath);
    if (cur is! String) return '';
    return fill(cur, vars);
  }

  Map<String, double> gaugeSnap() {
    final r = run!;
    return {
      'boiler': r.boiler,
      'water': r.water,
      'hull': r.hull,
      'sat': r.sat,
      'threat': r.threat,
      'beat': r.beat.toDouble(),
      'cargoHealth': r.cargoHealth,
    };
  }

  Map<String, double> gaugeDelta(Map<String, double> before, Map<String, double> after) {
    final d = <String, double>{};
    for (final k in after.keys) {
      final n = after[k]! - before[k]!;
      if (n != 0) d[k] = n;
    }
    return d;
  }

  void beginTurn() {
    _before = gaugeSnap();
    _turnLines = [];
  }

  void say(String cls, String text) {
    final line = LogLine(cls: cls, text: text);
    if (_turnLines != null) {
      _turnLines!.add(line);
    } else if (run?.card != null) {
      run!.card!.lines.add(line);
    }
  }

  void commitCard(String station) {
    final ended = screen == 'node' && run!.beat <= 0 && !run!.awaitingContinue;
    if (ended) {
      applyNodeResolution();
      run!.awaitingContinue = true;
    }
    run!.card = PlayCard(
      station: station,
      lines: _turnLines ?? [],
      deltas: _before == null ? {} : gaugeDelta(_before!, gaugeSnap()),
      ended: ended,
      beatsSpent: _before == null ? 0 : (_before!['beat']! - run!.beat).round(),
    );
    _turnLines = null;
  }

  String nodeOpenText(NodeDef node) {
    final stages = node.settleStages;
    if (stages != null && stages.isNotEmpty) {
      var stage = stages.first;
      for (final st in stages) {
        if (career.runs >= (st['min_runs'] as int)) stage = st;
      }
      return stage['text'] as String;
    }
    return node.open ?? '';
  }

  Map<String, List<String>> dealForks() {
    final offer = <String, List<String>>{};
    for (final b in content.branches) {
      final n = b.pick ?? b.edges.length;
      offer[b.id] = pickUnique(b.edges, n).map((e) => e.id).toList();
    }
    return offer;
  }

  List<BranchEdge> offeredEdges(BranchDef branch) {
    final ids = run?.forkOffer[branch.id];
    if (ids == null) return branch.edges;
    final byId = {for (final e in branch.edges) e.id: e};
    return ids.map((id) => byId[id]).whereType<BranchEdge>().toList();
  }

  BranchEdge? edgeById(String id) {
    for (final b in content.branches) {
      for (final e in b.edges) {
        if (e.id == id) return e;
      }
    }
    return null;
  }

  int scoreJoke(Joke joke) {
    final r = run!;
    final node = nodes[r.node]!;
    var s = 0.0;
    for (final pid in r.pax) {
      final w = profiles[pid]!.flavorWeights;
      var sum = 0.0;
      for (final f in joke.flavors) {
        sum += w[f] ?? 0;
      }
      s += sum;
    }
    s /= r.pax.length;
    s *= math.pow(cfg.fatigueMultiplier, r.used[joke.id] ?? 0);
    if (jokeOnTopic(joke)) {
      s *= cfg.onTopicBonus;
    } else if (joke.at.isNotEmpty) {
      s *= cfg.offTopicPenalty;
    }
    if (node.selling) s *= cfg.sellingMultiplier;
    return (s * cfg.scoreScale).round();
  }

  bool runMeets(Map<String, dynamic> cond) {
    final r = run;
    if (r == null) return false;
    if (cond['boiler_gte'] != null && r.boiler < (cond['boiler_gte'] as num)) return false;
    if (cond['water_gte'] != null && r.water < (cond['water_gte'] as num)) return false;
    if (cond['hull_gte'] != null && r.hull < (cond['hull_gte'] as num)) return false;
    return true;
  }

  Set<String> situationTags() {
    final n = nodes[run!.node];
    final tags = <String>{...(n?.tags ?? const []), ...(n?.jokeTagsFavored ?? const [])};
    for (final rule in cfg.situationTags) {
      final tag = rule['tag'] as String?;
      if (tag != null && runMeets(rule)) tags.add(tag);
    }
    return tags;
  }

  bool jokeOnTopic(Joke joke) {
    if (run == null) return false;
    final tags = situationTags();
    if (joke.at.any(tags.contains)) return true;
    if (joke.unlock?['method'] == 'bail' && run!.nodeBailed) return true;
    final c = cargo[run!.cargo]!;
    return c.unlocksJokes.contains(joke.id);
  }

  bool jokeOffTopic(Joke joke) {
    if (joke.at.isEmpty) return false;
    return !jokeOnTopic(joke);
  }

  /// Pass lines already shown this run, so the same one does not repeat back to back.
  final Set<String> _usedPassLines = {};

  void startRun(String cargoId) {
    _usedPassLines.clear();
    final goose = career.runs >= cfg.gooseAfterRuns;
    final hand = content.jokes
        .where((j) {
          if (j.unlock?['method'] == 'salvage' && !career.salvage.contains(j.id)) {
            return false;
          }
          if (j.unlock?['method'] == 'bail') return false;
          if (j.at.contains('goose') && !goose) return false;
          return true;
        })
        .map((j) => j.id)
        .toList();
    final pax = pickUnique(content.profiles, cfg.paxCount).map((p) => p.id).toList();

    run = RunState(
      boiler: cfg.startBoiler,
      water: cfg.startWater,
      hull: cfg.startHull,
      sat: cfg.startSat,
      cargo: cargoId,
      cargoHealth: cfg.startCargoHealth,
      pax: pax,
      hand: hand,
      goose: goose,
      forkOffer: dealForks(),
      plan: _buildPlan(),
    );
    run!.record = {
      'cargo': cargoId,
      'branches': <String>[],
      'nodes': <Map<String, dynamic>>[],
      'jokes': <Map<String, dynamic>>[],
    };
    settleResult = null;
    choiceDone = false;
    choiceId = null;
    advanceToCurrent();
  }

  /// Builds this run's step list from `runPlan`. A `{"kind": "shuffle", "units": [[...], ...]}`
  /// entry expands to its units in random order; each unit is a list of steps that stay together
  /// (e.g. a fork and the stretch it leads to).
  List<Map<String, dynamic>> _buildPlan() {
    final out = <Map<String, dynamic>>[];
    for (final s in cfg.runPlan) {
      if (s['kind'] == 'shuffle') {
        final units = (s['units'] as List)
            .map(
              (u) => (u as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            )
            .toList();
        for (final unit in shuffled(units)) {
          out.addAll(unit);
        }
      } else {
        out.add(Map<String, dynamic>.from(s));
      }
    }
    return out;
  }

  /// Fills a `{"kind": "node", "pool": "..."}` step with a random stretch from that pool that
  /// this run has not used yet. Leaves `id` null when the pool is exhausted.
  void _resolvePool(Map<String, dynamic>? step) {
    if (step == null || step['kind'] != 'node' || step['id'] != null) return;
    final pool = step['pool'] as String?;
    if (pool == null) return;
    final r = run!;
    final taken = <String>{
      for (final s in r.plan)
        if (s['id'] is String) s['id'] as String,
      for (final row in r.record['nodes'] as List) (row as Map)['id'] as String,
    };
    // Stretches offered at this run's forks are reserved so a fork never leads somewhere
    // the run has already been.
    final reserved = <String>{};
    for (final ids in r.forkOffer.values) {
      for (final id in ids) {
        final edge = edgeById(id);
        if (edge != null) reserved.add(edge.to);
      }
    }
    final options = content.nodes
        .where((n) => n.pools.contains(pool) && !taken.contains(n.id) && !reserved.contains(n.id))
        .toList();
    if (options.isEmpty) return;
    step['id'] = pick(options).id;
  }

  Map<String, dynamic>? currentStep() {
    final r = run;
    if (r == null || r.step >= r.plan.length) return null;
    return r.plan[r.step];
  }

  void advanceToCurrent() {
    final s = currentStep();
    if (s == null) {
      screen = 'office';
      run = null;
      return;
    }
    _resolvePool(s);
    if (s['kind'] == 'node' && s['id'] == null && s['pool'] != null) {
      // Pool exhausted: skip this scene rather than ending the run.
      run!.step++;
      advanceToCurrent();
      return;
    }
    if (s['kind'] == 'node' && s['id'] != null) {
      enterNode(s['id'] as String);
      return;
    }
    if (s['kind'] == 'branch') {
      screen = 'branch';
      return;
    }
    if (s['kind'] == 'choice') {
      screen = 'choice';
      choiceId = s['id'] as String;
      choiceDone = false;
      run!.card = null;
      if (s['id'] == 'boulder') {
        run!.boulderScrape = chance(0.5) ? 'left' : 'right';
      }
      return;
    }
    if (s['kind'] == 'settle') {
      screen = 'settle';
      settleResult = computeSettle();
      return;
    }
    screen = 'office';
  }

  void enterNode(String id) {
    final n = nodes[id]!;
    final r = run!;
    r.node = id;
    r.beat = n.beats;
    r.threat = n.threat;
    r.nodeBeats = {'patter': 0, 'steer': 0, 'wrench': 0, 'bail': 0};
    r.nodeSatStart = r.sat;
    r.nodeCrises = [];
    r.nodeBailed = false;
    r.awaitingContinue = false;
    screen = 'node';
    var open = nodeOpenText(n);
    if (n.type == 'destination') {
      r.nowhere = nowhereOutcome();
      open = (S['nowhere'] as Map)[r.nowhere] as String;
      if (r.nowhere != 'passed') {
        r.beat = 0;
        r.awaitingContinue = true;
        r.card = PlayCard(
          station: 'open',
          lines: open.isNotEmpty ? [LogLine(cls: 'beat', text: open)] : [],
          deltas: {},
          ended: true,
          beatsSpent: 0,
        );
        (r.record['nodes'] as List).add({
          'id': id,
          'satDelta': 0,
          'threatLeft': 0,
          'crises': <String>[],
          'beats': Map<String, int>.from(r.nodeBeats),
        });
        return;
      }
    }
    final lines = <LogLine>[];
    if (open.isNotEmpty) lines.add(LogLine(cls: 'beat', text: open));
    if (n.beats > 0) {
      final brief = n.brief ?? dig(S, 'card.rule') as String?;
      if (brief != null && brief.isNotEmpty) {
        lines.add(LogLine(cls: 'act', text: brief));
      }
    }
    r.card = PlayCard(
      station: 'open',
      lines: lines,
      deltas: {},
      ended: false,
      beatsSpent: 0,
    );
  }

  String nowhereOutcome() {
    final nowhere = cfg.nowhere;
    var crises = 0;
    for (final row in run!.record['nodes'] as List) {
      crises += ((row as Map)['crises'] as List?)?.length ?? 0;
    }
    crises += run!.nodeCrises.length;
    if (run!.hull >= (nowhere['abortHull'] as num) ||
        run!.sat < (nowhere['abortSat'] as num) ||
        crises >= (nowhere['abortCrises'] as num)) {
      return 'abort';
    }
    final branchesTaken = (run!.record['branches'] as List).cast<String>();
    if (branchesTaken.any((id) => edgeById(id)?.detour == true)) return 'missed';
    final wrong = nowhere['wrongTurn'] as String?;
    if (wrong != null && branchesTaken.contains(wrong)) return 'missed';
    return 'passed';
  }

  void applyBeatCargo() {
    final c = cargo[run!.cargo]!;
    for (final fx in c.effects) {
      if (fx['trigger'] == 'beat' && fx['effect'] == 'melt') {
        run!.cargoHealth =
            (run!.cargoHealth - ((fx['value'] as num?)?.toDouble() ?? 0)).clamp(0, 100);
      }
    }
  }

  void damageHull(double amount) {
    final r = run!;
    r.hull = clamp(r.hull + amount, 0, cfg.gaugeClamp);
  }

  void repairHull(double amount) {
    final r = run!;
    r.hull = clamp(r.hull - amount, 0, cfg.gaugeClamp);
  }

  void checkCrisis() {
    final r = run!;
    if (r.boiler >= cfg.boilerCrisisAt) {
      say('bad', dig(S, 'log.boilerCrisis') as String);
      r.boiler = clamp(r.boiler - cfg.boilerCrisisVent, 0, cfg.gaugeClamp);
      r.threat += cfg.boilerCrisisThreat;
      r.sat = clamp(r.sat - cfg.boilerCrisisSat, 0, 100);
      say('bad', dig(S, 'log.boilerCrisisFix') as String);
      r.nodeCrises.add('boiler');
    }
    if (r.water >= cfg.waterCrisisAt) {
      say('bad', dig(S, 'log.waterCrisis') as String);
      r.water = clamp(r.water - cfg.waterCrisisVent, 0, cfg.gaugeClamp);
      damageHull(cfg.waterCrisisHull);
      r.sat = clamp(r.sat - cfg.waterCrisisSat, 0, 100);
      r.nodeCrises.add('water');
    }
  }

  void spend(int cost, String station, {double? drain}) {
    final node = nodes[run!.node]!;
    final wasTalk = station == 'patter';
    for (var i = 0; i < cost; i++) {
      run!.beat--;
      if (station == 'steer') {
        run!.boiler = clamp(run!.boiler - cfg.steerBoilerReduce, 0, cfg.gaugeClamp);
      } else {
        run!.boiler = clamp(run!.boiler + node.boilerRate, 0, cfg.gaugeClamp);
      }
      run!.water = clamp(
        run!.water + node.waterRate + (run!.hull / cfg.hullWaterFactor).floor(),
        0,
        cfg.gaugeClamp,
      );
      if (!wasTalk) run!.sat = clamp(run!.sat - (drain ?? cfg.silenceDrain), 0, 100);
      applyBeatCargo();
      run!.beatsSpent[station] = (run!.beatsSpent[station] ?? 0) + 1;
      run!.nodeBeats[station] = (run!.nodeBeats[station] ?? 0) + 1;
      checkCrisis();
    }
  }

  void tellJoke(String id) {
    final joke = jokes[id]!;
    final timesPrev = run!.used[id] ?? 0;
    final gain = scoreJoke(joke);
    final offTopic = jokeOffTopic(joke);
    beginTurn();
    run!.used[id] = timesPrev + 1;
    run!.told++;
    final told = pickWeighted(joke.variants);
    say('skip', told.text);
    if (told.follow != null) say('act', told.follow!);
    if (told.water != null) {
      run!.water = clamp(run!.water + told.water!, 0, cfg.gaugeClamp);
    }
    if (joke.deadpan) say('beat', dig(S, 'log.deadpan') as String);

    run!.sat = clamp(run!.sat + gain, 0, 100);
    if (offTopic) say('act', dig(S, 'log.jokeOffTopic') as String);
    if (gain >= cfg.jokeStrongAt) {
      say('good', dig(S, 'log.jokeStrong') as String);
    } else if (gain >= cfg.jokeFairAt) {
      say('act', dig(S, 'log.jokeFair') as String);
    } else if (gain > cfg.jokeFlatAt) {
      say('act', dig(S, 'log.jokeFlat') as String);
    } else {
      say('bad', dig(S, 'log.jokeBad') as String);
    }

    if (nodes[run!.node]!.selling) run!.fallsScore += gain;

    (run!.record['jokes'] as List).add({
      'id': id,
      'node': run!.node,
      'score': gain,
      'timesPreviouslyTold': timesPrev,
      'offTopic': offTopic,
    });

    final risk = joke.risk;
    if (risk != null && chance((risk['chance'] as num).toDouble())) {
      say('bad', dig(S, 'log.riskTrigger') as String);
      run!.threat += cfg.riskThreat;
      run!.sat = clamp(run!.sat - cfg.riskSat, 0, 100);
      run!.water = clamp(run!.water + cfg.riskWater, 0, cfg.gaugeClamp);
      say('bad', dig(S, 'log.riskOverboard') as String);
    }
    spend(joke.attentionCost, 'patter');
    commitCard('patter');
  }

  /// Room lost on a non-patter beat. Working a real problem is not dead air: the room only
  /// worries in proportion to the hazard still unresolved. Idle beats (nothing to fix, or the
  /// falls, where the show is the point) cost the full silence drain.
  double beatDrain(String kind, NodeDef node) {
    final r = run!;
    if (node.selling) return cfg.silenceDrain;
    final useful = switch (kind) {
      'steer' => r.threat > 0,
      'wrench' => r.hull > 0,
      'bail' => r.water >= cfg.bailUsefulAt,
      _ => false,
    };
    if (!useful) return cfg.silenceDrain;
    return math.min(cfg.silenceDrain, r.threat * cfg.worryScale);
  }

  /// Chance a passenger bolts while you bail: none while the leak is manageable, rising toward
  /// [GameConfig.bailJumpChance] as the boat fills.
  double bailJumpChanceAt(double water) {
    final span = cfg.bailJumpFull - cfg.bailJumpFrom;
    if (span <= 0) return cfg.bailJumpChance;
    final t = math.max(0.0, math.min(1.0, (water - cfg.bailJumpFrom) / span));
    return cfg.bailJumpChance * t;
  }

  void doAction(String kind) {
    final node = nodes[run!.node]!;
    final drain = beatDrain(kind, node);
    final jumpChance = bailJumpChanceAt(run!.water);
    beginTurn();
    if (kind == 'steer') {
      if (node.selling) {
        say('act', node.stationCopy?['steer'] ?? dig(S, 'log.steerSelling') as String);
      } else {
        run!.threat = (run!.threat - cfg.steerThreatReduce).clamp(0, double.infinity);
        say('act', node.stationCopy?['steer'] ?? dig(S, 'log.steer') as String);
      }
    }
    if (kind == 'wrench') {
      repairHull(cfg.wrenchHullReduce);
      say('act', node.stationCopy?['wrench'] ?? dig(S, 'log.wrench') as String);
    }
    if (kind == 'bail') {
      run!.water = clamp(run!.water - cfg.bailWaterReduce, 0, cfg.gaugeClamp);
      run!.nodeBailed = true;
      say('act', node.stationCopy?['bail'] ?? dig(S, 'log.bail') as String);
      final jumped = !node.selling && chance(jumpChance);
      if (jumped) say('bad', dig(S, 'log.bailJump') as String);
      for (final j in content.jokes) {
        if (j.unlock?['method'] == 'bail' && !run!.hand.contains(j.id)) {
          run!.hand.add(j.id);
        }
      }
      spend(1, kind, drain: drain);
      if (!jumped && !node.selling && drain >= cfg.silenceDrain) {
        say('beat', dig(S, 'log.silence') as String);
      }
      commitCard(kind);
      return;
    }
    spend(1, kind, drain: drain);
    if (kind != 'patter' && drain >= cfg.silenceDrain) {
      say('beat', dig(S, 'log.silence') as String);
    }
    commitCard(kind);
  }

  void applyNodeResolution() {
    final n = nodes[run!.node]!;
    final c = cargo[run!.cargo]!;
    if (n.type == 'destination') {
      if (run!.nowhere == 'passed') say('act', dig(S, 'log.nowhereHome') as String);
    } else if (n.selling) {
      if ((run!.nodeBeats['patter'] ?? 0) > 0) {
        say('good', dig(S, 'log.cleanSelling') as String);
      } else {
        say('act', dig(S, 'log.fallsUnsold') as String);
      }
      final rating = run!.fallsScore;
      if (rating >= cfg.fallsRatingHigh) {
        say('good', dig(S, 'log.fallsHigh') as String);
      } else if (rating >= cfg.fallsRatingMid) {
        say('act', dig(S, 'log.fallsMid') as String);
      } else {
        say('bad', dig(S, 'log.fallsLow') as String);
      }
    } else if (run!.threat > 0) {
      final t = run!.threat;
      final sides = (dig(S, 'log.sides') as List).cast<String>();
      say(
        'bad',
        fmt('log.unresolved', {
          'label': n.threatLabel ?? dig(S, 'log.unresolvedFallback') as String,
          'side': pick(sides),
        }),
      );
      // Scale + floor so "takes a hit" always moves the Damage meter on the 0–100 dial.
      final hit = math.max(
        cfg.unresolvedHullMin,
        (t * cfg.unresolvedHullScale).round().toDouble(),
      );
      damageHull(hit);
      run!.water = clamp(run!.water + t * cfg.unresolvedWaterScale, 0, cfg.gaugeClamp);
      run!.sat = clamp(run!.sat - t * cfg.unresolvedSatScale, 0, 100);
      if (c.hasEffect('play_note')) say('act', dig(S, 'log.pianoNote') as String);
      if (c.hasEffect('escape') && !career.leopardOut) {
        final fx = c.effects.firstWhere((e) => e['effect'] == 'escape');
        final chanceKey = fx['chance_key'] as String?;
        final p = chanceKey != null
            ? (cfg[chanceKey] as num).toDouble()
            : (fx['chance'] as num?)?.toDouble() ?? 0;
        if (chance(p)) {
          career.leopardOut = true;
          persist();
          say('bad', dig(S, 'log.leopardGone') as String);
          run!.cargoHealth = 0;
        }
      }
    } else {
      final close = n.threat >= cfg.closeCallThreat;
      final pool = dig(S, close ? 'log.cleanClose' : 'log.cleanCalm');
      var text = dig(S, 'log.clean') as String;
      if (pool is List && pool.isNotEmpty) {
        final all = pool.cast<String>();
        final fresh = all.where((l) => !_usedPassLines.contains(l)).toList();
        text = pick(fresh.isNotEmpty ? fresh : all);
        _usedPassLines.add(text);
      }
      say('good', text);
    }
    if (n.salvage && run!.threat <= cfg.salvageThreatMax) {
      run!.salvageGot = 1;
      say('good', dig(S, 'log.salvage') as String);
    }

    (run!.record['nodes'] as List).add({
      'id': run!.node,
      'satDelta': run!.sat - run!.nodeSatStart,
      'threatLeft': run!.threat,
      'crises': List<String>.from(run!.nodeCrises),
      'beats': Map<String, int>.from(run!.nodeBeats),
    });
  }

  void continueNode() {
    run!.awaitingContinue = false;
    run!.step++;
    final nx = currentStep();
    _resolvePool(nx);
    if (nx != null && nx['kind'] == 'node' && nx['id'] != null) {
      enterNode(nx['id'] as String);
    } else {
      advanceToCurrent();
    }
  }

  Future<void> chooseBranch(String edgeId) async {
    final step = currentStep()!;
    final branch = branches[step['id'] as String]!;
    final edge = branch.edges.firstWhere((e) => e.id == edgeId);
    career.notes[edge.id] = edge.annotationOnDiscovery;
    await persist();
    (run!.record['branches'] as List).add(edge.id);
    final nextIdx = run!.step + 1;
    if (nextIdx < run!.plan.length) {
      final next = run!.plan[nextIdx];
      if (next['kind'] == 'node') next['id'] = edge.to;
    }
    if (edge.boilerBonus != 0) {
      run!.boiler = clamp(run!.boiler + edge.boilerBonus, 0, cfg.gaugeClamp);
    }
    run!.step++;
    enterNode(edge.to);
    final claim = fmt('log.chartSaid', {'claim': edge.charted.claim});
    run!.card?.lines.add(LogLine(cls: 'beat', text: claim));
  }

  void chooseDucks(String choice) {
    final dCfg = cfg.ducks;
    final dS = Map<String, dynamic>.from(S['ducks'] as Map);
    beginTurn();
    say('beat', run!.goose ? dS['openGoose'] as String : dS['open'] as String);

    if (choice == 'funny') {
      final gooseJoke = jokes[dCfg['gooseJokeId'] as String]!;
      final paraJoke = jokes[dCfg['paraJokeId'] as String]!;
      if (run!.goose && !career.salvage.contains(dCfg['gooseJokeId'])) {
        say('skip', dS['funnySetup'] as String);
        say('bad', dS['funnyFail'] as String);
        say('skip', pickWeighted(gooseJoke.variants).text);
        say('good', dS['funnyLand'] as String);
        career.salvage.add(dCfg['gooseJokeId'] as String);
        persist();
        run!.sat = clamp(run!.sat + (dCfg['gooseSat'] as num).toDouble(), 0, 100);
      } else if (run!.goose) {
        say('skip', pickWeighted(gooseJoke.variants).text);
        run!.sat = clamp(run!.sat + (dCfg['gooseRepeatSat'] as num).toDouble(), 0, 100);
        say('good', dS['funnyRepeat'] as String);
      } else {
        say('skip', pickWeighted(paraJoke.variants).text);
        run!.sat = clamp(run!.sat + (dCfg['funnySat'] as num).toDouble(), 0, 100);
        say('good', dS['funnyGroan'] as String);
      }
      run!.boiler = clamp(run!.boiler + (dCfg['funnyBoiler'] as num).toDouble(), 0, cfg.gaugeClamp);
      say('act', dS['funnyCost'] as String);
      checkCrisis();
    } else {
      say('act', dS['fastAct'] as String);
      run!.sat = clamp(run!.sat + (dCfg['fastSat'] as num).toDouble(), 0, 100);
      run!.boiler = clamp(run!.boiler + (dCfg['fastBoiler'] as num).toDouble(), 0, cfg.gaugeClamp);
      say('beat', dS['fastAsk'] as String);
    }
    choiceDone = true;
    run!.card = PlayCard(
      station: choice == 'funny' ? 'patter' : 'steer',
      lines: _turnLines ?? [],
      deltas: _before == null ? {} : gaugeDelta(_before!, gaugeSnap()),
      ended: true,
      beatsSpent: 0,
    );
    _turnLines = null;
  }

  void chooseBoulder(String side) {
    final bCfg = cfg.boulder;
    final bS = Map<String, dynamic>.from(S['boulder'] as Map);
    beginTurn();
    if (side == run!.boulderScrape) {
      damageHull((bCfg['scrapeHull'] as num).toDouble());
      run!.water = clamp(run!.water + (bCfg['scrapeWater'] as num).toDouble(), 0, cfg.gaugeClamp);
      run!.sat = clamp(run!.sat - (bCfg['scrapeSat'] as num).toDouble(), 0, 100);
      say('bad', bS['scrape'] as String);
    } else {
      say('good', bS['clear'] as String);
    }
    final punchlines = (bS['punchlines'] as List)
        .map((e) => JokeVariant.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    say('skip', pickWeighted(punchlines).text);
    checkCrisis();
    choiceDone = true;
    run!.card = PlayCard(
      station: 'boulder',
      lines: _turnLines ?? [],
      deltas: _before == null ? {} : gaugeDelta(_before!, gaugeSnap()),
      ended: true,
      beatsSpent: 0,
    );
    _turnLines = null;
  }

  void continueAfterChoice() {
    run!.step++;
    advanceToCurrent();
  }

  int cargoPay() {
    final c = cargo[run!.cargo]!;
    var pay = c.pay;
    if (c.hasEffect('melt')) {
      pay = run!.cargoHealth >= cfg.iceSurvivePct
          ? c.pay + cfg.iceSurviveBonus
          : (c.pay * (run!.cargoHealth / 100)).round();
    }
    if (c.hasEffect('escape') && run!.cargoHealth == 0) pay = cfg.leopardLostPay;
    if (c.hasEffect('play_note') && run!.hull > cfg.pianoDamageHull) {
      pay = (c.pay * cfg.pianoDamagedPayScale).round();
    }
    return pay;
  }

  SettleResult computeSettle() {
    final tips =
        ((run!.sat - cfg.tipSatFloor).clamp(0, double.infinity) * cfg.tipScale).round();
    final refunds = run!.sat < cfg.refundSatFloor
        ? ((cfg.refundSatFloor - run!.sat) / cfg.refundDivisor).floor()
        : 0;
    final refundCost = refunds * cfg.refundEach;
    final repairs = (run!.hull * cfg.repairScale).round();
    final pay = cargoPay();
    final salvage = run!.salvageGot != 0 ? cfg.salvagePay : 0;
    final net = cfg.baseFare + tips + pay + salvage - refundCost - repairs;

    career.runs++;
    career.purse += net;
    career.best = career.best > run!.sat ? career.best : run!.sat;
    persist();

    final ctx = {
      'refunds': refunds,
      'net': net,
      'sat': run!.sat,
      'cargoId': run!.cargo,
      'cargoHealth': run!.cargoHealth,
    };
    final wireRule = content.telegrams.settle.firstWhere(
      (w) => condMatch(w['if'] as Map<String, dynamic>?, ctx),
      orElse: () => <String, dynamic>{},
    );
    var wire = ((wireRule['text'] as String?) ?? '').replaceAll('{refunds}', '$refunds');
    wire = applyTypos(wire, content.telegrams.typos, cfg.typosPerTelegram);

    final fallsUnsold = (run!.record['nodes'] as List).any((row) {
      final m = row as Map;
      final node = nodes[m['id'] as String];
      final beats = Map<String, dynamic>.from(m['beats'] as Map? ?? {});
      return node?.selling == true && ((beats['patter'] as num?)?.toInt() ?? 0) == 0;
    });
    final whyLines = ((S['settle'] as Map)['why'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(
          (line) => explainMatch(line['if'] as Map<String, dynamic>?, {
            'refunds': refunds,
            'fallsUnsold': fallsUnsold,
            'nowhere': run!.nowhere,
            'repairs': repairs,
          }),
        )
        .map(
          (line) => fill(line['text'] as String, {
            'refunds': refunds,
            'sat': run!.sat.round(),
          }),
        )
        .join(' ');

    final result = SettleResult(
      base: cfg.baseFare,
      tips: tips,
      refunds: refunds,
      refundCost: refundCost,
      repairs: repairs,
      cargoPay: pay,
      cargoName: cargo[run!.cargo]!.name,
      salvage: salvage,
      net: net,
      wire: wire,
      why: whyLines,
    );

    telemetry.commitRun({
      'cargo': run!.record['cargo'],
      'branches': run!.record['branches'],
      'nodes': run!.record['nodes'],
      'jokes': run!.record['jokes'],
      'beatsSpent': run!.beatsSpent,
      'final': {
        'boiler': run!.boiler,
        'water': run!.water,
        'hull': run!.hull,
        'sat': run!.sat,
      },
      'refunds': refunds,
      'nowhere': run!.nowhere,
      'net': net,
    });

    return result;
  }

  Map<String, String> officeTelegram() {
    officeWire ??= () {
      final lines = pick(content.telegrams.office.variants);
      return {
        'header': content.telegrams.office.header,
        'body': applyTypos(
          lines.join('\n'),
          content.telegrams.typos,
          cfg.typosPerTelegram,
        ),
        'signoff': content.telegrams.office.signoff,
      };
    }();
    return officeWire!;
  }

  void returnToOffice() {
    run = null;
    settleResult = null;
    screen = 'office';
    officeWire = null;
  }

  String formatPurse(int n) {
    final sign = n >= 0 ? '£' : '−£';
    return '$sign${n.abs()}';
  }
}
