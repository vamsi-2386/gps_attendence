import 'package:geolocator/geolocator.dart';

import 'geolocation_service.dart';

/// Result of evaluating the employee's real GPS against an assigned site.
class GeofenceResult {
  const GeofenceResult({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.inside,
    required this.hasSiteCoords,
  });

  final double latitude; // employee's real location
  final double longitude;
  final double? distanceMeters; // null when the site has no coordinates
  final bool inside;
  final bool hasSiteCoords;

  String get statusLabel => !hasSiteCoords
      ? 'Unknown'
      : inside
          ? 'Inside'
          : 'Outside';

  String get distanceLabel {
    final d = distanceMeters;
    if (d == null) return '—';
    if (d < 1000) return '${d.round()} m';
    return '${(d / 1000).toStringAsFixed(2)} km';
  }
}

/// Real-device GPS + geofence math. No mock or hardcoded coordinates.
class GeofenceService {
  GeofenceService._();

  /// The employee's current real GPS position (throws if unavailable/denied).
  static Future<Position> currentPosition() {
    return GeolocationService().getCurrentPosition(
      accuracy: LocationAccuracy.high,
      timeLimit: 15000,
    );
  }

  /// Compare a real position against a site's geofence.
  static GeofenceResult evaluate({
    required Position pos,
    double? siteLat,
    double? siteLng,
    int radius = 200,
  }) {
    if (siteLat == null || siteLng == null) {
      return GeofenceResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        distanceMeters: null,
        inside: false,
        hasSiteCoords: false,
      );
    }
    final d = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      siteLat,
      siteLng,
    );
    return GeofenceResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      distanceMeters: d,
      inside: d <= radius,
      hasSiteCoords: true,
    );
  }
}
