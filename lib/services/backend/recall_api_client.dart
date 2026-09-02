import '../ai/note_parser.dart';

/// Result of a Places nearby-category lookup. Symbolic/display data only —
/// see the coordinate-handling note on [ParsedNote].
class NearbyPlace {
  const NearbyPlace({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;
}

/// Client for the backend's thin proxy — the only thing in this app allowed
/// to reach the LLM/Places APIs, and only indirectly (the keys live on the
/// backend, never here). Per Claude.md: "No LLM or Places API key ever
/// ships in the Flutter app." When implemented (Phase 2+), this class must
/// only ever hold a non-secret base URL for the proxy itself.
///
/// Unimplemented in Phase 1 — nothing calls this yet.
abstract class RecallApiClient {
  Future<ParsedNote> parseNote(String rawText);
  Future<List<NearbyPlace>> placesNearby({
    required double lat,
    required double lng,
    required String category,
  });
}

class UnimplementedRecallApiClient implements RecallApiClient {
  const UnimplementedRecallApiClient();

  @override
  Future<ParsedNote> parseNote(String rawText) {
    throw UnimplementedError(
      'RecallApiClient.parseNote is a Phase 2 feature — not wired into '
      'Phase 1 UI. Backend hosting choice is still open (see the plan).',
    );
  }

  @override
  Future<List<NearbyPlace>> placesNearby({
    required double lat,
    required double lng,
    required String category,
  }) {
    throw UnimplementedError(
      'RecallApiClient.placesNearby is a Phase 4 feature (specific/category '
      'place triggers) — not wired into Phase 1 UI.',
    );
  }
}
