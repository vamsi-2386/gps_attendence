import 'dart:math';

/// Office Location Model
///
/// Represents an office location with geofence information
class Office {
  final String id;
  final String companyId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final double latitude;
  final double longitude;
  final double geofenceRadius; // in meters
  final String? contact;
  final String? description;
  final bool isHeadquarters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Office({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    this.contact,
    this.description,
    required this.isHeadquarters,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full address
  String get fullAddress =>
      '$address, $city, $state $zipCode, $country';

  /// Check if a location is within geofence
  bool isLocationWithinGeofence(double lat, double lng) {
    final distance = _calculateDistance(latitude, longitude, lat, lng);
    return distance <= geofenceRadius;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  /// Returns distance in meters
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadian(lat2 - lat1);
    final dLon = _toRadian(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadian(lat1)) *
            cos(_toRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadian(double degree) {
    return degree * 3.141592653589793 / 180.0;
  }

  /// Create Office from JSON
  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      zipCode: json['zip_code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geofenceRadius: (json['geofence_radius'] as num).toDouble(),
      contact: json['contact'] as String?,
      description: json['description'] as String?,
      isHeadquarters: json['is_headquarters'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Office to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius': geofenceRadius,
      'contact': contact,
      'description': description,
      'is_headquarters': isHeadquarters,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Office copyWith({
    String? id,
    String? companyId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    String? contact,
    String? description,
    bool? isHeadquarters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Office(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      contact: contact ?? this.contact,
      description: description ?? this.description,
      isHeadquarters: isHeadquarters ?? this.isHeadquarters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
