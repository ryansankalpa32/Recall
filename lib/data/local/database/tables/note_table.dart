import 'package:drift/drift.dart';

import '../../../../domain/models/enums/geofence_transition.dart';
import '../../../../domain/models/enums/location_kind.dart';
import '../../../../domain/models/enums/note_status.dart';
import '../../../../domain/models/enums/trigger_type.dart';
import 'user_place_table.dart';

class TriggerTypeConverter extends TypeConverter<TriggerType, String> {
  const TriggerTypeConverter();

  @override
  TriggerType fromSql(String fromDb) => TriggerType.fromName(fromDb);

  @override
  String toSql(TriggerType value) => value.name;
}

class LocationKindConverter extends TypeConverter<LocationKind?, String?> {
  const LocationKindConverter();

  @override
  LocationKind? fromSql(String? fromDb) =>
      fromDb == null ? null : LocationKind.fromName(fromDb);

  @override
  String? toSql(LocationKind? value) => value?.name;
}

class GeofenceTransitionConverter
    extends TypeConverter<GeofenceTransition?, String?> {
  const GeofenceTransitionConverter();

  @override
  GeofenceTransition? fromSql(String? fromDb) =>
      fromDb == null ? null : GeofenceTransition.fromName(fromDb);

  @override
  String? toSql(GeofenceTransition? value) => value?.name;
}

class NoteStatusConverter extends TypeConverter<NoteStatus, String> {
  const NoteStatusConverter();

  @override
  NoteStatus fromSql(String fromDb) => NoteStatus.fromName(fromDb);

  @override
  String toSql(NoteStatus value) => value.name;
}

/// Backs [Note] (see `domain/models/note.dart`). Every README data-model
/// column is present from Phase 1 — most stay null until the phase that
/// gives them meaning (see the field-level comments below and the plan's
/// Phase 1 section), so later phases populate columns instead of migrating.
@DataClassName('NoteRow')
class NoteTable extends Table {
  @override
  String get tableName => 'notes';

  IntColumn get id => integer().autoIncrement()();

  /// What the user typed.
  TextColumn get rawText => text()();

  /// Phase 1 mirrors [rawText] unless edited; Phase 2 replaces it with the
  /// AI-parsed task text.
  TextColumn get taskDescription => text()();

  TextColumn get triggerType =>
      text().map(const TriggerTypeConverter())();

  /// Null in Phase 1 — no location triggers yet.
  TextColumn get locationKind =>
      text().nullable().map(const LocationKindConverter())();

  /// Null in Phase 1.
  TextColumn get geofenceTransition =>
      text().nullable().map(const GeofenceTransitionConverter())();

  /// Set when [triggerType] resolves to a time.
  DateTimeColumn get resolvedDatetime => dateTime().nullable()();

  /// RRULE string. No UI in Phase 1.
  TextColumn get recurrenceRule => text().nullable()();

  /// From the AI parse; null for manually-entered notes.
  RealColumn get confidence => real().nullable()();

  TextColumn get status => text().map(const NoteStatusConverter())();

  /// FK to [UserPlaceTable]. Unused until Phase 3.
  IntColumn get userPlaceId =>
      integer().nullable().references(UserPlaceTable, #id)();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
