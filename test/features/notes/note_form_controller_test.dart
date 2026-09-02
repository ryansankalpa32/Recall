import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall/core/providers/core_providers.dart';
import 'package:recall/data/local/database/app_database.dart';
import 'package:recall/domain/models/enums/note_status.dart';
import 'package:recall/domain/models/enums/trigger_type.dart';
import 'package:recall/domain/models/note.dart';
import 'package:recall/features/notes/presentation/providers/note_form_controller.dart';
import 'package:recall/features/scheduling/scheduling_service.dart';

class MockSchedulingService extends Mock implements SchedulingService {}

void main() {
  setUpAll(() {
    final now = DateTime.now();
    registerFallbackValue(
      Note(
        rawText: '',
        taskDescription: '',
        triggerType: TriggerType.none,
        status: NoteStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  late AppDatabase db;
  late MockSchedulingService scheduling;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scheduling = MockSchedulingService();
    when(() => scheduling.scheduleReminder(any())).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        schedulingServiceProvider.overrideWithValue(scheduling),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('save() refuses empty text', () async {
    final controller = container.read(noteFormControllerProvider.notifier);

    expect(await controller.save(), isFalse);
    expect(await container.read(noteRepositoryProvider).watchAllNotes().first,
        isEmpty);
  });

  test('a note with no time picked is saved as NONE/PENDING and not scheduled',
      () async {
    final controller = container.read(noteFormControllerProvider.notifier);
    controller.setRawText('  pick up shoes  ');

    expect(await controller.save(), isTrue);

    final notes = await container.read(noteRepositoryProvider).watchAllNotes().first;
    expect(notes, hasLength(1));
    expect(notes.single.taskDescription, 'pick up shoes', reason: 'trimmed');
    expect(notes.single.triggerType, TriggerType.none);
    expect(notes.single.status, NoteStatus.pending);
    expect(notes.single.resolvedDatetime, isNull);
    verifyNever(() => scheduling.scheduleReminder(any()));
  });

  test('a note with a time picked is saved as TIME/SCHEDULED and scheduled',
      () async {
    final when0 = DateTime.now().add(const Duration(hours: 2));
    final controller = container.read(noteFormControllerProvider.notifier);
    controller.setRawText('call mum');
    controller.setPickedDateTime(when0);

    expect(await controller.save(), isTrue);

    final notes = await container.read(noteRepositoryProvider).watchAllNotes().first;
    expect(notes, hasLength(1));
    expect(notes.single.triggerType, TriggerType.time);
    expect(notes.single.status, NoteStatus.scheduled);
    expect(notes.single.resolvedDatetime, when0);

    // The scheduler must receive the persisted note — i.e. with its DB id
    // filled in, since cancellation later keys off that id.
    final scheduled = verify(() => scheduling.scheduleReminder(captureAny()))
        .captured
        .single as Note;
    expect(scheduled.id, isNotNull);
  });

  test('the form resets after a successful save', () async {
    final controller = container.read(noteFormControllerProvider.notifier);
    controller.setRawText('pick up shoes');
    await controller.save();

    final state = container.read(noteFormControllerProvider);
    expect(state.rawText, isEmpty);
    expect(state.pickedDateTime, isNull);
    expect(state.isSaving, isFalse);
  });
}
