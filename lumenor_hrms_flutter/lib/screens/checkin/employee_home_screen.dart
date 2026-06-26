import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

/// Where the device-location flow currently is — drives the geofence card and
/// whether Clock In is allowed.
enum LocationState { checking, serviceDisabled, denied, deniedForever, error, ready }

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

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  bool _loadingDash = true;
  bool _busy = false;
  Map<String, dynamic>? _today; // today's attendance row
  Map<String, dynamic>? _site; // assigned site (with geofence)
  GeofenceResult? _geo; // live GPS vs site
  LocationState _locState = LocationState.checking;
  String? _gpsError;
  Timer? _ticker; // drives the live worked-hours timer while clocked in
  StreamSubscription<ServiceStatus>? _svcSub; // auto-refresh when GPS toggles

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-refresh the instant the user toggles GPS in the system tray.
    _svcSub = Geolocator.getServiceStatusStream().listen((status) {
      if (!mounted) return;
      if (status == ServiceStatus.enabled) {
        _refreshLocation();
      } else {
        setState(() {
          _locState = LocationState.serviceDisabled;
          _geo = null;
        });
      }
    });
    _loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _svcSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from Location/App settings.
    if (state == AppLifecycleState.resumed) _refreshLocation();
  }

  String get _firstName {
    final parts = AppSession.instance.employeeName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  /// Time-based greeting from the device's LOCAL clock.
  String get _greeting {
    final h = DateTime.now().hour; // local
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night'; // 21:00–04:59
  }

  /// Start/stop the per-minute ticker so the worked timer is live only while
  /// the employee is clocked in and not yet clocked out.
  void _syncTicker() {
    _ticker?.cancel();
    if (_checkedInToday && !_clockedOut) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {}); // re-render the live worked label
      });
    }
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
      _site = await repo.assignedOffice(session.employeeId, session.companyId);
    } catch (e) {
      _gpsError = 'Could not load dashboard: $e';
    } finally {
      if (mounted) setState(() => _loadingDash = false);
      _syncTicker(); // start/stop the live worked timer based on today's state
    }
    // Resolve the device location/permission flow against the loaded site.
    await _refreshLocation();
  }

  /// Full device-location flow — GPS service → permission → real fix → geofence.
  /// Drives [_locState] so the card and the Clock In gate reflect reality. Safe
  /// to call repeatedly (on resume, on GPS toggle, on retry).
  Future<void> _refreshLocation() async {
    if (mounted) {
      setState(() {
        _locState = LocationState.checking;
        _gpsError = null;
      });
    }
    try {
      // 1. Location service (GPS) must be ON.
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() {
            _locState = LocationState.serviceDisabled;
            _geo = null;
          });
        }
        return;
      }
      // 2. Permission — request it if not yet granted.
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locState = LocationState.deniedForever;
            _geo = null;
          });
        }
        return;
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.unableToDetermine) {
        if (mounted) {
          setState(() {
            _locState = LocationState.denied;
            _geo = null;
          });
        }
        return;
      }
      // 3. Fetch a real fix and evaluate the geofence against the assigned site.
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final lat = (_site?['latitude'] as num?)?.toDouble();
      final lng = (_site?['longitude'] as num?)?.toDouble();
      final radius = (_site?['radius'] as num?)?.toInt() ?? 200;
      final geo = GeofenceService.evaluate(
          pos: pos, siteLat: lat, siteLng: lng, radius: radius);
      if (mounted) {
        setState(() {
          _geo = geo;
          _locState = LocationState.ready;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locState = LocationState.error;
          _geo = null;
          _gpsError = 'Waiting for GPS… couldn’t get a fix. Tap retry.';
        });
      }
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    // The service stream + onResume also re-check; this covers the rest.
    await Future.delayed(const Duration(milliseconds: 600));
    await _refreshLocation();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    // Re-check happens automatically on resume (didChangeAppLifecycleState).
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
          BodyLargeText(
            _firstName.isEmpty ? _greeting : '$_greeting, $_firstName',
            color: AppTheme.textSecondary,
          ),
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
    final bool ready = _locState == LocationState.ready;
    final bool hasCoords = geo?.hasSiteCoords ?? false;
    final bool inside = geo?.inside ?? false;
    final String siteName =
        (_site?['office_name'] ?? AppSession.instance.officeName).toString();
    final lat = (_site?['latitude'] as num?)?.toDouble();
    final lng = (_site?['longitude'] as num?)?.toDouble();
    final radius = (_site?['radius'] as num?)?.toInt();

    // Header status + icon + accent colour, driven by the location state.
    final (String statusText, IconData icon, Color color) = switch (_locState) {
      LocationState.checking =>
        ('Checking location…', Icons.location_searching, AppTheme.warningColor),
      LocationState.serviceDisabled =>
        ('Location (GPS) is off', Icons.location_disabled, AppTheme.errorColor),
      LocationState.denied => (
          'Location permission needed',
          Icons.location_disabled,
          AppTheme.warningColor
        ),
      LocationState.deniedForever => (
          'Location permission blocked',
          Icons.location_disabled,
          AppTheme.errorColor
        ),
      LocationState.error =>
        ('Location unavailable', Icons.location_off, AppTheme.warningColor),
      LocationState.ready => !hasCoords
          ? (
              'Geofence not set for this site',
              Icons.location_searching,
              AppTheme.warningColor
            )
          : inside
              ? ('Inside geofence', Icons.location_on, AppTheme.successColor)
              : ('Outside assigned site', Icons.location_off, AppTheme.errorColor),
    };

    // Current-GPS line per state.
    final String gpsText = switch (_locState) {
      LocationState.checking => 'Checking…',
      LocationState.serviceDisabled => 'Location (GPS) is turned off.',
      LocationState.denied => 'Permission denied.',
      LocationState.deniedForever => 'Blocked — enable in App Settings.',
      LocationState.error => _gpsError ?? 'Waiting for GPS…',
      LocationState.ready => geo == null
          ? '—'
          : '${geo.latitude.toStringAsFixed(5)}, ${geo.longitude.toStringAsFixed(5)}',
    };

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
                child: _locState == LocationState.checking
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: color),
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
          _kv('Geofence Status', ready && hasCoords ? geo!.statusLabel : '—'),
          _kv('Distance from Site', ready && hasCoords ? geo!.distanceLabel : '—'),
          _kv('Current GPS', gpsText),
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
          // ~38% of a 360dp screen for the label, leaving the rest for the
          // value (which wraps via Expanded) — avoids cramped values on small
          // phones while keeping the key/value columns aligned.
          SizedBox(
            width: 130,
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
      // Clock In is gated on a real GPS fix. Until then, show the action that
      // resolves whatever is blocking location (GPS off / permission / retry).
      if (_locState != LocationState.ready) return _locActionButton();
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

  /// Shown in place of Clock In while location isn't ready — each state offers
  /// the one tap that moves the user forward.
  Widget _locActionButton() {
    switch (_locState) {
      case LocationState.checking:
        return ThemedButton(
          label: 'Checking location…',
          icon: Icons.location_searching,
          height: 56,
          isEnabled: false,
          isLoading: true,
          onPressed: () {},
        );
      case LocationState.serviceDisabled:
        return ThemedButton(
          label: 'Enable Location (GPS)',
          icon: Icons.my_location,
          height: 56,
          backgroundColor: AppTheme.warningColor,
          onPressed: _openLocationSettings,
        );
      case LocationState.denied:
        return ThemedButton(
          label: 'Grant Location Permission',
          icon: Icons.lock_open_outlined,
          height: 56,
          backgroundColor: AppTheme.primaryColor,
          onPressed: _refreshLocation,
        );
      case LocationState.deniedForever:
        return ThemedButton(
          label: 'Open App Settings',
          icon: Icons.settings_outlined,
          height: 56,
          backgroundColor: AppTheme.primaryColor,
          onPressed: _openAppSettings,
        );
      case LocationState.error:
        return ThemedButton(
          label: 'Retry GPS',
          icon: Icons.refresh,
          height: 56,
          backgroundColor: AppTheme.warningColor,
          onPressed: _refreshLocation,
        );
      case LocationState.ready:
        return const SizedBox.shrink();
    }
  }

  // --- Today's status ------------------------------------------------------

  Widget _todayStatusCard() {
    final log = _today;
    final bool hasLog = log != null;
    final String status = hasLog
        ? (log['attendance_status'] ??
                (log['is_present'] == true ? 'Present' : 'Absent'))
            .toString()
        : 'Not Checked In';
    final Color statusColor = _statusColor(status);

    final checkIn =
        hasLog ? _formatTime(log['check_in_time'] ?? log['timestamp']) : '--';
    final outVal = hasLog ? (log['check_out_time'] ?? log['checkout_time']) : null;
    final bool clockedOut = outVal != null && '$outVal'.isNotEmpty;
    final checkOut = clockedOut ? _formatTime(outVal) : '--';
    final worked = _workedLabel(log);
    final bool live = _checkedInToday && !_clockedOut;
    final String dateLabel =
        DateFormat('EEE, dd MMM yyyy').format(DateTime.now());

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
              _statusChip(status, statusColor),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: AppTheme.spacingXSmall),
              BodySmallText(dateLabel, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          const Divider(color: AppTheme.borders, height: 1),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flexible so the three columns shrink instead of overflowing on
              // narrow phones; dividers stay a fixed hairline.
              Flexible(
                child: _statusItem('Check In', checkIn, AppTheme.successColor),
              ),
              Container(width: 1, height: 44, color: AppTheme.borders),
              Flexible(
                child: _statusItem('Check Out', checkOut,
                    clockedOut ? AppTheme.errorColor : AppTheme.textSecondary),
              ),
              Container(width: 1, height: 44, color: AppTheme.borders),
              Flexible(
                child: _statusItem('Worked', worked, AppTheme.textPrimary,
                    bold: true, live: live),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return AppTheme.successColor; // green
      case 'Flagged':
        return AppTheme.warningColor; // orange
      case 'Absent':
      case 'Rejected':
        return AppTheme.errorColor; // red
      default:
        return AppTheme.textSecondary; // Not Checked In
    }
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spacingXSmall),
          BodySmallText(label, color: color, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  /// Worked time. Before clock-in: 0h 00m. While clocked in (no clock-out):
  /// LIVE = now − check-in (re-rendered by the ticker). After clock-out:
  /// stored worked_hours, else check-out − check-in. All UTC-consistent.
  String _workedLabel(Map<String, dynamic>? log) {
    if (log == null) return '0h 00m';
    final checkIn =
        DateTime.tryParse('${log['check_in_time'] ?? log['timestamp'] ?? ''}')
            ?.toUtc();
    if (checkIn == null) return '0h 00m';
    final outIso = '${log['check_out_time'] ?? log['checkout_time'] ?? ''}';
    final checkOut = outIso.isEmpty ? null : DateTime.tryParse(outIso)?.toUtc();

    Duration d;
    if (checkOut != null) {
      final wh = (log['worked_hours'] as num?)?.toDouble();
      d = (wh != null && wh > 0)
          ? Duration(seconds: (wh * 3600).round())
          : checkOut.difference(checkIn);
    } else {
      d = DateTime.now().toUtc().difference(checkIn); // live
    }
    if (d.isNegative) d = Duration.zero;
    return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  }

  Widget _statusItem(String label, String value, Color valueColor,
      {bool bold = false, bool live = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BodySmallText(label, color: AppTheme.textSecondary),
            if (live) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppTheme.successColor, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.spacingXSmall),
        HeadingMediumText(value,
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600),
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
