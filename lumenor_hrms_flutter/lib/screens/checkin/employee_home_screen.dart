import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/attendance_service.dart';
import '../../services/geofence_service.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_card.dart';
import '../selfservice/attendance_calendar_screen.dart';
import '../selfservice/leave_status_screen.dart';

/// Employee Home Screen (dashboard)
///
/// Real-time GPS geofencing attendance. The Home tab resolves the employee's
/// assigned site geofence, reads the live device GPS, and shows distance +
/// inside/outside status, today's check-in/out, worked hours and status.
/// Clock In runs geofence validation; Clock Out computes worked hours. The
/// dashboard auto-refreshes after each action.
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _currentIndex = 0;

  bool _loadingDash = true;
  bool _busy = false;
  Map<String, dynamic>? _today; // today's attendance row
  Map<String, dynamic>? _site; // assigned site (with geofence)
  GeofenceResult? _geo; // live GPS vs site
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String get _firstName {
    final parts = AppSession.instance.employeeName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  String _formatTime(dynamic iso) {
    final dt = DateTime.tryParse('$iso')?.toLocal();
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt);
  }

  /// Load today's attendance, the assigned-site geofence, and live GPS status.
  Future<void> _loadDashboard() async {
    if (mounted) setState(() => _loadingDash = true);
    final repo = HrmsRepository.instance;
    final session = AppSession.instance;
    try {
      _today = await repo.todayAttendance(session.employeeId);

      // The assigned site IS the office the admin assigned to this employee.
      final office = await repo.assignedOffice(session.employeeId, session.companyId);
      _site = office;

      // Live GPS + geofence evaluation against the assigned office.
      _gpsError = null;
      try {
        final pos = await GeofenceService.currentPosition();
        final lat = (office?['latitude'] as num?)?.toDouble();
        final lng = (office?['longitude'] as num?)?.toDouble();
        final radius = (office?['radius'] as num?)?.toInt() ?? 200;
        _geo = GeofenceService.evaluate(
            pos: pos, siteLat: lat, siteLng: lng, radius: radius);
      } catch (_) {
        _geo = null;
        _gpsError = 'Location unavailable. Enable GPS to see geofence status.';
      }
    } catch (e) {
      _gpsError = 'Could not load dashboard: $e';
    } finally {
      if (mounted) setState(() => _loadingDash = false);
    }
  }

  bool get _checkedInToday => _today != null;
  bool get _clockedOut {
    final out = _today?['check_out_time'] ?? _today?['checkout_time'];
    return out != null && '$out'.isNotEmpty;
  }

  Future<void> _clockIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    final out = await AttendanceService.markCheckIn();
    if (!mounted) return;
    final color = switch (out.status) {
      CheckInStatus.marked => AppTheme.successColor,
      CheckInStatus.flagged => AppTheme.warningColor,
      CheckInStatus.alreadyMarked => AppTheme.warningColor,
      CheckInStatus.error => AppTheme.errorColor,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(out.message), backgroundColor: color),
    );
    await _loadDashboard(); // auto-refresh
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _clockOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    final out = await AttendanceService.clockOut();
    if (!mounted) return;
    final color = out.status == ClockOutStatus.done
        ? AppTheme.successColor
        : (out.status == ClockOutStatus.error
            ? AppTheme.errorColor
            : AppTheme.warningColor);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(out.message), backgroundColor: color),
    );
    await _loadDashboard(); // auto-refresh
    if (mounted) setState(() => _busy = false);
  }

  void _onTabTapped(int index) async {
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceCalendarScreen()),
      );
      return;
    }
    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaveStatusScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkElements,
        elevation: 0,
        title: const HeadingMediumText('Lumenor HRMS'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadingDash ? null : _loadDashboard,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeTab() : _buildProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: AppTheme.darkElements,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_busy_outlined), label: 'Leave'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          BodyLargeText('Good morning, $_firstName',
              color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingXSmall),
          HeadingLargeText(AppSession.instance.employeeName),
          BodySmallText(AppSession.instance.designation,
              color: AppTheme.textSecondary),
          const SizedBox(height: AppTheme.spacingMedium),

          if (_loadingDash)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXLarge),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _geofenceCard(),
            const SizedBox(height: AppTheme.spacingMedium),
            _actionButtons(),
            const SizedBox(height: AppTheme.spacingLarge),
            _todayStatusCard(),
          ],
          const SizedBox(height: AppTheme.spacingLarge),
        ],
      ),
    );
  }

  // --- Geofence + GPS card -------------------------------------------------

  Widget _geofenceCard() {
    final geo = _geo;
    final bool inside = geo?.inside ?? false;
    final bool unknown = geo == null || !geo.hasSiteCoords;
    final Color color = unknown
        ? AppTheme.warningColor
        : (inside ? AppTheme.successColor : AppTheme.errorColor);
    final String siteName =
        (_site?['office_name'] ?? AppSession.instance.officeName).toString();
    final lat = (_site?['latitude'] as num?)?.toDouble();
    final lng = (_site?['longitude'] as num?)?.toDouble();
    final radius = (_site?['radius'] as num?)?.toInt();
    final String statusText = unknown
        ? (_gpsError != null
            ? 'Location unavailable'
            : 'No office assigned / geofence not set')
        : (inside ? 'Inside geofence' : 'Outside assigned site');

    return ThemedCard(
      backgroundColor: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.5),
      borderWidth: 1,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle),
                child: Icon(
                    inside
                        ? Icons.location_on
                        : (unknown ? Icons.location_searching : Icons.location_off),
                    color: color),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BodyLargeText(statusText,
                        color: color, fontWeight: FontWeight.w600),
                    BodySmallText(
                      siteName.isEmpty ? 'No site assigned' : siteName,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          const Divider(color: AppTheme.borders, height: 1),
          const SizedBox(height: AppTheme.spacingMedium),
          _kv('Assigned Site', siteName.isEmpty ? '—' : siteName),
          _kv('Site Latitude', lat == null ? '—' : lat.toStringAsFixed(6)),
          _kv('Site Longitude', lng == null ? '—' : lng.toStringAsFixed(6)),
          _kv('Geofence Radius', radius == null ? '—' : '$radius m'),
          _kv('Geofence Status', unknown ? '—' : geo.statusLabel),
          _kv('Distance from Site', unknown ? '—' : geo.distanceLabel),
          _kv(
            'Current GPS',
            geo == null
                ? (_gpsError ?? '—')
                : '${geo.latitude.toStringAsFixed(5)}, ${geo.longitude.toStringAsFixed(5)}',
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: BodySmallText(k, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: BodyMediumText(v, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // --- Clock In / Clock Out ------------------------------------------------

  Widget _actionButtons() {
    if (!_checkedInToday) {
      return ThemedButton(
        label: 'Clock In',
        icon: Icons.fingerprint,
        height: 56,
        backgroundColor: AppTheme.successColor,
        isLoading: _busy,
        onPressed: _clockIn,
      );
    }
    if (!_clockedOut) {
      return ThemedButton(
        label: 'Clock Out',
        icon: Icons.logout,
        height: 56,
        backgroundColor: AppTheme.errorColor,
        isLoading: _busy,
        onPressed: _clockOut,
      );
    }
    // Already clocked in and out today.
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppTheme.successColor),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: BodyMediumText("Today's attendance is complete.",
                color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --- Today's status ------------------------------------------------------

  Widget _todayStatusCard() {
    final log = _today;
    final bool hasLog = log != null;
    final String status = hasLog
        ? (log['attendance_status'] ?? (log['is_present'] == true ? 'Present' : 'Absent'))
            .toString()
        : 'Not checked in';
    final Color statusColor = !hasLog
        ? AppTheme.textSecondary
        : (status == 'Present'
            ? AppTheme.successColor
            : (status == 'Flagged'
                ? AppTheme.warningColor
                : AppTheme.errorColor));

    final checkIn =
        hasLog ? _formatTime(log['check_in_time'] ?? log['timestamp']) : '--:--';
    final outVal = hasLog ? (log['check_out_time'] ?? log['checkout_time']) : null;
    final checkOut =
        (outVal != null && '$outVal'.isNotEmpty) ? _formatTime(outVal) : '--:--';
    final worked = _workedLabel(log);

    return ThemedCard(
      backgroundColor: AppTheme.darkElements,
      borderColor: AppTheme.borders,
      borderWidth: 0.5,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const HeadingMediumText("Today's Status"),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: BodySmallText(status, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusItem('Check In', checkIn, AppTheme.successColor),
              Container(width: 1, height: 40, color: AppTheme.borders),
              _statusItem('Check Out', checkOut,
                  checkOut == '--:--' ? AppTheme.textSecondary : AppTheme.errorColor),
              Container(width: 1, height: 40, color: AppTheme.borders),
              _statusItem('Worked', worked, AppTheme.textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  String _workedLabel(Map<String, dynamic>? log) {
    if (log == null) return '0h 00m';
    final wh = (log['worked_hours'] as num?)?.toDouble();
    if (wh != null && wh > 0) {
      final h = wh.floor();
      final m = ((wh - h) * 60).round();
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    final inTs =
        DateTime.tryParse('${log['check_in_time'] ?? log['timestamp']}')?.toUtc();
    final outTs =
        DateTime.tryParse('${log['check_out_time'] ?? log['checkout_time']}')
            ?.toUtc();
    if (inTs == null || outTs == null || !outTs.isAfter(inTs)) return '0h 00m';
    final d = outTs.difference(inTs);
    return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  }

  Widget _statusItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        BodySmallText(label, color: AppTheme.textSecondary),
        const SizedBox(height: AppTheme.spacingXSmall),
        HeadingMediumText(value, color: valueColor),
      ],
    );
  }

  // --- Profile -------------------------------------------------------------

  Widget _buildProfileTab() {
    final s = AppSession.instance;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: [
        const SizedBox(height: AppTheme.spacingMedium),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: AppTheme.primaryColor, size: 44),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              HeadingMediumText(s.employeeName),
              BodySmallText(s.designation, color: AppTheme.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        _profileRow(Icons.business_outlined, 'Company', s.companyName),
        _profileRow(Icons.location_on_outlined, 'Assigned Site',
            s.officeName.isEmpty ? '—' : s.officeName),
        _profileRow(Icons.verified_user_outlined, 'Role', s.role),
        const SizedBox(height: AppTheme.spacingLarge),
        ThemedOutlineButton(
          label: 'View Leave Status',
          icon: Icons.list_alt,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveStatusScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: ThemedCard(
        backgroundColor: AppTheme.darkElements,
        borderColor: AppTheme.borders,
        borderWidth: 0.5,
        shadow: const [],
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(child: BodyMediumText(label)),
            BodyMediumText(value.isEmpty ? '—' : value,
                fontWeight: FontWeight.w600),
          ],
        ),
      ),
    );
  }
}
