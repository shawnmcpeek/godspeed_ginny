import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/loader.dart';
import 'game.dart';
import 'telemetry.dart';

enum AppShell { title, play, settings, credits }

class GameController extends ChangeNotifier {
  GameController();

  Game? game;
  Telemetry? telemetry;
  bool loading = true;
  String? loadError;
  bool showTelemetry = false;
  AppShell shell = AppShell.title;

  Future<void> boot() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final content = await loadGameContent();
      final prefs = await SharedPreferences.getInstance();
      telemetry = Telemetry(content.config, prefs);
      game = Game(content, telemetry!, prefs);
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      loadError = '$e';
      notifyListeners();
    }
  }

  Game get g => game!;

  Map<String, dynamic> get strings => game?.S ?? const {};

  void _bump() => notifyListeners();

  Future<void> startRun(String cargoId) async {
    g.startRun(cargoId);
    _bump();
  }

  void tellJoke(String id) {
    g.tellJoke(id);
    _bump();
  }

  void doAction(String kind) {
    g.doAction(kind);
    _bump();
  }

  void continueNode() {
    g.continueNode();
    _bump();
  }

  Future<void> chooseBranch(String edgeId) async {
    await g.chooseBranch(edgeId);
    _bump();
  }

  void chooseDucks(String choice) {
    g.chooseDucks(choice);
    _bump();
  }

  void chooseBoulder(String side) {
    g.chooseBoulder(side);
    _bump();
  }

  void continueAfterChoice() {
    g.continueAfterChoice();
    _bump();
  }

  void returnToOffice() {
    g.returnToOffice();
    _bump();
  }

  Future<void> resetCareer() async {
    await g.resetCareer();
    _bump();
  }

  void toggleTelemetry() {
    showTelemetry = !showTelemetry;
    _bump();
  }

  void openTitle() {
    showTelemetry = false;
    shell = AppShell.title;
    _bump();
  }

  void openPlay() {
    showTelemetry = false;
    shell = AppShell.play;
    _bump();
  }

  void openSettings() {
    showTelemetry = false;
    shell = AppShell.settings;
    _bump();
  }

  void openCredits() {
    showTelemetry = false;
    shell = AppShell.credits;
    _bump();
  }

  bool get hasActiveRun => game?.run != null;

  bool get hasCareerHistory => (game?.career.runs ?? 0) > 0;
}
