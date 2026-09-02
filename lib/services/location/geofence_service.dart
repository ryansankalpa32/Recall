/// A registered geofence, matching the shape `tracelet` exposes.
class GeofenceRegistration {
  const GeofenceRegistration({
    required this.id,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });

  final String id;
  final double lat;
  final double lng;
  final int radiusM;
}

enum GeofenceEventType { enter, exit, dwell }

class GeofenceEvent {
  const GeofenceEvent({required this.geofenceId, required this.type});

  final String geofenceId;
  final GeofenceEventType type;
}

/// Wraps `tracelet` (the only geofencing plugin this project uses — see
/// Claude.md's hard constraint: not `flutter_background_geolocation`).
///
/// No `tracelet` dependency is added to `pubspec.yaml` until Phase 3, so
/// this abstraction — and Phase 1 as a whole — has zero location-plugin
/// footprint, not just an unused one. Real background-location permission
/// requests happen lazily, inside the real implementation's
/// [registerGeofence], the first time a geofence is actually needed — never
/// during onboarding.
abstract class GeofenceService {
  Future<void> registerGeofence(GeofenceRegistration geofence);
  Future<void> unregisterGeofence(String id);
  Stream<GeofenceEvent> get events;
}

class UnimplementedGeofenceService implements GeofenceService {
  const UnimplementedGeofenceService();

  @override
  Future<void> registerGeofence(GeofenceRegistration geofence) {
    throw UnimplementedError(
      'GeofenceService is a Phase 3 feature (personal-place location '
      'triggers, via tracelet) — not wired into Phase 1 UI.',
    );
  }

  @override
  Future<void> unregisterGeofence(String id) {
    throw UnimplementedError('GeofenceService is a Phase 3 feature.');
  }

  @override
  Stream<GeofenceEvent> get events =>
      throw UnimplementedError('GeofenceService is a Phase 3 feature.');
}
