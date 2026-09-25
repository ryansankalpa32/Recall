import 'dart:async';

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
    this.stage = CaptureStage.editing,
    this.parsed,
    this.parseFailed = false,
    this.error,
    this.notice,
  });

  final String rawText;

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

  /// A plain user-facing message — a rejected time, or a caveat about how a
  /// saved reminder will actually be delivered. Distinct from [error], which
  /// holds an exception and reads as a failure; a notice is not a failure.
  final String? notice;

  bool get isBusy =>
      stage == CaptureStage.parsing || stage == CaptureStage.saving;

  bool get canSubmit => rawText.trim().isNotEmpty && !isBusy;

  NoteFormState copyWith({
    String? rawText,
    CaptureStage? stage,
    ParsedNote? parsed,
    bool clearParsed = false,
    bool? parseFailed,
    Object? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return NoteFormState(
      rawText: rawText ?? this.rawText,
      stage: stage ?? this.stage,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      parseFailed: parseFailed ?? this.parseFailed,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

class NoteFormController extends Notifier<NoteFormState> {
  @override
  NoteFormState build() => const NoteFormState();

  /// Clears the form back to empty.
  ///
  /// The capture sheet calls this as it opens. Without it the controller keeps
  /// its state for the life of the app (the provider is not auto-disposed), so
  /// a sheet dismissed mid-flow would leak two things into the next note: the
  /// previous [NoteFormState.rawText] — invisible, because the `TextField` is
  /// uncontrolled and renders empty — and a sticky [NoteFormState.parseFailed],
  /// which silently routes every later note past the parser.
  void reset() => state = const NoteFormState();

  void setRawText(String text) {
    // Any existing interpretation is now stale.
    //
    // A genuine edit also retires a previous parse failure: the text the
    // parser choked on is not the text we now have, so it has earned another
    // attempt. Re-submitting *unchanged* text after a failure still saves
    // directly, which is what keeps a note writable with no backend reachable.
    final textChanged = text != state.rawText;
    state = state.copyWith(
      rawText: text,
      clearParsed: true,
      clearError: true,
      clearNotice: true,
      parseFailed: textChanged ? false : null,
      stage: CaptureStage.editing,
    );
  }

  /// Returns to the text field from the confirmation card, keeping what was
  /// typed so the user can correct it.
  void backToEditing() {
    state = state.copyWith(
      stage: CaptureStage.editing,
      clearParsed: true,
      clearError: true,
      clearNotice: true,
    );
  }

  /// The Save tap.
  ///
  /// Returns whether the note was saved and the sheet should close. A `false`
  /// means either that the flow moved on to the confirmation card, or that
  /// something failed and the sheet should stay open showing why.
  ///
  /// There is no manual time entry in this build — every reminder time comes
  /// from the AI parse. A prior parse failure bypasses the parser on this
  /// attempt (saving as a plain, timeless note) so a note can always be
  /// written with no backend reachable; see [NoteFormState.parseFailed].
  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    if (state.parseFailed) {
      return _persist(
        taskDescription: state.rawText.trim(),
        resolvedDatetime: null,
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

    final effective = parsed.resolvedDatetime;

    // The parse resolved against the clock at *parse* time, and this card can
    // sit on screen indefinitely. "take the pasta out in 2 minutes" plus a
    // three-minute pause would otherwise commit a time already gone.
    if (effective != null && !effective.isAfter(DateTime.now())) {
      state = state.copyWith(
        notice: 'That time has just passed — set a new one before saving.',
      );
      return false;
    }

    return _persist(
      taskDescription: parsed.taskDescription,
      resolvedDatetime: effective,
      confidence: parsed.confidence,
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
      final sync = ref.read(firestoreSyncServiceProvider);
      final note = Note(
        firestoreId: sync.reserveDocumentId(),
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
      final saved = note.copyWith(id: id);
      
      // Send to backend API so it can handle server-side timestamp conversion
      // and initialize notification flags. If offline, fall back to the direct
      // Firestore sync (which we'll also update to include notificationSent: false).
      try {
        await ref.read(recallApiClientProvider).saveNote(saved);
      } catch (_) {
        unawaited(sync.pushNote(saved));
      }

      // Scheduling is deliberately outside the insert's failure path. Sharing
      // one try meant a scheduler throw left the row already written while
      // reporting failure — so tapping Save again inserted a duplicate.
      // The note is committed at this point; the only open question is whether
      // its reminder is live, and that is answered without losing the note.
      String? caveat;
      if (hasTime) {
        try {
          final outcome = await ref
              .read(schedulingServiceProvider)
              .scheduleReminder(saved);
          caveat = outcome.caveat;
        } catch (error) {
          // Downgrade the status so the list does not claim a reminder that
          // was never registered.
          await ref
              .read(noteRepositoryProvider)
              .updateNote(saved.copyWith(status: NoteStatus.pending));
          caveat = 'Saved, but the reminder could not be scheduled. '
              'Open the note to set a time again.';
        }
      }

      state = NoteFormState(notice: caveat);
      return true;
    } catch (error) {
      state = state.copyWith(stage: CaptureStage.editing, error: error);
      return false;
    }
  }
}

final noteFormControllerProvider =
    NotifierProvider<NoteFormController, NoteFormState>(NoteFormController.new);
