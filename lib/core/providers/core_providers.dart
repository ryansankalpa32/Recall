import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database/app_database.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/user_place_repository.dart';
import '../../features/scheduling/notification_service.dart';
import '../../features/scheduling/permission_service.dart';
import '../../features/scheduling/scheduling_service.dart';
import '../../features/scheduling/workmanager_service.dart';

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
