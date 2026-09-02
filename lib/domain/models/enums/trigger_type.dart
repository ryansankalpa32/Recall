/// What kind of trigger resolves a [Note]'s reminder.
///
/// All four values are modeled from Phase 1 (see Claude.md's build order),
/// even though Phase 1 UI only ever constructs [time] or [none] — [location]
/// and [both] become reachable starting Phase 3 (personal-place triggers).
enum TriggerType {
  location,
  time,
  both,
  none;

  static TriggerType fromName(String name) =>
      TriggerType.values.byName(name);
}
