import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'data/local/database/app_database.dart';
import 'features/scheduling/notification_service.dart';
import 'features/scheduling/workmanager_service.dart';
import 'firebase_options.dart';

/// Region the `parseNote` callable is deployed to. Must match the `region` in
/// `functions/src/index.ts` and the one `FirebaseRecallApiClient` asks for —
/// `FirebaseFunctions` instances are cached per region, so a mismatch here
/// would point the emulator override at an instance the client never uses.
const _functionsRegion = 'us-central1';

/// Route callable traffic at a local Functions emulator instead of the
/// deployed one. Set with `--dart-define=USE_FIREBASE_EMULATOR=true`.
const _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Emulator host override, for a physical device on the same LAN as the
/// machine running the emulator: `--dart-define=FIREBASE_EMULATOR_HOST=192.168.1.5`.
const _emulatorHostOverride = String.fromEnvironment('FIREBASE_EMULATOR_HOST');

/// A debug token already registered under App Check > Apps > Manage debug
/// tokens: `--dart-define=APP_CHECK_DEBUG_TOKEN=...`. Optional — without it the
/// debug provider generates a fresh token and prints it to the console, which
/// then has to be registered by hand after every clean install.
const _appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// Where the Functions emulator is reachable from the *device*, which is not
/// where it is reachable from the host.
///
/// On an Android emulator `localhost` is the emulated device itself; `10.0.2.2`
/// is the alias for the host machine. An iOS simulator shares the host's
/// network stack, so `localhost` is right there. A physical device can reach
/// neither and needs [_emulatorHostOverride].
String get _emulatorHost {
  if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
}

/// One-time app startup: opens the (single, shared) [AppDatabase], registers
/// the WorkManager [callbackDispatcher] the background isolate uses to
/// reopen that same database file, then runs the app with the database
/// instance overridden into [appDatabaseProvider].
///
/// Notification-permission and exact-alarm prompts are deliberately **not**
/// requested here — they fire contextually, the first time the user creates
/// a time-based reminder (see `SchedulingService`), never at startup.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  final notificationService =
      NotificationService(FlutterLocalNotificationsPlugin());

  // The scheduling stack is mobile-oriented: WorkManager and local
  // notifications have partial or no-op web implementations. A failure to
  // initialize them must not stop the app booting — notes CRUD and "My
  // places" work fine without a scheduler, and time reminders are the only
  // thing degraded. Surfaced as a debug log rather than swallowed silently.
  await _initQuietly(
    'WorkManager',
    'time reminders may not fire',
    () => const WorkManagerService().init(),
  );
  await _initQuietly(
    'notifications',
    'time reminders may not fire',
    notificationService.init,
  );

  // Firebase backs the note parser only (the `parseNote` callable proxies
  // Gemini — see `functions/`). Without it the app still runs: the capture
  // sheet falls back to the manual date/time picker, which is exactly the
  // Phase 1 behaviour. So this is another degrade-don't-crash init, and it is
  // also why a dev without a configured Firebase project can still work on
  // everything else.
  await _initQuietly('Firebase', 'free-text note parsing is unavailable',
      () async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check is what stops the callable being an open, paid Gemini relay
    // for anyone who finds its URL.
    //
    // Play Integrity and DeviceCheck only attest builds signed and distributed
    // the normal way, so they reject every debug build — which would look
    // exactly like "the parser is broken". Debug builds therefore use the
    // debug providers, whose token has to be registered in the console once.
    // The production providers are the shipping path; never ship the debug
    // ones, or the endpoint is unprotected again.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken:
                  _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
            )
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(
              debugToken:
                  _appCheckDebugToken.isEmpty ? null : _appCheckDebugToken,
            )
          : const AppleDeviceCheckProvider(),
    );

    if (_useFirebaseEmulator) {
      FirebaseFunctions.instanceFor(region: _functionsRegion)
          .useFunctionsEmulator(_emulatorHost, 5001);
      debugPrint(
        'Recall: callables routed to the Functions emulator at '
        '$_emulatorHost:5001',
      );
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const RecallApp(),
    ),
  );
}

Future<void> _initQuietly(
  String what,
  String consequence,
  Future<void> Function() init,
) async {
  try {
    await init();
  } catch (error, stackTrace) {
    debugPrint('Recall: $what init failed — $consequence. $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
