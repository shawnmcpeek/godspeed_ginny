import 'package:flutter_test/flutter_test.dart';
import 'package:godspeed_ginny/content/loader.dart';
import 'package:godspeed_ginny/engine/game.dart';
import 'package:godspeed_ginny/engine/telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('content loads and a run reaches settle', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final telemetry = Telemetry(content.config, prefs);
    final game = Game(content, telemetry, prefs);

    expect(content.jokes.length, greaterThan(10));
    expect(content.nodes.any((n) => n.id == 'falls'), isTrue);

    game.startRun('mail_sacks');
    expect(game.screen, 'node');
    expect(game.run?.node, 'castoff');
    expect(content.telegrams.office.variants.length, greaterThan(1));

    final wireA = game.officeTelegram()['body'];
    game.officeWire = null;
    final wireB = game.officeTelegram()['body'];
    // Same or different is fine; both must be non-empty STOP wires.
    expect(wireA, contains('STOP'));
    expect(wireB, contains('STOP'));
  });

  test('unresolved threat always bumps hull by at least unresolvedHullMin', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final game = Game(content, Telemetry(content.config, prefs), prefs);

    game.startRun('mail_sacks');
    final before = game.run!.hull;
    game.run!.threat = 1;
    game.beginTurn();
    game.applyNodeResolution();
    final delta = game.run!.hull - before;

    expect(delta, greaterThanOrEqualTo(content.config.unresolvedHullMin));
  });

  test('boulder scrape raises hull on the Damage meter', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final game = Game(content, Telemetry(content.config, prefs), prefs);

    game.startRun('mail_sacks');
    game.screen = 'choice';
    game.choiceId = 'boulder';
    game.choiceDone = false;
    game.run!.boulderScrape = 'left';
    final before = game.run!.hull;
    game.chooseBoulder('left');
    expect(game.run!.hull - before, (content.config.boulder['scrapeHull'] as num).toDouble());
    expect(game.run!.card!.deltas['hull'], (content.config.boulder['scrapeHull'] as num).toDouble());
  });

  test('boulder plan is approach then left/right choice, no fork', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final game = Game(content, Telemetry(content.config, prefs), prefs);

    game.startRun('mail_sacks');
    final plan = game.run!.plan;
    expect(plan.any((s) => s['id'] == 'fork_boulder'), isFalse);
    final nodeAt = plan.indexWhere((s) => s['kind'] == 'node' && s['id'] == 'boulder');
    expect(nodeAt, greaterThanOrEqualTo(0));
    expect(plan[nodeAt + 1]['kind'], 'choice');
    expect(plan[nodeAt + 1]['id'], 'boulder');

    game.run!.step = nodeAt;
    game.enterNode('boulder');
    expect(game.screen, 'node');
    expect(game.run!.node, 'boulder');
    expect(game.choiceId, isNull);

    game.run!.beat = 0;
    game.continueNode();
    expect(game.screen, 'choice');
    expect(game.choiceId, 'boulder');
    expect(game.choiceDone, isFalse);
  });

  test('a finished stretch opens the next fork without a Next pause', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final game = Game(content, Telemetry(content.config, prefs), prefs);

    game.startRun('mail_sacks');
    final plan = game.run!.plan;
    final nodeAt = plan.indexWhere((s) => s['kind'] == 'node' && s['id'] == 'boulder');
    game.run!.plan[nodeAt + 1] = {'kind': 'branch', 'id': 'fork2'};
    game.run!.step = nodeAt;
    game.enterNode('boulder');
    game.run!.beat = 1;

    game.doAction('steer');

    expect(game.screen, 'branch');
    expect(game.run!.awaitingContinue, isFalse);
    expect(game.currentStep()!['id'], 'fork2');
    expect(game.run!.card, isNotNull);
  });

  test('clearing the boulder opens the next fork without Carry on', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final content = await loadGameContent();
    final game = Game(content, Telemetry(content.config, prefs), prefs);

    game.startRun('mail_sacks');
    final plan = game.run!.plan;
    final choiceAt = plan.indexWhere((s) => s['kind'] == 'choice' && s['id'] == 'boulder');
    game.run!.plan[choiceAt + 1] = {'kind': 'branch', 'id': 'fork2'};
    game.run!.step = choiceAt;
    game.screen = 'choice';
    game.choiceId = 'boulder';
    game.choiceDone = false;
    game.run!.boulderScrape = 'left';

    game.chooseBoulder('right');

    expect(game.screen, 'branch');
    expect(game.currentStep()!['id'], 'fork2');
    expect(game.run!.card!.lines.map((l) => l.text).join('\n'), contains('Clear water'));
  });
}
