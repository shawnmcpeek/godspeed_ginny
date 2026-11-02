import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Client DSN for [godspeed-ginny] (daddoo-dev). Override with `--dart-define=SENTRY_DSN=...`.
const _defaultSentryDsn =
    'https://447d673787f030c7e9dd4c84597ba238@o4509657807060992.ingest.us.sentry.io/4512362583425024';

Future<void> runWithSentry(Future<void> Function() appRunner) async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final release = 'godspeed-ginny@${info.version}+${info.buildNumber}';

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: _defaultSentryDsn,
      );
      options.sendDefaultPii = false;
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.release = release;
      options.enableAutoSessionTracking = true;
      options.replay.sessionSampleRate = 0;
      options.replay.onErrorSampleRate = 0;
    },
    appRunner: appRunner,
  );
}
