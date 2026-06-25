import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/app_session.dart';
import 'services/device_security_service.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/security_blocked_screen.dart';
import 'screens/checkin/employee_home_screen.dart';

/// Build with --dart-define=DEMO_HOME=true to launch straight into the
/// employee dashboard (skips onboarding) for demoing live data.
const bool _demoHome = bool.fromEnvironment('DEMO_HOME', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
    // Seed the demo identity from the live DB so screens show real data.
    await AppSession.instance.hydrate();
  } catch (e) {
    // Non-fatal: the UI still renders with mock data if Supabase is unreachable.
    debugPrint('Warning: Supabase initialization failed: $e');
  }

  runApp(const LumenorHRMSApp());
}

/// Main Application Widget
class LumenorHRMSApp extends StatelessWidget {
  const LumenorHRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumenor HRMS',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      home: const SecurityGate(),
    );
  }
}

/// Anti-tampering gate. Blocks the app while Android "Developer options" is
/// enabled (a common vector for mock-location / debugging tools that would
/// undermine GPS attendance integrity). Enforced only in release/profile so
/// developers can still run debug builds. Re-checks on resume so toggling the
/// setting from system Settings takes effect immediately on return.
class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  // null = still checking, true = blocked, false = allowed.
  bool? _blocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    // Debug builds bypass the gate so the app can be developed/tested on a
    // device that (necessarily) has USB debugging on.
    if (kDebugMode) {
      if (mounted) setState(() => _blocked = false);
      return;
    }
    final enabled = await DeviceSecurity.isDeveloperOptionsEnabled();
    if (mounted) setState(() => _blocked = enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_blocked == true) {
      return SecurityBlockedScreen(onRetry: _check);
    }
    return _demoHome ? const EmployeeHomeScreen() : const SplashScreen();
  }
}
