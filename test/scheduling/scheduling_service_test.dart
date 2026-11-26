import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall/domain/models/enums/note_status.dart';
import 'package:recall/domain/models/enums/trigger_type.dart';
import 'package:recall/domain/models/note.dart';
import 'package:recall/features/scheduling/notification_service.dart';
import 'package:recall/features/scheduling/permission_service.dart';
import 'package:recall/features/scheduling/scheduling_service.dart';
import 'package:recall/features/scheduling/workmanager_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockWorkManagerService extends Mock implements WorkManagerService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockNotificationService notificationService;
  late MockWorkManagerService workManagerService;
  late MockPermissionService permissionService;
  late SchedulingService scheduling;

  setUp(() {
    notificationService = MockNotificationService();
    workManagerService = MockWorkManagerService();
    permissionService = MockPermissionService();
    scheduling = SchedulingService(
      notificationService: notificationService,
      workManagerService: workManagerService,
      permissionService: permissionService,
    );

    when(() => permissionService.requestNotificationPermission())
        .thenAnswer((_) async => true);
    when(() => notificationService.requestExactAlarmsPermission())
        .thenAnswer((_) async => true);
    when(() => notificationService.canScheduleExactAlarms())
        .thenAnswer((_) async => true);
    when(() => notificationService.scheduleNoteReminder(
          noteId: any(named: 'noteId'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          useExactAlarm: any(named: 'useExactAlarm'),
        )).thenAnswer((_) async {});
    when(() => workManagerService.scheduleNoteReminder(
          noteId: any(named: 'noteId'),
          scheduledDate: any(named: 'scheduledDate'),
        )).thenAnswer((_) async {});
    when(() => notificationService.cancel(any())).thenAnswer((_) async {});
    when(() => workManagerService.cancelNoteReminder(any()))
        .thenAnswer((_) async {});
  });

  Note buildNote(DateTime scheduledFor) {
    final now = DateTime.now();
    return Note(
      id: 1,
      rawText: 'call mum',
      taskDescription: 'call mum',
      triggerType: TriggerType.time,
      resolvedDatetime: scheduledFor,
      status: NoteStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('near-term reminders use exact NotificationService scheduling', () async {
    final note = buildNote(DateTime.now().add(const Duration(minutes: 5)));

    final outcome = await scheduling.scheduleReminder(note);

    expect(outcome.usedExactAlarm, isTrue);
    expect(outcome.notificationsAllowed, isTrue);
    expect(outcome.caveat, isNull);
    verify(() => notificationService.scheduleNoteReminder(
          noteId: 1,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          useExactAlarm: true,
        )).called(1);
    verifyNever(() => workManagerService.scheduleNoteReminder(
          noteId: any(named: 'noteId'),
          scheduledDate: any(named: 'scheduledDate'),
        ));
  });

  test('far-out reminders use an inexact local alarm, not WorkManager',
      () async {
    final note = buildNote(DateTime.now().add(const Duration(days: 3)));

    final outcome = await scheduling.scheduleReminder(note);

    expect(outcome.usedExactAlarm, isFalse);
    expect(outcome.delivery, ReminderDelivery.deferredAlarm);
    expect(outcome.caveat, isNull,
        reason: 'an inexact alarm days ahead is expected, '
            'not something to warn about');
    verify(() => notificationService.scheduleNoteReminder(
          noteId: 1,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          useExactAlarm: false,
        )).called(1);
    verifyNever(() => notificationService.requestExactAlarmsPermission());
    verifyNever(() => workManagerService.scheduleNoteReminder(
          noteId: any(named: 'noteId'),
          scheduledDate: any(named: 'scheduledDate'),
        ));
  });

  test('near-term without exact-alarm allowance falls back with a caveat',
      () async {
    when(() => notificationService.canScheduleExactAlarms())
        .thenAnswer((_) async => false);
    final note = buildNote(DateTime.now().add(const Duration(minutes: 5)));

    final outcome = await scheduling.scheduleReminder(note);

    expect(outcome.delivery, ReminderDelivery.inexactAlarm);
    expect(outcome.caveat, isNotNull);
    verify(() => notificationService.scheduleNoteReminder(
          noteId: 1,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          useExactAlarm: false,
        )).called(1);
  });

  test('cancelReminder cancels the local alarm and legacy WorkManager task',
      () async {
    await scheduling.cancelReminder(1);

    verify(() => notificationService.cancel(1)).called(1);
    verify(() => workManagerService.cancelNoteReminder(1)).called(1);
  });

  test('cancelReminder tolerates an uninitialized WorkManager', () async {
    when(() => workManagerService.cancelNoteReminder(any()))
        .thenThrow(StateError('WorkManager not initialized'));

    await scheduling.cancelReminder(1);

    verify(() => notificationService.cancel(1)).called(1);
  });

  test('scheduleReminder throws for a note with no resolvedDatetime', () async {
    final now = DateTime.now();
    final note = Note(
      id: 1,
      rawText: 'x',
      taskDescription: 'x',
      triggerType: TriggerType.none,
      status: NoteStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    expect(() => scheduling.scheduleReminder(note), throwsArgumentError);
  });
}
