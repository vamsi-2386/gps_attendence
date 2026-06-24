import 'package:geolocator/geolocator.dart';

/// Geolocation Service
///
/// Handles location permissions and positioning
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();

  factory GeolocationService() {
    return _instance;
  }

  GeolocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get current position
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int timeLimit = 30000, // milliseconds
  }) async {
    try {
      final permission = await getLocationPermission();

      if (permission == LocationPermission.denied) {
        await requestLocationPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        throw Exception('Location permission is permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: Duration(milliseconds: timeLimit),
      ).timeout(
        Duration(milliseconds: timeLimit),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      return position;
    } catch (e) {
      throw Exception('Error getting current position: $e');
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      throw Exception('Error getting last known position: $e');
    }
  }

  /// Calculate distance between two points
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if location is within a geofence
  bool isLocationInGeofence({
    required double userLatitude,
    required double userLongitude,
    required double fenceLatitude,
    required double fenceLongitude,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      startLatitude: userLatitude,
      startLongitude: userLongitude,
      endLatitude: fenceLatitude,
      endLongitude: fenceLongitude,
    );

    return distance <= radiusInMeters;
  }

  /// Start listening to position changes
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 0, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await getLocationPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get location accuracy authorization status (iOS 14+/Android)
  Future<LocationAccuracyStatus> getLocationAccuracy() async {
    return await Geolocator.getLocationAccuracy();
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
