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
import 'package:recall/services/ai/note_parser.dart';

class MockSchedulingService extends Mock implements SchedulingService {}

class MockNoteParser extends Mock implements NoteParser {}

/// Drift stores `dateTime()` columns as whole unix seconds, so a [DateTime]
/// carrying microseconds does not survive the round trip through the database.
///
/// Production never hits this — the backend emits `HH:mm:ss` and the manual
/// picker is minute-precision — but `DateTime.now()` in a test does, which is
/// what made the equivalent Phase 1 assertion fail.
DateTime secondsFromNow(Duration offset) {
  final t = DateTime.now().add(offset);
  return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
}

ParsedNote timeParse(DateTime when, {String task = 'call mum'}) => ParsedNote(
      taskDescription: task,
      triggerType: 'time',
      resolvedDatetime: when,
      confidence: 0.93,
    );

const noneParse = ParsedNote(
  taskDescription: 'buy shoes',
  triggerType: 'none',
  confidence: 0.9,
);

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
  late MockNoteParser parser;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scheduling = MockSchedulingService();
    parser = MockNoteParser();
    when(() => scheduling.scheduleReminder(any())).thenAnswer(
      (_) async => const ReminderOutcome(
        notificationsAllowed: true,
        delivery: ReminderDelivery.exactAlarm,
      ),
    );

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        schedulingServiceProvider.overrideWithValue(scheduling),
        noteParserProvider.overrideWithValue(parser),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  NoteFormController controller() =>
      container.read(noteFormControllerProvider.notifier);
  NoteFormState formState() => container.read(noteFormControllerProvider);
  Future<List<Note>> notes() =>
      container.read(noteRepositoryProvider).watchAllNotes().first;

  test('submit() refuses empty text', () async {
    expect(await controller().submit(), isFalse);
    expect(await notes(), isEmpty);
    verifyNever(() => parser.parse(any()));
  });

  test('submit() parses and stops at the confirmation stage without saving',
      () async {
    final when0 = secondsFromNow(const Duration(hours: 2));
    when(() => parser.parse(any())).thenAnswer((_) async => timeParse(when0));

    final c = controller();
    c.setRawText('  call mum at 4pm  ');

    expect(await c.submit(), isFalse, reason: 'the sheet must stay open');
    expect(formState().stage, CaptureStage.confirming);
    expect(formState().parsed?.resolvedDatetime, when0);
    expect(await notes(), isEmpty,
        reason: 'nothing is committed before confirm');
    verifyNever(() => scheduling.scheduleReminder(any()));

    // The trimmed text is what gets parsed.
    verify(() => parser.parse('call mum at 4pm')).called(1);
  });

  test('confirm() persists the parsed note and schedules it', () async {
    final when0 = secondsFromNow(const Duration(hours: 2));
    when(() => parser.parse(any())).thenAnswer((_) async => timeParse(when0));

    final c = controller();
    c.setRawText('call mum at 4pm');
    await c.submit();

    expect(await c.confirm(), isTrue);

    final saved = await notes();
    expect(saved, hasLength(1));
    expect(saved.single.rawText, 'call mum at 4pm');
    expect(saved.single.taskDescription, 'call mum',
        reason: 'the AI-cleaned task, not the raw text');
    expect(saved.single.triggerType, TriggerType.time);
    expect(saved.single.status, NoteStatus.scheduled);
    expect(saved.single.resolvedDatetime, when0);
    expect(saved.single.confidence, 0.93);

    // Scheduling keys off the DB id, so the persisted note must be the one
    // handed to the scheduler.
    final scheduled = verify(() => scheduling.scheduleReminder(captureAny()))
        .captured
        .single as Note;
    expect(scheduled.id, isNotNull);
  });

  test('a parse with no time saves as NONE/PENDING and is never scheduled',
      () async {
    when(() => parser.parse(any())).thenAnswer((_) async => noneParse);

    final c = controller();
    c.setRawText('buy shoes');
    await c.submit();

    expect(formState().stage, CaptureStage.confirming);
    expect(await c.confirm(), isTrue);

    final saved = await notes();
    expect(saved.single.triggerType, TriggerType.none);
    expect(saved.single.status, NoteStatus.pending);
    expect(saved.single.resolvedDatetime, isNull);
    verifyNever(() => scheduling.scheduleReminder(any()));
  });

  test('a hand-picked time bypasses the parser entirely', () async {
    final when0 = secondsFromNow(const Duration(hours: 2));
    final c = controller();
    c.setRawText('call mum');
    c.setPickedDateTime(when0);

    expect(await c.submit(), isTrue);

    final saved = await notes();
    expect(saved.single.triggerType, TriggerType.time);
    expect(saved.single.resolvedDatetime, when0);
    expect(saved.single.confidence, isNull,
        reason: 'manual entry is confident by construction');
    verifyNever(() => parser.parse(any()));
    verify(() => scheduling.scheduleReminder(any())).called(1);
  });

  test('a failed parse degrades to the manual path instead of blocking',
      () async {
    when(() => parser.parse(any()))
        .thenThrow(const NoteParseException('offline'));

    final c = controller();
    c.setRawText('call mum at 4pm');

    expect(await c.submit(), isFalse);
    expect(formState().stage, CaptureStage.editing);
    expect(formState().parseFailed, isTrue);
    expect(formState().error, isA<NoteParseException>());
    expect(await notes(), isEmpty);
    verifyNever(() => scheduling.scheduleReminder(any()));

    // The second tap must save rather than retry the parser, so a note can
    // always be written even with no backend reachable.
    expect(await c.submit(), isTrue);
    final saved = await notes();
    expect(saved.single.taskDescription, 'call mum at 4pm');
    expect(saved.single.triggerType, TriggerType.none);
    verify(() => parser.parse(any())).called(1);
  });

  test('a location trigger is rejected as unsupported in this phase', () async {
    when(() => parser.parse(any())).thenAnswer(
      (_) async => const ParsedNote(
        taskDescription: 'homework',
        triggerType: 'location',
        locationKind: 'PERSONAL',
        locationValue: 'home',
        confidence: 0.9,
      ),
    );

    final c = controller();
    c.setRawText('homework in maths');

    expect(await c.submit(), isFalse);
    expect(formState().stage, CaptureStage.editing);
    expect(formState().parseFailed, isTrue);
    expect(await notes(), isEmpty);
  });

  test('a parse whose trigger type and time disagree is rejected', () async {
    when(() => parser.parse(any())).thenAnswer(
      (_) async => const ParsedNote(
        taskDescription: 'call mum',
        triggerType: 'time',
        confidence: 0.9,
      ),
    );

    final c = controller();
    c.setRawText('call mum at 4pm');

    expect(await c.submit(), isFalse);
    expect(formState().parseFailed, isTrue);
    expect(await notes(), isEmpty);
  });

  test('editing the time on the confirmation card overrides the parse',
      () async {
    final parsedWhen = secondsFromNow(const Duration(hours: 2));
    final chosenWhen = secondsFromNow(const Duration(days: 1));
    when(() => parser.parse(any()))
        .thenAnswer((_) async => timeParse(parsedWhen));

    final c = controller();
    c.setRawText('call mum at 4pm');
    await c.submit();
    c.setPickedDateTime(chosenWhen);

    expect(await c.confirm(), isTrue);

    final saved = await notes();
    expect(saved.single.resolvedDatetime, chosenWhen);
    expect(saved.single.confidence, isNull,
        reason: 'an overridden time is no longer an AI interpretation');
  });

  test('backToEditing() drops the interpretation but keeps the text', () async {
    final when0 = secondsFromNow(const Duration(hours: 2));
    when(() => parser.parse(any())).thenAnswer((_) async => timeParse(when0));

    final c = controller();
    c.setRawText('call mum at 4pm');
    await c.submit();
    c.backToEditing();

    expect(formState().stage, CaptureStage.editing);
    expect(formState().parsed, isNull);
    expect(formState().rawText, 'call mum at 4pm');
  });

  test('the form resets after a successful save', () async {
    when(() => parser.parse(any())).thenAnswer((_) async => noneParse);

    final c = controller();
    c.setRawText('buy shoes');
    await c.submit();
    await c.confirm();

    final state = formState();
    expect(state.rawText, isEmpty);
    expect(state.pickedDateTime, isNull);
    expect(state.parsed, isNull);
    expect(state.stage, CaptureStage.editing);
    expect(state.parseFailed, isFalse);
  });
}
