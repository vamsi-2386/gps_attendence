# Backend Integration Layer Documentation

## Overview

This document describes the complete backend integration layer for the Lumenor HRMS Flutter app, including Supabase client configuration, FastAPI endpoints, and data models.

## Architecture

### Services

1. **SupabaseService** - Database and real-time operations
2. **ApiService** - FastAPI backend communication
3. **Additional services** - Face recognition, geolocation, etc.

### Models

- **Employee** - Employee profile and credentials
- **Company** - Company/organization details
- **Attendance** - Check-in/check-out records
- **LeaveRequest** - Leave application and approval
- **Office** - Office locations with geofence data

### Configuration

- **SupabaseConfig** - Supabase initialization and client management
- **AppTheme** - Dark theme with status colors (success, error, warning)

## Setup Instructions

### 1. Environment Configuration

Create or update `.env` file in the project root:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-project-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# FastAPI Backend
API_BASE_URL=http://10.79.79.4:8000
API_TIMEOUT_SECONDS=30

# Face Recognition
MIN_FACE_CONFIDENCE=0.7
FACE_FRAME_SIZE=100

# Geofence
DEFAULT_GEOFENCE_RADIUS=100.0

# Environment
ENVIRONMENT=development
DEBUG_MODE=true
```

### 2. Supabase Setup

1. Create a Supabase project at https://supabase.com
2. Create the following tables:

#### employees table
```sql
create table employees (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  email text unique not null,
  first_name text not null,
  last_name text not null,
  phone_number text,
  employee_id text unique not null,
  designation text not null,
  department text,
  profile_image_url text,
  face_embedding_id text,
  is_face_enrolled boolean default false,
  date_of_joining timestamp not null,
  date_of_birth timestamp,
  role text default 'employee',
  is_active boolean default true,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

#### companies table
```sql
create table companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  registration_number text unique not null,
  email_domain text,
  logo_url text,
  address text not null,
  city text,
  state text,
  zip_code text,
  country text,
  phone_number text,
  website text,
  industry text,
  total_employees integer default 0,
  is_active boolean default true,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

#### attendance_logs table
```sql
create table attendance_logs (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references employees(id),
  company_id uuid not null references companies(id),
  check_in_time timestamp not null,
  check_out_time timestamp,
  check_in_location text not null,
  check_out_location text,
  check_in_latitude float not null,
  check_in_longitude float not null,
  check_out_latitude float,
  check_out_longitude float,
  is_inside_geofence boolean default true,
  status text default 'checked_in',
  notes text,
  is_face_verified boolean default false,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

#### leave_requests table
```sql
create table leave_requests (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references employees(id),
  company_id uuid not null references companies(id),
  start_date timestamp not null,
  end_date timestamp not null,
  leave_type text not null,
  status text default 'pending',
  reason text not null,
  attachment_url text,
  approver_comments text,
  approved_by_employee_id uuid,
  approval_date timestamp,
  number_of_days integer not null,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

#### offices table
```sql
create table offices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id),
  name text not null,
  address text not null,
  city text,
  state text,
  country text,
  zip_code text,
  latitude float not null,
  longitude float not null,
  geofence_radius float default 100.0,
  contact text,
  description text,
  is_headquarters boolean default false,
  is_active boolean default true,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
```

### 3. FastAPI Backend Setup

The app expects a FastAPI backend at `http://10.79.79.4:8000` with the following endpoints:

#### Face Recognition
- `POST /api/v1/face/login` - Verify employee with face
  - Request: MultipartFile (image)
  - Response: `{employee_id, name, company_id, ...}`

#### Attendance
- `POST /api/v1/attendance/check-in` - Check in with face and location
  - Request: MultipartFile (image), employee_id, latitude, longitude
  - Response: `{success, message, attendance_id, ...}`

- `POST /api/v1/attendance/check-out` - Check out with face and location
  - Request: MultipartFile (image), employee_id, latitude, longitude
  - Response: `{success, message, working_hours, ...}`

- `GET /api/v1/attendance/history` - Get attendance history
  - Query: `employee_id`, `start_date`, `end_date`, `limit`
  - Response: `{records: [...]}`

#### Leave Management
- `POST /api/v1/leave/apply` - Apply for leave
  - Request: `{employee_id, start_date, end_date, leave_type, reason, attachment_url}`
  - Response: `{success, message, leave_id, ...}`

- `GET /api/v1/leave/history` - Get leave history
  - Query: `employee_id`, `status`, `limit`
  - Response: `{records: [...]}`

#### Health Check
- `GET /api/v1/health` - Health check endpoint
  - Response: `{status: "ok"}`

## Service Usage Examples

### SupabaseService

```dart
import 'package:lumenor_hrms_flutter/services/supabase_service.dart';

// Initialize
await SupabaseService.initialize();

// Get employee
final employee = await SupabaseService().getEmployee('employee_id');

// Get attendance history
final attendance = await SupabaseService().getEmployeeAttendance(
  'employee_id',
  startDate: DateTime.now().subtract(Duration(days: 30)),
);

// Apply for leave
final leave = await SupabaseService().applyLeave(leaveRequest);

// Subscribe to attendance updates
SupabaseService().subscribeToAttendance('company_id').listen((attendance) {
  print('New attendance: ${attendance.id}');
});
```

### ApiService

```dart
import 'package:lumenor_hrms_flutter/services/api_service.dart';

// Check-in with face recognition
final result = await ApiService().checkIn(
  employeeId: 'emp_001',
  imageBytes: faceImageBytes,
  latitude: 12.9716,
  longitude: 77.5946,
);

// Check health
final isHealthy = await ApiService().healthCheck();

// Apply leave via API
final leaveResult = await ApiService().applyLeave(
  employeeId: 'emp_001',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 3)),
  leaveType: 'casual',
  reason: 'Personal work',
);
```

## Data Models

### Employee
```dart
Employee(
  id: 'uuid',
  companyId: 'company_uuid',
  email: 'emp@company.com',
  firstName: 'John',
  lastName: 'Doe',
  employeeId: 'EMP001',
  designation: 'Software Engineer',
  faceEmbeddingId: 'embedding_uuid',
  isFaceEnrolled: true,
  // ... other fields
)
```

### Attendance
```dart
Attendance(
  id: 'uuid',
  employeeId: 'emp_uuid',
  checkInTime: DateTime.now(),
  checkInLatitude: 12.9716,
  checkInLongitude: 77.5946,
  isInsideGeofence: true,
  status: 'checked_in',
  isFaceVerified: true,
  // ... other fields
)
```

### LeaveRequest
```dart
LeaveRequest(
  id: 'uuid',
  employeeId: 'emp_uuid',
  startDate: DateTime(2024, 6, 20),
  endDate: DateTime(2024, 6, 22),
  leaveType: 'casual',
  status: 'pending',
  reason: 'Personal work',
  numberOfDays: 3,
  // ... other fields
)
```

## Theme Configuration

The app uses a dark theme with the following color scheme:

- **Background**: #000000 (pure black)
- **Elements**: #212225 (dark gray)
- **Text Primary**: #B0B4BA (light gray)
- **Text Secondary**: #60646C (muted gray)
- **Borders**: #60646C
- **Success**: #10B981 (green)
- **Error**: #EF4444 (red)
- **Warning**: #F59E0B (amber)
- **Info**: #3B82F6 (blue)

Customize colors in `lib/config/app_theme.dart`.

## Error Handling

Both services implement comprehensive error handling:

- **Connection timeouts**: Automatic retry with exponential backoff
- **Network errors**: Graceful fallback with user messages
- **Validation errors**: Detailed error responses from API
- **Authentication errors**: Token refresh and re-authentication

## Real-time Subscriptions

SupabaseService provides real-time streams:

```dart
// Subscribe to attendance updates
SupabaseService().subscribeToAttendance('company_id')
  .listen((attendance) {
    // Handle new attendance record
  });

// Subscribe to leave request updates
SupabaseService().subscribeToLeaveRequests('company_id')
  .listen((leave) {
    // Handle leave update
  });
```

## Security Notes

1. **Anon Key**: Used for client-side operations (limited permissions)
2. **Service Key**: Used server-side only (admin operations)
3. **Row Level Security**: Enable RLS on all tables
4. **API Authentication**: Implement JWT token-based auth for FastAPI
5. **Sensitive Data**: Face embeddings and location data should be encrypted

## Deployment Checklist

- [ ] Configure Supabase credentials in `.env`
- [ ] Create all required database tables
- [ ] Set up Row Level Security policies
- [ ] Configure storage buckets for images
- [ ] Deploy FastAPI backend
- [ ] Test all endpoints with sample data
- [ ] Configure error handling and logging
- [ ] Set up monitoring and alerts
- [ ] Test real-time subscriptions
- [ ] Load test the system

## Troubleshooting

### Supabase Connection Issues
- Verify SUPABASE_URL and SUPABASE_ANON_KEY
- Check network connectivity
- Ensure Supabase project is active

### API Connection Issues
- Verify API_BASE_URL is correct
- Check FastAPI server is running
- Verify network allows connections to API server

### Face Recognition Issues
- Ensure good lighting conditions
- Check face image resolution (minimum 100x100 pixels)
- Verify face confidence threshold (default 0.7)

### Location Issues
- Ensure location permission is granted
- Check GPS is enabled on device
- Verify geofence radius is appropriate

## Support

For issues or questions:
1. Check logs in console
2. Review error messages in app
3. Consult Supabase documentation
4. Review FastAPI backend logs
5. Check network connectivity
