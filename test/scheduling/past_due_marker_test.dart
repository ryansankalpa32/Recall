import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall/data/local/database/app_database.dart';
import 'package:recall/data/repositories/note_repository.dart';
import 'package:recall/domain/models/enums/note_status.dart';
import 'package:recall/domain/models/enums/trigger_type.dart';
import 'package:recall/domain/models/note.dart';
import 'package:recall/features/scheduling/past_due_marker.dart';
import 'package:recall/features/sync/firestore_sync_service.dart';

class MockFirestoreSyncService extends Mock implements FirestoreSyncService {}

void main() {
  late AppDatabase db;
  late NoteRepository repo;
  late MockFirestoreSyncService sync;
  late PastDueMarker marker;

  setUpAll(() {
    final now = DateTime.now();
    registerFallbackValue(Note(
      rawText: '',
      taskDescription: '',
      triggerType: TriggerType.none,
      status: NoteStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftNoteRepository(db);
    sync = MockFirestoreSyncService();
    when(() => sync.pushNote(any())).thenAnswer((_) async {});
    marker = PastDueMarker(noteRepository: repo, syncService: sync);
  });

  tearDown(() => db.close());

  /// Whole seconds: drift stores dateTime() columns as unix seconds.
  DateTime at(int y, int m, int d, int h) => DateTime(y, m, d, h);

  Future<int> insert(NoteStatus status, DateTime? when) {
    final created = at(2026, 1, 1, 0);
    return repo.insertNote(Note(
      rawText: 'x',
      taskDescription: 'x',
      triggerType: when == null ? TriggerType.none : TriggerType.time,
      resolvedDatetime: when,
      status: status,
      createdAt: created,
      updatedAt: created,
    ));
  }

  test('marks only scheduled notes whose time has passed, and syncs them',
      () async {
    final now = at(2026, 6, 1, 12);
    final past = await insert(NoteStatus.scheduled, at(2026, 6, 1, 9));
    final future = await insert(NoteStatus.scheduled, at(2026, 6, 1, 15));
    final pending = await insert(NoteStatus.pending, null);
    final done = await insert(NoteStatus.done, at(2026, 6, 1, 8));

    expect(await marker.markPastDue(now: now), 1);

    expect((await repo.getNote(past))!.status, NoteStatus.notified);
    expect((await repo.getNote(future))!.status, NoteStatus.scheduled);
    expect((await repo.getNote(pending))!.status, NoteStatus.pending);
    expect((await repo.getNote(done))!.status, NoteStatus.done);

    final pushed =
        verify(() => sync.pushNote(captureAny())).captured.cast<Note>();
    expect(pushed.single.id, past);
    expect(pushed.single.status, NoteStatus.notified);
  });

  test('is a no-op when nothing is due', () async {
    await insert(NoteStatus.scheduled, at(2026, 6, 1, 15));

    expect(await marker.markPastDue(now: at(2026, 6, 1, 12)), 0);
    verifyNever(() => sync.pushNote(any()));
  });
}
