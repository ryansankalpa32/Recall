import '../../domain/models/note.dart';
import 'notification_service.dart';
import 'permission_service.dart';
import 'workmanager_service.dart';

/// Picks the delivery mechanism for a note's time-based reminder and keeps
/// the two in sync with note lifecycle changes (save / done).
///
/// - Near-term reminders (within [_exactScheduleThreshold]) go through
///   `NotificationService.scheduleNoteReminder` (`zonedSchedule`), which can
///   use Android's exact-alarm path for precise firing.
/// - Farther-out reminders go through `WorkManagerService`, which survives
///   process death/reboots better for long delays but fires on an
///   inexact/backoff-managed schedule.
///
/// Both prompts this depends on (notification permission, exact-alarm
/// allowance) are requested contextually, the first time a reminder is
/// actually created — never at app startup.
class SchedulingService {
  SchedulingService({
    required this.notificationService,
    required this.workManagerService,
    required this.permissionService,
  });

  final NotificationService notificationService;
  final WorkManagerService workManagerService;
  final PermissionService permissionService;

  static const _exactScheduleThreshold = Duration(hours: 6);

  /// Requests the permissions a time-based reminder needs, then schedules
  /// it. Returns whether exact-alarm delivery was used (near-term path) so
  /// the caller can surface "may fire a few minutes late" when it wasn't.
  Future<bool> scheduleReminder(Note note) async {
    final scheduledDate = note.resolvedDatetime;
    if (scheduledDate == null) {
      throw ArgumentError('Note ${note.id} has no resolvedDatetime to schedule');
    }
    final noteId = note.id;
    if (noteId == null) {
      throw ArgumentError('Note must be persisted (have an id) before scheduling');
    }

    await permissionService.requestNotificationPermission();

    final delay = scheduledDate.difference(DateTime.now());
    if (delay <= _exactScheduleThreshold) {
      final exactGranted = await notificationService.requestExactAlarmsPermission();
      final canUseExact = exactGranted && await notificationService.canScheduleExactAlarms();
      await notificationService.scheduleNoteReminder(
        noteId: noteId,
        title: 'Recall',
        body: note.taskDescription,
        scheduledDate: scheduledDate,
        useExactAlarm: canUseExact,
      );
      return canUseExact;
    } else {
      await workManagerService.scheduleNoteReminder(
        noteId: noteId,
        scheduledDate: scheduledDate,
      );
      return false;
    }
  }

  /// Cancels any pending delivery for [noteId] — called when a note is
  /// marked done, so completed notes never fire late. Safe to call even if
  /// only one of the two mechanisms was actually used.
  Future<void> cancelReminder(int noteId) async {
    await notificationService.cancel(noteId);
    await workManagerService.cancelNoteReminder(noteId);
  }
}
