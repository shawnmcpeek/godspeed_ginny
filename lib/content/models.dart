class GameContent {
  GameContent({
    required this.config,
    required this.jokes,
    required this.nodes,
    required this.branches,
    required this.cargo,
    required this.profiles,
    required this.telegrams,
    required this.strings,
  });

  final GameConfig config;
  final List<Joke> jokes;
  final List<NodeDef> nodes;
  final List<BranchDef> branches;
  final List<CargoDef> cargo;
  final List<Profile> profiles;
  final Telegrams telegrams;
  final Map<String, dynamic> strings;
}

class GameConfig {
  GameConfig(this.raw);

  final Map<String, dynamic> raw;

  String get storageKey => raw['storageKey'] as String;
  String get telemetryKey => raw['telemetryKey'] as String;
  int get telemetryKeep => raw['telemetryKeep'] as int;
  int get paxCount => raw['paxCount'] as int;
  double get startBoiler => (raw['startBoiler'] as num).toDouble();
  double get startWater => (raw['startWater'] as num).toDouble();
  double get startHull => (raw['startHull'] as num).toDouble();
  double get startSat => (raw['startSat'] as num).toDouble();
  double get startCargoHealth => (raw['startCargoHealth'] as num).toDouble();
  double get gaugeClamp => (raw['gaugeClamp'] as num).toDouble();
  double get gaugeDisplayMax => (raw['gaugeDisplayMax'] as num).toDouble();
  double get silenceDrain => (raw['silenceDrain'] as num).toDouble();
  double get fatigueMultiplier => (raw['fatigueMultiplier'] as num).toDouble();
  double get onTopicBonus => (raw['onTopicBonus'] as num).toDouble();
  double get offTopicPenalty => (raw['offTopicPenalty'] as num).toDouble();
  double get sellingMultiplier => (raw['sellingMultiplier'] as num).toDouble();
  double get scoreScale => (raw['scoreScale'] as num).toDouble();
  double get steerThreatReduce => (raw['steerThreatReduce'] as num).toDouble();
  double get steerBoilerReduce => (raw['steerBoilerReduce'] as num).toDouble();
  double get wrenchHullReduce => (raw['wrenchHullReduce'] as num).toDouble();
  double get bailWaterReduce => (raw['bailWaterReduce'] as num).toDouble();
  /// Maximum chance a passenger bolts when bailing; scales up with how much water is aboard.
  double get bailJumpChance => (raw['bailJumpChance'] as num).toDouble();
  double get bailJumpFrom => (raw['bailJumpFrom'] as num?)?.toDouble() ?? 55;
  double get bailJumpFull => (raw['bailJumpFull'] as num?)?.toDouble() ?? 100;
  /// Water level at which bailing counts as real work (no dead air).
  double get bailUsefulAt => (raw['bailUsefulAt'] as num?)?.toDouble() ?? 25;
  /// Room worry per beat per point of unresolved threat while working a real problem.
  double get worryScale => (raw['worryScale'] as num?)?.toDouble() ?? 0.25;
  double get hullWaterFactor => (raw['hullWaterFactor'] as num).toDouble();
  double get boilerCrisisAt => (raw['boilerCrisisAt'] as num).toDouble();
  double get boilerCrisisVent => (raw['boilerCrisisVent'] as num).toDouble();
  double get boilerCrisisThreat => (raw['boilerCrisisThreat'] as num).toDouble();
  double get boilerCrisisSat => (raw['boilerCrisisSat'] as num).toDouble();
  double get waterCrisisAt => (raw['waterCrisisAt'] as num).toDouble();
  double get waterCrisisVent => (raw['waterCrisisVent'] as num).toDouble();
  double get waterCrisisHull => (raw['waterCrisisHull'] as num).toDouble();
  double get waterCrisisSat => (raw['waterCrisisSat'] as num).toDouble();
  double get unresolvedHullScale => (raw['unresolvedHullScale'] as num).toDouble();
  /// Floor so an announced hull hit always moves the Damage meter.
  double get unresolvedHullMin => (raw['unresolvedHullMin'] as num?)?.toDouble() ?? 6;
  double get unresolvedWaterScale => (raw['unresolvedWaterScale'] as num).toDouble();
  double get unresolvedSatScale => (raw['unresolvedSatScale'] as num).toDouble();
  double get riskThreat => (raw['riskThreat'] as num).toDouble();
  double get riskSat => (raw['riskSat'] as num).toDouble();
  double get riskWater => (raw['riskWater'] as num).toDouble();
  /// Stretches that started with at least this much threat earn the "close call" pass line;
  /// gentler ones get a calm pass line.
  double get closeCallThreat => (raw['closeCallThreat'] as num?)?.toDouble() ?? 5;
  double get jokeStrongAt => (raw['jokeStrongAt'] as num).toDouble();
  double get jokeFairAt => (raw['jokeFairAt'] as num).toDouble();
  double get jokeFlatAt => (raw['jokeFlatAt'] as num).toDouble();
  double get salvageThreatMax => (raw['salvageThreatMax'] as num).toDouble();
  int get salvagePay => raw['salvagePay'] as int;
  double get leopardEscapeChance => (raw['leopardEscapeChance'] as num).toDouble();
  int get baseFare => raw['baseFare'] as int;
  double get tipSatFloor => (raw['tipSatFloor'] as num).toDouble();
  double get tipScale => (raw['tipScale'] as num).toDouble();
  double get refundSatFloor => (raw['refundSatFloor'] as num).toDouble();
  double get refundDivisor => (raw['refundDivisor'] as num).toDouble();
  int get refundEach => raw['refundEach'] as int;
  double get repairScale => (raw['repairScale'] as num).toDouble();
  double get iceSurvivePct => (raw['iceSurvivePct'] as num).toDouble();
  int get iceSurviveBonus => raw['iceSurviveBonus'] as int;
  int get leopardLostPay => raw['leopardLostPay'] as int;
  double get pianoDamageHull => (raw['pianoDamageHull'] as num).toDouble();
  double get pianoDamagedPayScale => (raw['pianoDamagedPayScale'] as num).toDouble();
  double get fallsRatingHigh => (raw['fallsRatingHigh'] as num).toDouble();
  double get fallsRatingMid => (raw['fallsRatingMid'] as num).toDouble();
  List<int> get typosPerTelegram =>
      (raw['typosPerTelegram'] as List).map((e) => e as int).toList();
  int get gooseAfterRuns => raw['gooseAfterRuns'] as int;
  Map<String, dynamic> get ducks => raw['ducks'] as Map<String, dynamic>;
  Map<String, dynamic> get boulder => raw['boulder'] as Map<String, dynamic>;
  Map<String, dynamic> get nowhere => raw['nowhere'] as Map<String, dynamic>;
  List<Map<String, dynamic>> get runPlan =>
      (raw['runPlan'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  List<Map<String, dynamic>> get situationTags =>
      ((raw['situationTags'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  dynamic operator [](String key) => raw[key];
}

class Joke {
  Joke({
    required this.id,
    required this.title,
    required this.variants,
    required this.flavors,
    required this.attentionCost,
    required this.deadpan,
    required this.at,
    this.risk,
    this.unlock,
    this.callbackTo = const [],
  });

  factory Joke.fromJson(Map<String, dynamic> j) {
    return Joke(
      id: j['id'] as String,
      title: j['title'] as String,
      variants: (j['variants'] as List)
          .map((v) => JokeVariant.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      flavors: (j['flavors'] as List?)?.map((e) => e as String).toList() ?? const [],
      attentionCost: (j['attention_cost'] as num?)?.toInt() ?? 1,
      deadpan: j['deadpan'] as bool? ?? false,
      at: (j['at'] as List?)?.map((e) => e as String).toList() ?? const [],
      risk: j['risk'] == null ? null : Map<String, dynamic>.from(j['risk'] as Map),
      unlock: j['unlock'] == null ? null : Map<String, dynamic>.from(j['unlock'] as Map),
      callbackTo: (j['callback_to'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  final String id;
  final String title;
  final List<JokeVariant> variants;
  final List<String> flavors;
  final int attentionCost;
  final bool deadpan;
  final List<String> at;
  final Map<String, dynamic>? risk;
  final Map<String, dynamic>? unlock;
  final List<String> callbackTo;
}

class JokeVariant {
  JokeVariant({required this.text, this.weight = 1, this.follow, this.water});

  factory JokeVariant.fromJson(Map<String, dynamic> j) {
    return JokeVariant(
      text: j['text'] as String,
      weight: (j['weight'] as num?)?.toInt() ?? 1,
      follow: j['follow'] as String?,
      water: (j['water'] as num?)?.toDouble(),
    );
  }

  final String text;
  final int weight;
  final String? follow;
  final double? water;
}

class NodeDef {
  NodeDef({
    required this.id,
    required this.name,
    required this.sub,
    required this.type,
    required this.beats,
    required this.threat,
    required this.boilerRate,
    required this.waterRate,
    required this.tags,
    required this.jokeTagsFavored,
    required this.selling,
    required this.salvage,
    this.threatLabel,
    this.open,
    this.brief,
    this.settleStages,
    this.stationCopy,
    this.pools = const [],
  });

  factory NodeDef.fromJson(Map<String, dynamic> j) {
    final poolRaw = j['pool'];
    return NodeDef(
      pools: poolRaw is String
          ? [poolRaw]
          : (poolRaw as List?)?.map((e) => e as String).toList() ?? const [],
      id: j['id'] as String,
      name: j['name'] as String,
      sub: j['sub'] as String,
      type: j['type'] as String,
      beats: j['beats'] as int,
      threat: (j['threat'] as num).toDouble(),
      threatLabel: j['threat_label'] as String?,
      boilerRate: (j['boiler_rate'] as num).toDouble(),
      waterRate: (j['water_rate'] as num).toDouble(),
      tags: (j['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
      jokeTagsFavored:
          (j['joke_tags_favored'] as List?)?.map((e) => e as String).toList() ?? const [],
      open: j['open'] as String?,
      brief: j['brief'] as String?,
      selling: j['selling'] as bool? ?? false,
      salvage: j['salvage'] as bool? ?? false,
      settleStages: (j['settle_stages'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      stationCopy: j['station_copy'] == null
          ? null
          : Map<String, String>.from(
              (j['station_copy'] as Map).map((k, v) => MapEntry('$k', '$v')),
            ),
    );
  }

  final String id;
  final String name;
  final String sub;
  final String type;
  final int beats;
  final double threat;
  final String? threatLabel;
  final double boilerRate;
  final double waterRate;
  final List<String> tags;
  final List<String> jokeTagsFavored;
  final String? open;
  final String? brief;
  final bool selling;
  final bool salvage;
  final List<Map<String, dynamic>>? settleStages;
  final Map<String, String>? stationCopy;

  /// Random-scene pools this node can be drawn from (see `runPlan` steps with a `pool`).
  final List<String> pools;
}

class BranchDef {
  BranchDef({
    required this.id,
    required this.prompt,
    required this.edges,
    this.pick,
  });

  factory BranchDef.fromJson(Map<String, dynamic> j) {
    return BranchDef(
      id: j['id'] as String,
      prompt: j['prompt'] as String,
      pick: j['pick'] as int?,
      edges: (j['edges'] as List)
          .map((e) => BranchEdge.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String id;
  final String prompt;
  final int? pick;
  final List<BranchEdge> edges;
}

class BranchEdge {
  BranchEdge({
    required this.id,
    required this.to,
    required this.charted,
    required this.annotationOnDiscovery,
    this.detour = false,
    this.boilerBonus = 0,
  });

  factory BranchEdge.fromJson(Map<String, dynamic> j) {
    final charted = Map<String, dynamic>.from(j['charted'] as Map);
    return BranchEdge(
      id: j['id'] as String,
      to: j['to'] as String,
      detour: j['detour'] as bool? ?? false,
      charted: ChartedClaim(
        label: charted['label'] as String,
        claim: charted['claim'] as String,
      ),
      annotationOnDiscovery: j['annotation_on_discovery'] as String,
      boilerBonus: (j['boiler_bonus'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String to;
  final bool detour;
  final ChartedClaim charted;
  final String annotationOnDiscovery;
  final double boilerBonus;
}

class ChartedClaim {
  ChartedClaim({required this.label, required this.claim});

  final String label;
  final String claim;
}

class CargoDef {
  CargoDef({
    required this.id,
    required this.name,
    required this.pay,
    required this.note,
    required this.effects,
    required this.unlocksJokes,
  });

  factory CargoDef.fromJson(Map<String, dynamic> j) {
    return CargoDef(
      id: j['id'] as String,
      name: j['name'] as String,
      pay: j['pay'] as int,
      note: j['note'] as String,
      effects: (j['effects'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      unlocksJokes:
          (j['unlocks_jokes'] as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  final String id;
  final String name;
  final int pay;
  final String note;
  final List<Map<String, dynamic>> effects;
  final List<String> unlocksJokes;

  bool hasEffect(String effect) => effects.any((e) => e['effect'] == effect);
}

class Profile {
  Profile({required this.id, required this.name, required this.flavorWeights});

  factory Profile.fromJson(Map<String, dynamic> j) {
    final weights = Map<String, dynamic>.from(j['flavor_weights'] as Map);
    return Profile(
      id: j['id'] as String,
      name: j['name'] as String,
      flavorWeights: weights.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  final String id;
  final String name;
  final Map<String, double> flavorWeights;
}

class Telegrams {
  Telegrams({
    required this.typos,
    required this.office,
    required this.settle,
  });

  factory Telegrams.fromJson(Map<String, dynamic> j) {
    return Telegrams(
      typos: (j['typos'] as List)
          .map((e) => Typo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      office: OfficeTelegram.fromJson(Map<String, dynamic>.from(j['office'] as Map)),
      settle: (j['settle'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  final List<Typo> typos;
  final OfficeTelegram office;
  final List<Map<String, dynamic>> settle;
}

class Typo {
  Typo({required this.from, required this.to});

  factory Typo.fromJson(Map<String, dynamic> j) =>
      Typo(from: j['from'] as String, to: j['to'] as String);

  final String from;
  final String to;
}

class OfficeTelegram {
  OfficeTelegram({
    required this.header,
    required this.variants,
    required this.signoff,
  });

  factory OfficeTelegram.fromJson(Map<String, dynamic> j) {
    final variantsRaw = j['variants'] as List?;
    final List<List<String>> variants;
    if (variantsRaw != null && variantsRaw.isNotEmpty) {
      variants = variantsRaw.map((v) {
        final map = Map<String, dynamic>.from(v as Map);
        return (map['lines'] as List).map((e) => e as String).toList();
      }).toList();
    } else {
      // Legacy single-body shape.
      variants = [(j['lines'] as List).map((e) => e as String).toList()];
    }
    return OfficeTelegram(
      header: j['header'] as String,
      variants: variants,
      signoff: j['signoff'] as String,
    );
  }

  final String header;
  /// Each entry is one full office wire (lines joined for display).
  final List<List<String>> variants;
  final String signoff;
}

class LogLine {
  LogLine({required this.cls, required this.text});

  final String cls;
  final String text;
}

class PlayCard {
  PlayCard({
    required this.station,
    required this.lines,
    required this.deltas,
    required this.ended,
    required this.beatsSpent,
  });

  final String station;
  final List<LogLine> lines;
  final Map<String, double> deltas;
  final bool ended;
  final int beatsSpent;
}

class SettleResult {
  SettleResult({
    required this.base,
    required this.tips,
    required this.refunds,
    required this.refundCost,
    required this.repairs,
    required this.cargoPay,
    required this.cargoName,
    required this.salvage,
    required this.net,
    required this.wire,
    required this.why,
  });

  final int base;
  final int tips;
  final int refunds;
  final int refundCost;
  final int repairs;
  final int cargoPay;
  final String cargoName;
  final int salvage;
  final int net;
  final String wire;
  final String why;
}

class Career {
  Career({
    this.runs = 0,
    this.purse = 0,
    Map<String, String>? notes,
    List<String>? salvage,
    this.leopardOut = false,
    this.best = 0,
  })  : notes = notes ?? {},
        salvage = salvage ?? [];

  factory Career.fresh() => Career();

  factory Career.fromJson(Map<String, dynamic> j) {
    return Career(
      runs: j['runs'] as int? ?? 0,
      purse: j['purse'] as int? ?? 0,
      notes: (j['notes'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {},
      salvage: (j['salvage'] as List?)?.map((e) => e as String).toList() ?? [],
      leopardOut: j['leopardOut'] as bool? ?? false,
      best: (j['best'] as num?)?.toDouble() ?? 0,
    );
  }

  int runs;
  int purse;
  Map<String, String> notes;
  List<String> salvage;
  bool leopardOut;
  double best;

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'purse': purse,
        'notes': notes,
        'salvage': salvage,
        'leopardOut': leopardOut,
        'best': best,
      };
}
