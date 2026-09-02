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
  await _initQuietly('WorkManager', () => const WorkManagerService().init());
  await _initQuietly('notifications', notificationService.init);

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

Future<void> _initQuietly(String what, Future<void> Function() init) async {
  try {
    await init();
  } catch (error, stackTrace) {
    debugPrint('Recall: $what init failed — time reminders may not fire. $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
