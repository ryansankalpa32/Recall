import 'package:permission_handler/permission_handler.dart';

/// `permission_handler` usage scoped to exactly [Permission.notification] —
/// per the plan's Phase 1 design, this file must not request location
/// permission. Exact-alarm allowance is a separate Android setting handled
/// by `NotificationService` (via `flutter_local_notifications`'s own API),
/// not by this class.
///
/// Both this and the exact-alarm prompt are called contextually — the first
/// time the user creates a time-based reminder — never at app startup.
class PermissionService {
  const PermissionService();

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    return Permission.notification.isGranted;
  }
}
