import '../backend/recall_api_client.dart';
import 'note_parser.dart';

/// The real [NoteParser]: delegates straight to the backend proxy.
///
/// Thin by design. `NoteParser` and `RecallApiClient` are kept as separate
/// abstractions (see their doc comments) so the note-parsing seam the UI
/// depends on stays independent of whichever transport the backend uses —
/// this class is the whole of the coupling between them.
class BackendNoteParser implements NoteParser {
  const BackendNoteParser(this._client);

  final RecallApiClient _client;

  @override
  Future<ParsedNote> parse(String rawText) => _client.parseNote(rawText);
}
