/// The AI parser's output for one note.
///
/// Deliberately has **no `lat`/`lng` fields** — only a symbolic
/// [locationValue] (e.g. `"home"`, `"shoe_store"`). This is the structural
/// enforcement of Claude.md's hard constraint "the AI parser never resolves
/// coordinates": turning [locationValue] into coordinates is only ever done
/// by `UserPlaceRepository`/`GeofenceService`, in a different part of the
/// tree. Unused until Phase 2.
class ParsedNote {
  const ParsedNote({
    required this.taskDescription,
    required this.triggerType,
    this.locationKind,
    this.locationValue,
    this.resolvedDatetime,
    this.recurrenceRule,
    required this.confidence,
  });

  final String taskDescription;

  /// Matches [TriggerType.name] — kept as a raw string here so this file has
  /// no dependency on the domain layer's enum, since Phase 1 never imports
  /// this file at all.
  final String triggerType;

  final String? locationKind;

  /// Symbolic location reference, e.g. `"home"` or `"shoe_store"` — never a
  /// coordinate.
  final String? locationValue;

  final DateTime? resolvedDatetime;
  final String? recurrenceRule;
  final double confidence;
}

/// Backend-proxied note parser. Implemented in Phase 2 against the backend's
/// `/parse-note` endpoint (see `services/backend/recall_api_client.dart`) —
/// never called from Phase 1 UI.
abstract class NoteParser {
  Future<ParsedNote> parse(String rawText);
}

class UnimplementedNoteParser implements NoteParser {
  const UnimplementedNoteParser();

  @override
  Future<ParsedNote> parse(String rawText) {
    throw UnimplementedError(
      'NoteParser is a Phase 2 feature (AI-parsed free-text time/location '
      'expressions) — see Claude.md build order. Not wired into Phase 1 UI.',
    );
  }
}
