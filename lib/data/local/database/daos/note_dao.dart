import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_table.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [NoteTable])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  /// Reactive — the UI's [notesListProvider] wraps this directly so inserts
  /// and updates refresh the list with no manual invalidation.
  Stream<List<NoteRow>> watchAllNotes() {
    return (select(noteTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<NoteRow?> watchNote(int id) {
    return (select(noteTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<NoteRow?> getNote(int id) {
    return (select(noteTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertNote(NoteTableCompanion entry) =>
      into(noteTable).insert(entry);

  Future<bool> updateNote(NoteTableCompanion entry) =>
      update(noteTable).replace(entry);

  Future<int> deleteNote(int id) =>
      (delete(noteTable)..where((t) => t.id.equals(id))).go();
}
