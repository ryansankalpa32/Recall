import 'package:drift/drift.dart';

import '../../domain/models/note.dart';
import '../local/database/app_database.dart';

abstract class NoteRepository {
  Stream<List<Note>> watchAllNotes();
  Stream<Note?> watchNote(int id);
  Future<Note?> getNote(int id);
  Future<int> insertNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
}

class DriftNoteRepository implements NoteRepository {
  DriftNoteRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Note>> watchAllNotes() =>
      _db.noteDao.watchAllNotes().map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<Note?> watchNote(int id) =>
      _db.noteDao.watchNote(id).map((row) => row == null ? null : _toDomain(row));

  @override
  Future<Note?> getNote(int id) async {
    final row = await _db.noteDao.getNote(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insertNote(Note note) => _db.noteDao.insertNote(_toCompanion(note));

  @override
  Future<void> updateNote(Note note) => _db.noteDao.updateNote(_toCompanion(note));

  @override
  Future<void> deleteNote(int id) => _db.noteDao.deleteNote(id);

  Note _toDomain(NoteRow row) => Note(
        id: row.id,
        rawText: row.rawText,
        taskDescription: row.taskDescription,
        triggerType: row.triggerType,
        locationKind: row.locationKind,
        geofenceTransition: row.geofenceTransition,
        resolvedDatetime: row.resolvedDatetime,
        recurrenceRule: row.recurrenceRule,
        confidence: row.confidence,
        status: row.status,
        userPlaceId: row.userPlaceId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  NoteTableCompanion _toCompanion(Note note) => NoteTableCompanion(
        id: note.id == null ? const Value.absent() : Value(note.id!),
        rawText: Value(note.rawText),
        taskDescription: Value(note.taskDescription),
        triggerType: Value(note.triggerType),
        locationKind: Value(note.locationKind),
        geofenceTransition: Value(note.geofenceTransition),
        resolvedDatetime: Value(note.resolvedDatetime),
        recurrenceRule: Value(note.recurrenceRule),
        confidence: Value(note.confidence),
        status: Value(note.status),
        userPlaceId: Value(note.userPlaceId),
        createdAt: Value(note.createdAt),
        updatedAt: Value(note.updatedAt),
      );
}
