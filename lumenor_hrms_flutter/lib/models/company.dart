/// Company Model
///
/// Represents a company in the Lumenor HRMS system
class Company {
  final String id;
  final String name;
  final String registrationNumber;
  final String emailDomain;
  final String logoUrl;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phoneNumber;
  final String website;
  final String industry;
  final int totalEmployees;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.emailDomain,
    required this.logoUrl,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phoneNumber,
    required this.website,
    required this.industry,
    required this.totalEmployees,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full address
  String get fullAddress =>
      '$address, $city, $state $zipCode, $country';

  /// Create Company from JSON
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      registrationNumber: json['registration_number'] as String,
      emailDomain: json['email_domain'] as String,
      logoUrl: json['logo_url'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String,
      country: json['country'] as String,
      phoneNumber: json['phone_number'] as String,
      website: json['website'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      totalEmployees: json['total_employees'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Company to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registration_number': registrationNumber,
      'email_domain': emailDomain,
      'logo_url': logoUrl,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'phone_number': phoneNumber,
      'website': website,
      'industry': industry,
      'total_employees': totalEmployees,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  Company copyWith({
    String? id,
    String? name,
    String? registrationNumber,
    String? emailDomain,
    String? logoUrl,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phoneNumber,
    String? website,
    String? industry,
    int? totalEmployees,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      emailDomain: emailDomain ?? this.emailDomain,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
