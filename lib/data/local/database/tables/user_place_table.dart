import 'package:drift/drift.dart';

import '../../../../domain/models/user_place.dart';

class UserPlaceSourceConverter
    extends TypeConverter<UserPlaceSource, String> {
  const UserPlaceSourceConverter();

  @override
  UserPlaceSource fromSql(String fromDb) => UserPlaceSource.fromName(fromDb);

  @override
  String toSql(UserPlaceSource value) => value.name;
}

/// Backs [UserPlace]. `lat`/`lng` are nullable at the schema level (a place
/// could in principle exist without coordinates), but Phase 1's
/// `PlaceEditScreen` always sets them via the map-picker before save — see
/// the plan's "Place coordinates" decision.
@DataClassName('UserPlaceRow')
class UserPlaceTable extends Table {
  @override
  String get tableName => 'user_places';

  IntColumn get id => integer().autoIncrement()();

  /// `home` / `work` / `school` / `other` / a custom label.
  TextColumn get label => text()();

  TextColumn get customName => text().nullable()();

  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();

  /// Geofence radius in meters. Unused until geofencing exists (Phase 3+).
  IntColumn get radiusM => integer().withDefault(const Constant(150))();

  TextColumn get source => text().map(const UserPlaceSourceConverter())();

  DateTimeColumn get createdAt => dateTime()();
}
