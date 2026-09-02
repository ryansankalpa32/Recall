// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserPlaceTableTable get userPlaceTable => attachedDatabase.userPlaceTable;
  $NoteTableTable get noteTable => attachedDatabase.noteTable;
  NoteDaoManager get managers => NoteDaoManager(this);
}

class NoteDaoManager {
  final _$NoteDaoMixin _db;
  NoteDaoManager(this._db);
  $$UserPlaceTableTableTableManager get userPlaceTable =>
      $$UserPlaceTableTableTableManager(
        _db.attachedDatabase,
        _db.userPlaceTable,
      );
  $$NoteTableTableTableManager get noteTable =>
      $$NoteTableTableTableManager(_db.attachedDatabase, _db.noteTable);
}
