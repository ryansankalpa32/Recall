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
    this.manualTime,
  });

  final String rawText;

  /// A reminder time the user picked by hand after a failed parse. Null
  /// means "save as a plain note".
  final DateTime? manualTime;

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
    DateTime? manualTime,
    bool clearManualTime = false,
  }) {
    return NoteFormState(
      rawText: rawText ?? this.rawText,
      stage: stage ?? this.stage,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      parseFailed: parseFailed ?? this.parseFailed,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      manualTime: clearManualTime ? null : (manualTime ?? this.manualTime),
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
      // A hand-picked time belonged to the failed parse of the old text.
      clearManualTime: textChanged,
      stage: CaptureStage.editing,
    );
  }

  static const _pastTimeNotice =
      'That time has already passed — pick a later one.';

  /// Sets (or clears, with null) the hand-picked reminder time used when a
  /// parse failed. A time that has already passed is rejected with a notice.
  void setManualTime(DateTime? time) {
    if (time != null && !time.isAfter(DateTime.now())) {
      state = state.copyWith(notice: _pastTimeNotice);
      return;
    }
    state = state.copyWith(
      manualTime: time,
      clearManualTime: time == null,
      clearNotice: true,
    );
  }

  /// Replaces the time on the confirmation card with one the user picked.
  /// The card then shows the new time before anything is saved, so the
  /// show-before-commit rule still holds.
  void overrideParsedTime(DateTime time) {
    final parsed = state.parsed;
    if (parsed == null || state.isBusy) return;
    if (!time.isAfter(DateTime.now())) {
      state = state.copyWith(notice: _pastTimeNotice);
      return;
    }
    state = state.copyWith(
      parsed: ParsedNote(
        taskDescription: parsed.taskDescription,
        triggerType: TriggerType.time.name,
        locationKind: parsed.locationKind,
        locationValue: parsed.locationValue,
        resolvedDatetime: time,
        recurrenceRule: parsed.recurrenceRule,
        confidence: parsed.confidence,
      ),
      clearNotice: true,
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
  /// A prior parse failure bypasses the parser on this attempt and saves
  /// with the hand-picked [NoteFormState.manualTime] (or as a plain note if
  /// none was picked), so a note can always be written with no backend
  /// reachable; see [NoteFormState.parseFailed].
  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    if (state.parseFailed) {
      final manual = state.manualTime;
      // The picker could have been left open past the chosen time.
      if (manual != null && !manual.isAfter(DateTime.now())) {
        state = state.copyWith(notice: _pastTimeNotice);
        return false;
      }
      return _persist(
        taskDescription: state.rawText.trim(),
        resolvedDatetime: manual,
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
      
      // Firestore sync is the only write path to the server: pushNote stores
      // resolvedDatetime as a UTC Timestamp and sets notificationSent: false,
      // which is everything the reminder scheduler needs. (The old
      // `saveNote` call to POST /api/notes always threw on enum encoding and
      // silently fell back to this anyway.)
      unawaited(sync.pushNote(saved));

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
          // scheduleReminder just asked for notification permission in
          // context; now that it may exist, register for server pushes.
          if (outcome.notificationsAllowed) {
            unawaited(ref.read(fcmServiceProvider)?.ensureRegistered());
          }
        } catch (error) {
          // Downgrade the status so the list does not claim a reminder that
          // was never registered.
          final downgraded = saved.copyWith(
            status: NoteStatus.pending,
            updatedAt: DateTime.now(),
          );
          await ref.read(noteRepositoryProvider).updateNote(downgraded);
          // Firestore already has it as `scheduled` with a local alarm;
          // correct that too, or the server would mark it delivered.
          unawaited(sync.pushNote(downgraded));
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
