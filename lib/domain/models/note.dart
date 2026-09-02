import 'enums/geofence_transition.dart';
import 'enums/location_kind.dart';
import 'enums/note_status.dart';
import 'enums/trigger_type.dart';

/// A single note and everything needed to resolve its reminder trigger.
///
/// Mirrors the full field set from README.md's data model. Phase 1 only
/// ever constructs [TriggerType.time]/[TriggerType.none] and leaves the
/// location-related fields null — they're modeled now so Phases 3+ populate
/// them rather than requiring a schema migration. See the plan's Phase 1
/// section (`data/local/database/tables/note_table.dart`) for the backing
/// drift table.
class Note {
  const Note({
    this.id,
    required this.rawText,
    required this.taskDescription,
    required this.triggerType,
    this.locationKind,
    this.geofenceTransition,
    this.resolvedDatetime,
    this.recurrenceRule,
    this.confidence,
    required this.status,
    this.userPlaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Null for a not-yet-persisted note.
  final int? id;

  /// What the user typed.
  final String rawText;

  /// Cleaned-up task text. Phase 1 mirrors [rawText] unless the user edits
  /// it separately; Phase 2 replaces this with the AI-parsed version.
  final String taskDescription;

  final TriggerType triggerType;

  /// Always null in Phase 1 (no location triggers yet).
  final LocationKind? locationKind;

  /// Always null in Phase 1.
  final GeofenceTransition? geofenceTransition;

  /// Set when [triggerType] is [TriggerType.time] or [TriggerType.both].
  final DateTime? resolvedDatetime;

  /// RRULE string for repeating reminders. No UI in Phase 1.
  final String? recurrenceRule;

  /// From the AI parse. Always null for manually-entered notes (Phase 1) —
  /// manual entry is fully confident by construction.
  final double? confidence;

  final NoteStatus status;

  /// FK to a [UserPlace]. Unused until Phase 3.
  final int? userPlaceId;

  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    int? id,
    String? rawText,
    String? taskDescription,
    TriggerType? triggerType,
    LocationKind? locationKind,
    GeofenceTransition? geofenceTransition,
    DateTime? resolvedDatetime,
    String? recurrenceRule,
    double? confidence,
    NoteStatus? status,
    int? userPlaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      taskDescription: taskDescription ?? this.taskDescription,
      triggerType: triggerType ?? this.triggerType,
      locationKind: locationKind ?? this.locationKind,
      geofenceTransition: geofenceTransition ?? this.geofenceTransition,
      resolvedDatetime: resolvedDatetime ?? this.resolvedDatetime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      userPlaceId: userPlaceId ?? this.userPlaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
