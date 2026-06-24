import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/app_session.dart';
import 'screens/onboarding/splash_screen.dart';
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
      home: _demoHome ? const EmployeeHomeScreen() : const SplashScreen(),
    );
  }
}
