import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'data/local/database/app_database.dart';
import 'features/scheduling/notification_service.dart';
import 'features/scheduling/workmanager_service.dart';

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
    await Firebase.initializeApp();
    // App Check is what stops the callable being an open, paid Gemini relay
    // for anyone who finds its URL. Debug providers are needed for emulators
    // and CI; see the README in `functions/`.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleDeviceCheckProvider(),
    );
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
