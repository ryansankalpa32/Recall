/// The kind of place a location trigger resolves against.
///
/// Unused until Phase 3 ([personal]) and Phase 4/6 ([specific]/[category]) —
/// modeled now per Claude.md so later phases populate this column instead of
/// migrating the schema to add it.
enum LocationKind {
  /// A learned or manually-added [UserPlace] (home, work, ...).
  personal,

  /// A generic category resolved via the Places API (e.g. "shoe store").
  category,

  /// A specific, named, one-off place.
  specific;

  static LocationKind fromName(String name) => LocationKind.values.byName(name);
}
