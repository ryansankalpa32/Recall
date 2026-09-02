// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_place_dao.dart';

// ignore_for_file: type=lint
mixin _$UserPlaceDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserPlaceTableTable get userPlaceTable => attachedDatabase.userPlaceTable;
  UserPlaceDaoManager get managers => UserPlaceDaoManager(this);
}

class UserPlaceDaoManager {
  final _$UserPlaceDaoMixin _db;
  UserPlaceDaoManager(this._db);
  $$UserPlaceTableTableTableManager get userPlaceTable =>
      $$UserPlaceTableTableTableManager(
        _db.attachedDatabase,
        _db.userPlaceTable,
      );
}
