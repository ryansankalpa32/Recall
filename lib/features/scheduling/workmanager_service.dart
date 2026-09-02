import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database/app_database.dart';
import '../../domain/models/enums/note_status.dart';
import 'notification_service.dart';

const String kNoteReminderTask = 'noteReminderTask';
const String kNoteIdInputKey = 'noteId';

/// Top-level entry point WorkManager invokes on a background isolate.
///
/// Must stay top-level (not a class method/closure) and keep the
/// `@pragma('vm:entry-point')` annotation, or the Dart compiler strips it
/// and background execution silently never fires. Registered once, in
/// `bootstrap.dart`.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kNoteReminderTask) return true;

    final noteId = inputData?[kNoteIdInputKey] as int?;
    if (noteId == null) return false;

    // The background isolate has no Riverpod container from the main
    // isolate — reopen the same on-disk database file directly (see
    // AppDatabase's doc comment).
    final db = AppDatabase.forBackgroundIsolate();
    try {
      final note = await db.noteDao.getNote(noteId);
      if (note == null || note.status == NoteStatus.done) {
        // Deleted or already completed since scheduling — nothing to show.
        return true;
      }

      final plugin = FlutterLocalNotificationsPlugin();
      final notificationService = NotificationService(plugin);
      await notificationService.init();
      await notificationService.showImmediate(
        noteId: noteId,
        title: 'Recall',
        body: note.taskDescription,
      );

      await db.noteDao.updateNote(
        NoteTableCompanion(
          id: Value(noteId),
          status: const Value(NoteStatus.notified),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    } finally {
      await db.close();
    }
  });
}

/// Registers/cancels the WorkManager side of a note's reminder. Used for
/// longer-term deferred delivery, alongside `NotificationService`'s
/// near-term exact `zonedSchedule` — see `SchedulingService` for which one
/// gets picked.
class WorkManagerService {
  const WorkManagerService();

  Future<void> init() {
    return Workmanager().initialize(callbackDispatcher);
  }

  Future<void> scheduleNoteReminder({
    required int noteId,
    required DateTime scheduledDate,
  }) {
    final delay = scheduledDate.difference(DateTime.now());
    return Workmanager().registerOneOffTask(
      'note-$noteId',
      kNoteReminderTask,
      inputData: {kNoteIdInputKey: noteId},
      initialDelay: delay.isNegative ? Duration.zero : delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> cancelNoteReminder(int noteId) {
    return Workmanager().cancelByUniqueName('note-$noteId');
  }
}
