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

    // Burn castoff beats on steer.
    while (game.run != null && game.screen == 'node' && !game.run!.awaitingContinue) {
      game.doAction('steer');
    }
    if (game.run?.awaitingContinue == true) game.continueNode();

    expect(game.screen, 'branch');
    final branch = game.branches[game.currentStep()!['id']]!;
    final edge = game.offeredEdges(branch).first;
    await game.chooseBranch(edge.id);
    expect(game.screen, 'node');
  });
}
