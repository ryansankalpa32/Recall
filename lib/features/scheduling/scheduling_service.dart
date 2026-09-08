import '../../domain/models/note.dart';
import 'notification_service.dart';
import 'permission_service.dart';
import 'workmanager_service.dart';

/// How a reminder actually got scheduled.
enum ReminderDelivery {
  /// Android exact alarm — fires at the requested minute.
  exactAlarm,

  /// Exact-alarm allowance was withheld, so delivery is best-effort and may
  /// slip by minutes.
  inexactAlarm,

  /// Handed to WorkManager because the reminder is far enough out that
  /// surviving process death matters more than to-the-minute accuracy.
  deferredWork,
}

/// The result of scheduling one reminder.
///
/// Exists so the caller can tell the user when a reminder will *not* behave the
/// way they just asked for. Before this, a denied notification permission was
/// swallowed and the note was still saved as `scheduled` — which quietly
/// promised an alert that could never arrive.
class ReminderOutcome {
  const ReminderOutcome({
    required this.notificationsAllowed,
    required this.delivery,
  });

  /// Whether the OS will actually let a notification through. When false, the
  /// reminder is still registered, so enabling notifications later revives it.
  final bool notificationsAllowed;

  final ReminderDelivery delivery;

  bool get usedExactAlarm => delivery == ReminderDelivery.exactAlarm;

  /// A short, user-facing caveat, or null when the reminder will fire as asked.
  ///
  /// [ReminderDelivery.deferredWork] is deliberately not a caveat: a reminder
  /// days away is *expected* to go through WorkManager, and saying so on every
  /// save would be noise.
  String? get caveat {
    if (!notificationsAllowed) {
      return 'Saved, but notifications are off — this reminder cannot alert '
          'you until you enable them in system settings.';
    }
    if (delivery == ReminderDelivery.inexactAlarm) {
      return 'Saved — exact alarms are off, so this may fire a few minutes '
          'late.';
    }
    return null;
  }
}

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

  /// Requests the permissions a time-based reminder needs, then schedules it.
  ///
  /// The returned [ReminderOutcome] carries whatever the user needs to be told
  /// — a denied notification permission, or exact-alarm delivery downgraded to
  /// best-effort. The caller is responsible for surfacing
  /// [ReminderOutcome.caveat]; dropping it puts the app back to silently
  /// promising alerts it cannot deliver.
  Future<ReminderOutcome> scheduleReminder(Note note) async {
    final scheduledDate = note.resolvedDatetime;
    if (scheduledDate == null) {
      throw ArgumentError('Note ${note.id} has no resolvedDatetime to schedule');
    }
    final noteId = note.id;
    if (noteId == null) {
      throw ArgumentError('Note must be persisted (have an id) before scheduling');
    }

    final notificationsAllowed =
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
      return ReminderOutcome(
        notificationsAllowed: notificationsAllowed,
        delivery: canUseExact
            ? ReminderDelivery.exactAlarm
            : ReminderDelivery.inexactAlarm,
      );
    } else {
      await workManagerService.scheduleNoteReminder(
        noteId: noteId,
        scheduledDate: scheduledDate,
      );
      return ReminderOutcome(
        notificationsAllowed: notificationsAllowed,
        delivery: ReminderDelivery.deferredWork,
      );
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
