import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/enums/note_status.dart';
import '../../../../domain/models/enums/trigger_type.dart';
import '../../../../domain/models/note.dart';
import '../../../../services/ai/note_parser.dart';

/// Where the capture sheet is in the write-a-note flow.
///
/// Phase 2 puts a parse-and-confirm step between typing and saving, because
/// Claude.md requires every AI-parsed note to show its interpretation before it
/// is committed. [confirming] is that step.
enum CaptureStage { editing, parsing, confirming, saving }

/// State for `NoteCaptureSheet`.
class NoteFormState {
  const NoteFormState({
    this.rawText = '',
    this.pickedDateTime,
    this.stage = CaptureStage.editing,
    this.parsed,
    this.parseFailed = false,
    this.error,
  });

  final String rawText;

  /// A time the user picked by hand. Overrides anything the parser resolved,
  /// and skips parsing entirely when set before the first submit.
  final DateTime? pickedDateTime;

  final CaptureStage stage;

  /// The interpretation being shown on the confirmation card. Null except in
  /// [CaptureStage.confirming].
  final ParsedNote? parsed;

  /// Set once parsing has failed for this note. The sheet then falls back to
  /// the Phase 1 behaviour — save exactly what was typed, with whatever time
  /// the user picks by hand — so an offline or rejected parse can never leave
  /// the user unable to save a note.
  final bool parseFailed;

  final Object? error;

  bool get isBusy =>
      stage == CaptureStage.parsing || stage == CaptureStage.saving;

  bool get canSubmit => rawText.trim().isNotEmpty && !isBusy;

  NoteFormState copyWith({
    String? rawText,
    DateTime? pickedDateTime,
    bool clearPickedDateTime = false,
    CaptureStage? stage,
    ParsedNote? parsed,
    bool clearParsed = false,
    bool? parseFailed,
    Object? error,
    bool clearError = false,
  }) {
    return NoteFormState(
      rawText: rawText ?? this.rawText,
      pickedDateTime:
          clearPickedDateTime ? null : (pickedDateTime ?? this.pickedDateTime),
      stage: stage ?? this.stage,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      parseFailed: parseFailed ?? this.parseFailed,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NoteFormController extends Notifier<NoteFormState> {
  @override
  NoteFormState build() => const NoteFormState();

  void setRawText(String text) {
    // Any existing interpretation is now stale.
    state = state.copyWith(
      rawText: text,
      clearParsed: true,
      clearError: true,
      stage: CaptureStage.editing,
    );
  }

  void setPickedDateTime(DateTime? dateTime) {
    state = dateTime == null
        ? state.copyWith(clearPickedDateTime: true, clearError: true)
        : state.copyWith(pickedDateTime: dateTime, clearError: true);
  }

  /// Returns to the text field from the confirmation card, keeping what was
  /// typed so the user can correct it.
  void backToEditing() {
    state = state.copyWith(
      stage: CaptureStage.editing,
      clearParsed: true,
      clearError: true,
    );
  }

  /// The Save tap.
  ///
  /// Returns whether the note was saved and the sheet should close. A `false`
  /// means either that the flow moved on to the confirmation card, or that
  /// something failed and the sheet should stay open showing why.
  ///
  /// A hand-picked time bypasses the parser completely: manual entry is fully
  /// confident by construction, and Claude.md's show-before-commit rule governs
  /// *AI-parsed* notes, so there is no interpretation to confirm.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    if (state.pickedDateTime != null || state.parseFailed) {
      return _persist(
        taskDescription: state.rawText.trim(),
        resolvedDatetime: state.pickedDateTime,
        confidence: null,
      );
    }

    await _parse();
    return false;
  }

  /// Commits the note shown on the confirmation card.
  Future<bool> confirm() async {
    final parsed = state.parsed;
    if (parsed == null || state.isBusy) return false;

    // "Edit time" on the card overrides whatever the parser resolved, and makes
    // the note manual again — hence a null confidence, matching Note's contract
    // that confidence is only ever set by a parse.
    final override = state.pickedDateTime;
    return _persist(
      taskDescription: parsed.taskDescription,
      resolvedDatetime: override ?? parsed.resolvedDatetime,
      confidence: override != null ? null : parsed.confidence,
    );
  }

  Future<void> _parse() async {
    state = state.copyWith(stage: CaptureStage.parsing, clearError: true);
    try {
      final parsed = await ref.read(noteParserProvider).parse(state.rawText.trim());

      // Phase 2 is time intelligence only. A location trigger is not something
      // this build can schedule, so treat it as a failed parse rather than
      // silently saving a note whose trigger will never fire.
      TriggerType? triggerType;
      try {
        triggerType = TriggerType.fromName(parsed.triggerType);
      } catch (_) {
        triggerType = null;
      }
      if (triggerType != TriggerType.time && triggerType != TriggerType.none) {
        throw NoteParseException(
          'Unsupported trigger type for this build: ${parsed.triggerType}',
        );
      }
      if ((triggerType == TriggerType.time) != (parsed.resolvedDatetime != null)) {
        throw const NoteParseException(
          'Parsed trigger type and resolved time disagree.',
        );
      }

      state = state.copyWith(stage: CaptureStage.confirming, parsed: parsed);
    } catch (error) {
      state = state.copyWith(
        stage: CaptureStage.editing,
        parseFailed: true,
        error: error,
      );
    }
  }

  Future<bool> _persist({
    required String taskDescription,
    required DateTime? resolvedDatetime,
    required double? confidence,
  }) async {
    state = state.copyWith(stage: CaptureStage.saving, clearError: true);

    try {
      final now = DateTime.now();
      final hasTime = resolvedDatetime != null;
      final note = Note(
        rawText: state.rawText.trim(),
        taskDescription: taskDescription,
        triggerType: hasTime ? TriggerType.time : TriggerType.none,
        resolvedDatetime: resolvedDatetime,
        confidence: confidence,
        status: hasTime ? NoteStatus.scheduled : NoteStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final id = await ref.read(noteRepositoryProvider).insertNote(note);

      if (hasTime) {
        await ref
            .read(schedulingServiceProvider)
            .scheduleReminder(note.copyWith(id: id));
      }

      state = const NoteFormState();
      return true;
    } catch (error) {
      state = state.copyWith(stage: CaptureStage.editing, error: error);
      return false;
    }
  }
}

final noteFormControllerProvider =
    NotifierProvider<NoteFormController, NoteFormState>(NoteFormController.new);
