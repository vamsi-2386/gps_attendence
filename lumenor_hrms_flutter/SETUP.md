# Lumenor HRMS Flutter App - Setup Guide

This guide will help you set up and initialize the Lumenor HRMS Flutter attendance application.

## Project Information

- **Project Name**: lumenor_hrms_flutter
- **Min SDK**: Android 21, iOS 12
- **Target SDK**: Latest
- **Package**: com.lumenor.hrms_attendance

## Prerequisites

- Flutter 3.12.2 or higher
- Dart 3.12.2 or higher
- Android Studio / Xcode
- iOS deployment target: 12.0
- Android minimum SDK: 21

## Installation Steps

### 1. Install Dependencies

```bash
cd lumenor_hrms_flutter
flutter pub get
```

### 2. Configure Supabase

Edit `lib/config/supabase_config.dart` and add your Supabase credentials:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Configure Android

Update `android/app/build.gradle.kts`:
- minSdk is set to 21
- Package name: com.lumenor.hrms_attendance

### 4. Configure iOS

Update `ios/Podfile` if needed:
- iOS deployment target is 12.0
- Check `ios/Runner/Info.plist` for minimum OS version

### 5. Generate Required Files

Some plugins may require code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── config/
│   ├── supabase_config.dart          # Supabase configuration
│   └── app_theme.dart                 # Theme and styling
├── models/
│   ├── employee.dart                  # Employee model
│   ├── company.dart                   # Company model
│   ├── attendance.dart                # Attendance model
│   ├── leave.dart                     # Leave request model
│   └── office.dart                    # Office location model
├── services/
│   ├── supabase_service.dart         # Supabase operations
│   ├── api_service.dart               # HTTP API calls
│   ├── geolocation_service.dart      # Location services
│   └── face_service.dart              # Face recognition
├── screens/
│   ├── onboarding/ (5 screens)
│   ├── login/ (4 screens)
│   ├── checkin/ (5 screens)
│   ├── selfservice/ (4 screens)
│   └── admin/ (4 screens)
├── widgets/
│   ├── themed_button.dart
│   ├── themed_text.dart
│   ├── themed_card.dart
│   ├── geofence_banner.dart
│   └── face_scanner_widget.dart
└── utils/
    ├── constants.dart
    └── validators.dart
```

## Key Features Implemented

### 1. Configuration
- Supabase integration setup
- Theming system with colors, typography, spacing
- App-wide constants

### 2. Data Models (5 models)
- Employee with face recognition support
- Company information
- Attendance with geolocation
- Leave requests with approval
- Office locations with geofence

### 3. Services (4 services)
- SupabaseService: Database, auth, storage
- ApiService: HTTP client with Dio and logging
- GeolocationService: Location and geofencing
- FaceService: Camera and face operations

### 4. Widgets (5 widget files)
- Themed buttons (primary, outline, text)
- Typography (8 text widget types)
- Card variations (standard, elevated, gradient, outlined)
- Geofence UI components
- Face scanner with animations

### 5. Screens (22 screens)
- Onboarding flow (5 screens)
- Face login (4 screens)
- Check-in/Check-out (5 screens)
- Self-service (4 screens)
- Admin dashboard (4 screens)

## Running the App

### Development
```bash
flutter run
```

### Build Android
```bash
flutter build apk --release
flutter build appbundle
```

### Build iOS
```bash
flutter build ios --release
```

## Dependencies Added

- supabase_flutter: ^1.10.0
- http: ^1.1.0
- dio: ^5.3.0
- intl: ^0.19.0
- geolocator: ^10.1.0
- image_picker: ^1.0.5
- camera: ^0.10.5
- shared_preferences: ^2.2.2
- provider: ^6.1.0
- google_maps_flutter: ^2.5.0
- uuid: ^4.0.0
- bcrypt: ^0.0.4
- jwt_decoder: ^2.0.1

## Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:
- android.permission.INTERNET
- android.permission.CAMERA
- android.permission.ACCESS_FINE_LOCATION
- android.permission.ACCESS_COARSE_LOCATION

## iOS Permissions

Add to `ios/Runner/Info.plist`:
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription

## Database Schema

Supabase tables needed:
- employees
- companies
- attendance
- leave_requests
- offices
- face_embeddings

Storage buckets:
- face-images
- profile-pictures
- documents

## Next Steps

1. Configure Supabase credentials
2. Set up database schema
3. Implement navigation routes
4. Connect screens with state management
5. Implement authentication
6. Add API endpoints
7. Configure location services
8. Set up face recognition models
9. Add error handling
10. Prepare for production

---

**Created**: June 23, 2026  
**Framework**: Flutter 3.12.2+  
**Dart**: 3.12.2+
