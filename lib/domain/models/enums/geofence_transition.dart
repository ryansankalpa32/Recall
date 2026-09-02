/// Which geofence transition fires a location-triggered reminder.
///
/// Unused until Phase 3+. [dwell] (not raw [enter]) is the default once
/// geofencing exists, per the README's known-challenges note on avoiding
/// false positives from driving past a place.
enum GeofenceTransition {
  enter,
  exit,
  dwell;

  static GeofenceTransition fromName(String name) =>
      GeofenceTransition.values.byName(name);
}
