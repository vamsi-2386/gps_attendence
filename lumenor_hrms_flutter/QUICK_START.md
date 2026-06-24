# Quick Start Guide - Lumenor HRMS Flutter

## Installation (5 minutes)

```bash
# Navigate to project
cd C:\Users\229x1\Desktop\gps_attendence\lumenor_hrms_flutter

# Get dependencies
flutter pub get

# Run app
flutter run
```

## Essential Configuration

### 1. Supabase Setup
Edit `lib/config/supabase_config.dart`:
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 3. iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for face recognition</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location for attendance tracking</string>
```

## Project Structure Reference

| Directory | Purpose |
|-----------|---------|
| `config/` | Theme, constants, configuration |
| `models/` | Data classes (Employee, Attendance, etc.) |
| `services/` | Business logic (Supabase, API, Location, Face) |
| `screens/` | UI screens organized by feature |
| `widgets/` | Reusable UI components |
| `utils/` | Constants and validators |

## Key Files

| File | Purpose |
|------|---------|
| `main.dart` | App entry point with splash screen |
| `config/app_theme.dart` | Design system (colors, fonts, spacing) |
| `utils/constants.dart` | App-wide constants and messages |
| `utils/validators.dart` | Input validation functions |

## Development Commands

```bash
# Run app in debug mode
flutter run

# Run app in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>

# Build APK for Android
flutter build apk --release

# Build iOS app
flutter build ios --release

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Run code generation
flutter pub run build_runner build

# Clean project
flutter clean
```

## Navigation Routes (To Be Added)

Add these to `main.dart`:
```dart
routes: {
  '/home': (context) => const EmployeeHomeScreen(),
  '/checkin': (context) => const CheckInScreen(),
  '/login': (context) => const FaceLoginScreen(),
  '/onboarding': (context) => const RoleSelectionScreen(),
  '/admin': (context) => const AdminOverviewScreen(),
}
```

## Theming

Use `AppTheme` class for consistent styling:

```dart
// Colors
AppTheme.primaryColor      // Indigo
AppTheme.secondaryColor    // Violet
AppTheme.accentColor       // Emerald
AppTheme.errorColor        // Red
AppTheme.successColor      // Green

// Spacing
AppTheme.spacingSmall      // 8.0
AppTheme.spacingMedium     // 16.0
AppTheme.spacingLarge      // 24.0

// Border Radius
AppTheme.radiusMedium      // 12.0
AppTheme.radiusLarge       // 16.0

// Text Styles
AppTheme.headingLarge      // 24px, bold
AppTheme.bodyMedium        // 14px, normal
AppTheme.labelSmall        // 12px, semibold
```

## Common Tasks

### Create New Screen
1. Create file in appropriate `screens/` subdirectory
2. Extend `StatefulWidget` or `StatelessWidget`
3. Use themed widgets from `widgets/`
4. Add route in `main.dart`

### Create New Model
1. Create file in `models/` directory
2. Include `fromJson()` and `toJson()` methods
3. Add `copyWith()` for immutability
4. Import in relevant services

### Add Validation
Use validators from `utils/validators.dart`:

```dart
TextFormField(
  validator: Validators.validateEmail,
  // or
  validator: Validators.validatePassword,
)
```

### Use Services
```dart
// Supabase
final supabase = SupabaseService();
final data = await supabase.fetchFromTable('employees');

// API
final api = ApiService();
final response = await api.get('/endpoint');

// Location
final location = GeolocationService();
final position = await location.getCurrentPosition();

// Face
final face = FaceService();
await face.initializeCamera(camera);
```

## Debugging

```bash
# View logs
flutter logs

# Debug mode with verbose output
flutter run -v

# Hot reload (quick update)
Press 'r' in terminal

# Hot restart (full rebuild)
Press 'R' in terminal

# Stop app
Press 'q' in terminal
```

## Database Setup

Create Supabase tables with these columns:

**employees**
- id (uuid)
- company_id (uuid)
- email, first_name, last_name
- employee_id, designation, department
- face_embedding_id, is_face_enrolled
- role, is_active, created_at, updated_at

**attendance**
- id (uuid)
- employee_id, company_id (uuid)
- check_in_time, check_out_time (timestamp)
- check_in_latitude, check_in_longitude
- is_inside_geofence, status
- is_face_verified, created_at

**leave_requests**
- id (uuid)
- employee_id, company_id (uuid)
- start_date, end_date
- leave_type, status, reason
- approved_by_employee_id, approval_date

**offices**
- id (uuid)
- company_id (uuid)
- name, address, city, state, zip_code
- latitude, longitude, geofence_radius
- is_headquarters, is_active

**companies**
- id (uuid)
- name, registration_number, email_domain
- address, city, state, zip_code
- phone_number, website, industry

## Troubleshooting

| Issue | Solution |
|-------|----------|
| App won't run | Run `flutter clean && flutter pub get` |
| Supabase error | Check credentials in `supabase_config.dart` |
| Camera not working | Check Android/iOS permissions |
| Location not working | Enable location services on device |
| Build fails | Run `flutter clean` and try again |

## Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev)
- [Supabase Docs](https://supabase.com/docs)
- [Provider Package](https://pub.dev/packages/provider)

## Next Steps

1. ✅ Project created
2. ⏳ Configure Supabase
3. ⏳ Set up database
4. ⏳ Implement navigation
5. ⏳ Add state management
6. ⏳ Connect API endpoints
7. ⏳ Test features
8. ⏳ Build for production

---

**Quick Reference Created**: June 23, 2026
