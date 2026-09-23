import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database/app_database.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/user_place_repository.dart';
import '../../features/scheduling/notification_service.dart';
import '../../features/scheduling/permission_service.dart';
import '../../features/scheduling/scheduling_service.dart';
import '../../features/scheduling/workmanager_service.dart';
import '../../features/sync/firestore_sync_service.dart';
import '../../services/ai/backend_note_parser.dart';
import '../../services/ai/note_parser.dart';
import '../../services/backend/http_recall_api_client.dart';
import '../../services/backend/recall_api_client.dart';

/// The app's single [AppDatabase] instance — kept alive for the app's
/// lifetime (opened once in `bootstrap.dart` and overridden into this
/// provider so it's never reopened mid-session).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in bootstrap.dart');
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return DriftNoteRepository(ref.watch(appDatabaseProvider));
});

final userPlaceRepositoryProvider = Provider<UserPlaceRepository>((ref) {
  return DriftUserPlaceRepository(ref.watch(appDatabaseProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});

final workManagerServiceProvider = Provider<WorkManagerService>((ref) {
  return const WorkManagerService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionService();
});

final schedulingServiceProvider = Provider<SchedulingService>((ref) {
  return SchedulingService(
    notificationService: ref.watch(notificationServiceProvider),
    workManagerService: ref.watch(workManagerServiceProvider),
    permissionService: ref.watch(permissionServiceProvider),
  );
});

/// The backend proxy client. Holds no secrets — the Gemini key lives on the
/// standalone Node.js server as an environment variable.
///
/// The URL is configured via `--dart-define=BACKEND_URL=http://10.0.2.2:5001`
/// (Android emulator) or similar. Defaults to `http://10.0.2.2:5001`.
final recallApiClientProvider = Provider<RecallApiClient>((ref) {
  const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.10.7.228:5001',
  );
  return HttpRecallApiClient(baseUrl: backendUrl);
});

/// Free-text note parsing (Phase 2, time intelligence).
///
/// Lazy, like every provider here: nothing touches Firebase until a note is
/// actually parsed, so tests that override this — or that never parse at all —
/// never need Firebase initialized.
final noteParserProvider = Provider<NoteParser>((ref) {
  return BackendNoteParser(ref.watch(recallApiClientProvider));
});

/// Syncs notes to Firestore alongside the local database (see
/// `FirestoreSyncService`'s doc comment for why SQLite stays authoritative).
///
/// Defaults to a no-op so every existing test and any dev machine without
/// Firebase configured keeps working unchanged — `bootstrap.dart` overrides
/// this with a [LiveFirestoreSyncService] only after Firebase init and
/// anonymous sign-in both succeed, matching that file's degrade-don't-crash
/// contract.
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return const NoopFirestoreSyncService();
});
