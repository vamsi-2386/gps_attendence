import 'app_session.dart';
import 'geofence_service.dart';
import 'hrms_repository.dart';

/// Outcome of a check-in attempt.
enum CheckInStatus { marked, flagged, alreadyMarked, error }

class CheckInOutcome {
  const CheckInOutcome(
    this.status,
    this.message, {
    this.record,
    this.geofence,
  });
  final CheckInStatus status;
  final String message;
  final Map<String, dynamic>? record;
  final GeofenceResult? geofence;
}

enum ClockOutStatus { done, noOpenCheckIn, alreadyOut, error }

class ClockOutOutcome {
  const ClockOutOutcome(this.status, this.message, {this.workedHours});
  final ClockOutStatus status;
  final String message;
  final double? workedHours;
}

/// Geofenced attendance: real-GPS check-in with inside/outside validation,
/// duplicate-day prevention, HR-flagging for outside check-ins, and clock-out
/// with automatic worked-hours.
class AttendanceService {
  AttendanceService._();

  static Future<CheckInOutcome> markCheckIn() async {
    final session = AppSession.instance;
    final repo = HrmsRepository.instance;

    try {
      // 1. Prevent duplicate check-ins on the same day.
      final today = await repo.todayAttendance(session.employeeId);
      if (today != null) {
        return const CheckInOutcome(
          CheckInStatus.alreadyMarked,
          'Attendance already marked for today.',
        );
      }

      // 2. Real device GPS (no fallback to fake coordinates).
      final pos = await GeofenceService.currentPosition();

      // 3. Geofence = the office assigned to this employee by the admin.
      final geo = GeofenceService.evaluate(
        pos: pos,
        siteLat: session.officeLat,
        siteLng: session.officeLng,
        radius: session.officeRadius,
      );
      final bool inside = geo.inside;
      final attendanceStatus = inside ? 'Present' : 'Flagged';
      final geofenceStatus = geo.statusLabel;

      // 5. Save the attendance record with real GPS + status.
      final record = await repo.markAttendance(
        employeeId: session.employeeId,
        employeeName: session.employeeName,
        companyId: session.companyId,
        subjectId: session.subjectId,
        siteId: session.officeId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        attendanceStatus: attendanceStatus,
        geofenceStatus: geofenceStatus,
        present: inside, // outside check-ins are not counted present until HR approves
      );

      if (inside) {
        return CheckInOutcome(
          CheckInStatus.marked,
          'Clocked in — Present at ${session.officeName.isEmpty ? 'site' : session.officeName}.',
          record: record,
          geofence: geo,
        );
      }
      // Outside → flagged record routed to HR review (attendance_status=Flagged).
      return CheckInOutcome(
        CheckInStatus.flagged,
        'Outside Assigned Site (${geo.distanceLabel} away). Check-in flagged for HR review.',
        record: record,
        geofence: geo,
      );
    } catch (e) {
      return CheckInOutcome(
        CheckInStatus.error,
        _friendly(e),
      );
    }
  }

  static Future<ClockOutOutcome> clockOut() async {
    final repo = HrmsRepository.instance;
    final session = AppSession.instance;
    try {
      final today = await repo.todayAttendance(session.employeeId);
      if (today == null) {
        return const ClockOutOutcome(
          ClockOutStatus.noOpenCheckIn,
          'No active check-in to clock out from.',
        );
      }
      final existingOut = today['check_out_time'] ?? today['checkout_time'];
      if (existingOut != null && '$existingOut'.isNotEmpty) {
        return const ClockOutOutcome(
          ClockOutStatus.alreadyOut,
          'You have already clocked out today.',
        );
      }

      final inIso = (today['check_in_time'] ?? today['timestamp']).toString();
      // Normalize both sides to UTC so the difference is correct regardless of
      // the device timezone (the previous local-vs-UTC mix yielded 0 hours).
      final checkIn = DateTime.tryParse(inIso)?.toUtc();
      final now = DateTime.now().toUtc();
      double workedHours = 0;
      if (checkIn != null && now.isAfter(checkIn)) {
        workedHours = now.difference(checkIn).inSeconds / 3600.0;
      }

      await repo.clockOut(
        attendanceId: today['id'] as int,
        checkOutIso: now.toIso8601String(),
        workedHours: workedHours,
      );

      return ClockOutOutcome(
        ClockOutStatus.done,
        'Clocked out — ${workedHours.toStringAsFixed(2)} h worked.',
        workedHours: workedHours,
      );
    } catch (e) {
      return ClockOutOutcome(ClockOutStatus.error, _friendly(e));
    }
  }

  static String _friendly(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('location') ||
        s.contains('permission') ||
        s.contains('position')) {
      return 'Could not read GPS. Enable Location and try again.';
    }
    if (s.contains('failed host lookup') ||
        s.contains('socketexception') ||
        s.contains('timed out')) {
      return 'Cannot reach the server. Check your internet connection.';
    }
    return 'Could not save attendance: $e';
  }
}
