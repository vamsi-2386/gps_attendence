# Quick Integration Guide

## 5-Minute Setup

### 1. Configure Environment Variables

Edit `.env` file with your actual values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-project-anon-key
API_BASE_URL=http://10.79.79.4:8000
```

### 2. Initialize in main.dart

Already configured in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('Warning: Supabase initialization failed: $e');
  }
  
  runApp(const LumenorHRMSApp());
}
```

### 3. Use Services in Your Screens

```dart
// Import services
import 'package:lumenor_hrms_flutter/services/supabase_service.dart';
import 'package:lumenor_hrms_flutter/services/api_service.dart';

// Get employee data
final supabaseService = SupabaseService();
final employee = await supabaseService.getEmployee('emp_id');

// Check-in with face
final apiService = ApiService();
final result = await apiService.checkIn(
  employeeId: employee.id,
  imageBytes: faceImageBytes,
  latitude: 12.9716,
  longitude: 77.5946,
);

// Apply leave
final leaveRequest = LeaveRequest(
  id: 'new_leave_id',
  employeeId: employee.id,
  companyId: employee.companyId,
  startDate: DateTime(2024, 6, 20),
  endDate: DateTime(2024, 6, 22),
  leaveType: 'casual',
  status: 'pending',
  reason: 'Personal work',
  numberOfDays: 3,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final appliedLeave = await supabaseService.applyLeave(leaveRequest);

// Subscribe to real-time updates
supabaseService.subscribeToAttendance(employee.companyId).listen((attendance) {
  print('New check-in: ${attendance.employeeId}');
});
```

## Key Classes

### SupabaseService
Singleton for all database operations:
```dart
SupabaseService().getEmployee(id)
SupabaseService().getEmployeeAttendance(id, startDate, endDate)
SupabaseService().applyLeave(leaveRequest)
SupabaseService().approveLeave(leaveId, approverEmployeeId, comments)
```

### ApiService
Singleton for FastAPI integration:
```dart
ApiService().faceLogin(imageBytes)
ApiService().checkIn(employeeId, imageBytes, lat, lng)
ApiService().checkOut(employeeId, imageBytes, lat, lng)
ApiService().getAttendanceHistory(employeeId)
ApiService().applyLeave(employeeId, startDate, endDate, leaveType, reason)
ApiService().healthCheck()
```

### Models
- `Employee` - Employee profile
- `Company` - Company details
- `Attendance` - Check-in/check-out records
- `LeaveRequest` - Leave applications
- `Office` - Office locations with geofence

## Color Theme

Dark theme colors available via `AppTheme`:
- `darkBackground` - #000000
- `darkElements` - #212225
- `textPrimary` - #B0B4BA
- `textSecondary` - #60646C
- `successColor` - #10B981
- `errorColor` - #EF4444
- `warningColor` - #F59E0B

Use in UI:
```dart
Container(
  color: AppTheme.darkElements,
  child: Text(
    'Status',
    style: AppTheme.bodyMedium.copyWith(
      color: AppTheme.textPrimary,
    ),
  ),
)
```

## Common Tasks

### Task: Check-in Employee
```dart
final faceService = FaceService();
final geoService = GeolocationService();

// Capture face image
final image = await faceService.captureImage();

// Get location
final position = await geoService.getCurrentLocation();

// Check-in via API
final result = await ApiService().checkIn(
  employeeId: employeeId,
  imageBytes: image.readAsBytesSync(),
  latitude: position.latitude,
  longitude: position.longitude,
);

// Save to Supabase
if (result['success']) {
  await SupabaseService().createAttendance(
    Attendance(
      id: result['attendance_id'],
      employeeId: employeeId,
      companyId: companyId,
      checkInTime: DateTime.now(),
      checkInLocation: 'Office',
      checkInLatitude: position.latitude,
      checkInLongitude: position.longitude,
      isInsideGeofence: true,
      status: 'checked_in',
      isFaceVerified: result['face_verified'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
}
```

