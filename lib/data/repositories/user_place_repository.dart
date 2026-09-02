import 'package:drift/drift.dart';

import '../../domain/models/user_place.dart';
import '../local/database/app_database.dart';

abstract class UserPlaceRepository {
  Stream<List<UserPlace>> watchAllPlaces();
  Future<UserPlace?> getPlace(int id);
  Future<int> insertPlace(UserPlace place);
  Future<void> updatePlace(UserPlace place);
  Future<void> deletePlace(int id);
}

class DriftUserPlaceRepository implements UserPlaceRepository {
  DriftUserPlaceRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<UserPlace>> watchAllPlaces() => _db.userPlaceDao
      .watchAllPlaces()
      .map((rows) => rows.map(_toDomain).toList());

  @override
  Future<UserPlace?> getPlace(int id) async {
    final row = await _db.userPlaceDao.getPlace(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insertPlace(UserPlace place) =>
      _db.userPlaceDao.insertPlace(_toCompanion(place));

  @override
  Future<void> updatePlace(UserPlace place) =>
      _db.userPlaceDao.updatePlace(_toCompanion(place));

  @override
  Future<void> deletePlace(int id) => _db.userPlaceDao.deletePlace(id);

  UserPlace _toDomain(UserPlaceRow row) => UserPlace(
        id: row.id,
        label: row.label,
        customName: row.customName,
        lat: row.lat ?? 0,
        lng: row.lng ?? 0,
        radiusM: row.radiusM,
        source: row.source,
        createdAt: row.createdAt,
      );

  UserPlaceTableCompanion _toCompanion(UserPlace place) =>
      UserPlaceTableCompanion(
        id: place.id == null ? const Value.absent() : Value(place.id!),
        label: Value(place.label),
        customName: Value(place.customName),
        lat: Value(place.lat),
        lng: Value(place.lng),
        radiusM: Value(place.radiusM),
        source: Value(place.source),
        createdAt: Value(place.createdAt),
      );
}
