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

  /// Far enough out that an inexact alarm is used on purpose; it may slip by
  /// minutes, which doesn't matter days ahead.
  deferredAlarm,
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
  /// [ReminderDelivery.deferredAlarm] is deliberately not a caveat: a reminder
  /// days away is *expected* to use an inexact alarm, and saying so on every
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

/// Schedules a note's time-based reminder as a local alarm and keeps it in
/// sync with note lifecycle changes (save / done).
///
/// Delivery is "alarm first, push as backup": every reminder is a local
/// `zonedSchedule` alarm, which works offline and survives Doze and app
/// swipe-away. Notes synced with `localAlarm: true` (see
/// `FirestoreSyncService`) are skipped by the server's FCM cron job, so the
/// user never gets the reminder twice.
///
/// - Near-term reminders (within [_exactScheduleThreshold]) use Android's
///   exact-alarm path when allowed.
/// - Farther-out reminders use an inexact alarm, which is fine days ahead.
///
/// WorkManager is no longer used for delivery; [workManagerService] is kept
/// only to cancel tasks registered by older builds.
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

    final nearTerm =
        scheduledDate.difference(DateTime.now()) <= _exactScheduleThreshold;

    var useExact = false;
    if (nearTerm) {
      final exactGranted =
          await notificationService.requestExactAlarmsPermission();
      useExact =
          exactGranted && await notificationService.canScheduleExactAlarms();
    }

    await notificationService.scheduleNoteReminder(
      noteId: noteId,
      title: 'Recall',
      body: note.taskDescription,
      scheduledDate: scheduledDate,
      useExactAlarm: useExact,
    );

    return ReminderOutcome(
      notificationsAllowed: notificationsAllowed,
      delivery: useExact
          ? ReminderDelivery.exactAlarm
          : nearTerm
              ? ReminderDelivery.inexactAlarm
              : ReminderDelivery.deferredAlarm,
    );
  }

  /// Cancels any pending delivery for [noteId] — called when a note is
  /// marked done or deleted, so it never fires late.
  Future<void> cancelReminder(int noteId) async {
    await notificationService.cancel(noteId);
    // Legacy: older builds registered WorkManager tasks. WorkManager is not
    // initialized any more, so this can throw; it must never block the
    // caller (e.g. marking a note done must still sync).
    try {
      await workManagerService.cancelNoteReminder(noteId);
    } catch (_) {}
  }
}