### Task: Apply for Leave
```dart
final leave = LeaveRequest(
  id: const Uuid().v4(),
  employeeId: employeeId,
  companyId: companyId,
  startDate: selectedStartDate,
  endDate: selectedEndDate,
  leaveType: leaveType,
  status: 'pending',
  reason: reasonText,
  numberOfDays: selectedEndDate.difference(selectedStartDate).inDays + 1,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final appliedLeave = await SupabaseService().applyLeave(leave);
```

### Task: Get Attendance History
```dart
final startDate = DateTime.now().subtract(Duration(days: 30));
final endDate = DateTime.now();

final records = await SupabaseService().getEmployeeAttendance(
  employeeId,
  startDate: startDate,
  endDate: endDate,
);

for (var attendance in records) {
  print('${attendance.checkInTime}: ${attendance.status}');
}
```

### Task: Subscribe to Live Updates
```dart
final companyId = employee.companyId;

// Listen for new check-ins
SupabaseService().subscribeToAttendance(companyId).listen((attendance) {
  setState(() {
    latestAttendance = attendance;
  });
});

// Listen for leave request updates
SupabaseService().subscribeToLeaveRequests(companyId).listen((leave) {
  setState(() {
    pendingLeaves = [...pendingLeaves, leave];
  });
});
```

## Error Handling

All methods throw exceptions on failure:

```dart
try {
  final employee = await SupabaseService().getEmployee(id);
} catch (e) {
  print('Error: $e');
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

## API Health Check

Check if FastAPI server is running:

```dart
final isHealthy = await ApiService().healthCheck();
if (!isHealthy) {
  print('API server is down');
}
```

## Real-time Subscriptions

Get live updates without polling:

```dart
// Subscription automatically handles reconnection
final subscription = SupabaseService()
    .subscribeToAttendance(companyId)
    .listen(
      (attendance) {
        // Handle new/updated attendance
      },
      onError: (error) {
        // Handle subscription error
      },
    );

// Don't forget to cancel when done
subscription.cancel();
```

## Rate Limiting

API has built-in retry logic:
- Max 3 retries with exponential backoff
- Retry on: 408, 429, 500, 502, 503, 504
- Timeout: 30 seconds

## Database Sync

Models provide fromJson/toJson for seamless sync:

```dart
// From Supabase API response
final json = {'id': '123', 'name': 'John', ...};
final employee = Employee.fromJson(json);

// To Supabase API request
final jsonData = employee.toJson();
await supabaseService.upsertEmployee(employee);
```

## Troubleshooting

### "Supabase not initialized"
- Make sure `SupabaseService.initialize()` is called in main()
- Check .env file has correct SUPABASE_URL and SUPABASE_ANON_KEY

### "API connection refused"
- Verify API_BASE_URL in .env is correct
- Check FastAPI server is running: `curl http://10.79.79.4:8000/api/v1/health`
- Check network connectivity

### "Face recognition failed"
- Ensure good lighting
- Check minimum face size (100x100 pixels)
- Verify confidence threshold (0.7 by default)

### "Location permission denied"
- Request permission in app
- Check app settings on device
- Verify location permission is granted

## Next Steps

1. Review `BACKEND_INTEGRATION.md` for detailed documentation
2. Check `BACKEND_IMPLEMENTATION_SUMMARY.md` for complete feature list
3. Implement UI screens using the models and services
4. Add error handling and user feedback
5. Test with actual Supabase and FastAPI instances
6. Configure production environment variables

## Support

For more details, see:
- `BACKEND_INTEGRATION.md` - Full documentation
- `BACKEND_IMPLEMENTATION_SUMMARY.md` - Implementation details
- `lib/config/app_theme.dart` - Theme customization
- `lib/services/*.dart` - Service implementations

---

Ready to build! Start by creating your first screen that uses `SupabaseService` and `ApiService`.
