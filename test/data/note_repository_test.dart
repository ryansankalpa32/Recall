import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/local/database/app_database.dart';
import 'package:recall/data/repositories/note_repository.dart';
import 'package:recall/domain/models/enums/note_status.dart';
import 'package:recall/domain/models/enums/trigger_type.dart';
import 'package:recall/domain/models/note.dart';

void main() {
  late AppDatabase db;
  late NoteRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftNoteRepository(db);
  });

  tearDown(() => db.close());

  Note buildNote({DateTime? resolvedDatetime}) {
    final now = DateTime.now();
    return Note(
      rawText: 'pick up shoes',
      taskDescription: 'pick up shoes',
      triggerType: resolvedDatetime == null ? TriggerType.none : TriggerType.time,
      resolvedDatetime: resolvedDatetime,
      status: resolvedDatetime == null ? NoteStatus.pending : NoteStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('insertNote then getNote round-trips the note', () async {
    final id = await repo.insertNote(buildNote());
    final fetched = await repo.getNote(id);

    expect(fetched, isNotNull);
    expect(fetched!.rawText, 'pick up shoes');
    expect(fetched.triggerType, TriggerType.none);
    expect(fetched.status, NoteStatus.pending);
  });

  test('watchAllNotes starts empty', () async {
    expect(await repo.watchAllNotes().first, isEmpty);
  });

  test('watchAllNotes reflects an inserted note', () async {
    await repo.insertNote(buildNote());

    final notes = await repo.watchAllNotes().first;
    expect(notes, hasLength(1));
    expect(notes.single.taskDescription, 'pick up shoes');
  });

  test('updateNote persists status changes (e.g. marking done)', () async {
    final scheduledFor = DateTime.now().add(const Duration(hours: 1));
    final id = await repo.insertNote(buildNote(resolvedDatetime: scheduledFor));
    final note = await repo.getNote(id);

    await repo.updateNote(note!.copyWith(status: NoteStatus.done));
    final updated = await repo.getNote(id);

    expect(updated!.status, NoteStatus.done);
  });

  test('deleteNote removes the note', () async {
    final id = await repo.insertNote(buildNote());
    await repo.deleteNote(id);

    expect(await repo.getNote(id), isNull);
  });
}
