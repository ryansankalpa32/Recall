/// Lifecycle status of a [Note].
///
/// Phase 1 only ever reaches [pending]/[scheduled]/[notified]/[done].
/// [needsClarification] is modeled now but stays unreachable until Phase 7
/// (confidence & clarification loop) — see Claude.md's build order.
enum NoteStatus {
  /// Saved but has no schedulable trigger yet (e.g. [TriggerType.none]).
  pending,

  /// A trigger has been scheduled (time-based) or registered (location-based).
  scheduled,

  /// The reminder notification has fired.
  notified,

  /// The user marked the note done.
  done,

  /// A low-confidence AI parse needs the user to confirm/correct it before
  /// it can be scheduled. Unreachable until Phase 7.
  needsClarification;

  static NoteStatus fromName(String name) => NoteStatus.values.byName(name);
}
