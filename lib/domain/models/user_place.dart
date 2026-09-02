/// Where a place's coordinates came from.
enum UserPlaceSource {
  /// Auto-suggested from location-history clustering. Unused until Phase 5.
  learned,

  /// Added by hand — the only source Phase 1 ever produces.
  manual;

  static UserPlaceSource fromName(String name) =>
      UserPlaceSource.values.byName(name);
}

/// A personal place (home/work/school/custom) the user can add manually.
///
/// Per Claude.md's hard constraint, this screen works with zero AI and zero
/// location history — [source] is always [UserPlaceSource.manual] until
/// Phase 5 introduces clustering-based learning.
class UserPlace {
  const UserPlace({
    this.id,
    required this.label,
    this.customName,
    required this.lat,
    required this.lng,
    this.radiusM = 150,
    required this.source,
    required this.createdAt,
  });

  /// Null for a not-yet-persisted place.
  final int? id;

  /// `home` / `work` / `school` / `other` / a custom label.
  final String label;

  /// User-supplied name, e.g. when [label] is `other`.
  final String? customName;

  final double lat;
  final double lng;

  /// Geofence radius in meters. Unused until geofencing exists (Phase 3+).
  final int radiusM;

  final UserPlaceSource source;
  final DateTime createdAt;

  UserPlace copyWith({
    int? id,
    String? label,
    String? customName,
    double? lat,
    double? lng,
    int? radiusM,
    UserPlaceSource? source,
    DateTime? createdAt,
  }) {
    return UserPlace(
      id: id ?? this.id,
      label: label ?? this.label,
      customName: customName ?? this.customName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
