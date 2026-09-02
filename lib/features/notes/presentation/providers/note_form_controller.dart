import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../domain/models/enums/note_status.dart';
import '../../../../domain/models/enums/trigger_type.dart';
import '../../../../domain/models/note.dart';

/// State for [NoteCaptureSheet] — Phase 1 has no AI, so "manual time
/// reminders" means the user explicitly picks a time here (or leaves it
/// unset for a plain, trigger-less note).
class NoteFormState {
  const NoteFormState({
    this.rawText = '',
    this.pickedDateTime,
    this.isSaving = false,
    this.error,
  });

  final String rawText;
  final DateTime? pickedDateTime;
  final bool isSaving;
  final Object? error;

  bool get canSave => rawText.trim().isNotEmpty && !isSaving;

  NoteFormState copyWith({
    String? rawText,
    DateTime? pickedDateTime,
    bool clearPickedDateTime = false,
    bool? isSaving,
    Object? error,
    bool clearError = false,
  }) {
    return NoteFormState(
      rawText: rawText ?? this.rawText,
      pickedDateTime:
          clearPickedDateTime ? null : (pickedDateTime ?? this.pickedDateTime),
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NoteFormController extends Notifier<NoteFormState> {
  @override
  NoteFormState build() => const NoteFormState();

  void setRawText(String text) {
    state = state.copyWith(rawText: text, clearError: true);
  }

  void setPickedDateTime(DateTime? dateTime) {
    state = dateTime == null
        ? state.copyWith(clearPickedDateTime: true, clearError: true)
        : state.copyWith(pickedDateTime: dateTime, clearError: true);
  }

  /// Inserts the note and, if a time was picked, schedules its reminder.
  /// Returns whether the save succeeded; on success the form resets so the
  /// capture sheet can be reused/dismissed.
  Future<bool> save() async {
    if (!state.canSave) return false;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final now = DateTime.now();
      final hasTime = state.pickedDateTime != null;
      final note = Note(
        rawText: state.rawText.trim(),
        taskDescription: state.rawText.trim(),
        triggerType: hasTime ? TriggerType.time : TriggerType.none,
        resolvedDatetime: state.pickedDateTime,
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
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e);
      return false;
    }
  }
}

final noteFormControllerProvider =
    NotifierProvider<NoteFormController, NoteFormState>(NoteFormController.new);
