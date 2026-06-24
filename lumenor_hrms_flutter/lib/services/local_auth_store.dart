import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether an employee has registered on THIS device.
///
/// Used only by the Role Selection screen to decide whether a returning
/// employee skips registration and goes straight to the login page. Does not
/// touch registration fields, the DB schema, attendance, or face logic.
class LocalAuthStore {
  LocalAuthStore._();

  static const _kCode = 'registered_employee_code';
  static const _kId = 'registered_employee_id';
  static const _kName = 'registered_employee_name';

  /// Record the employee created on this device after a successful registration.
  static Future<void> setRegisteredEmployee({
    required String employeeCode,
    required int employeeId,
    required String name,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCode, employeeCode);
    await p.setInt(_kId, employeeId);
    await p.setString(_kName, name);
  }

  /// The employee code registered on this device, or null if none.
  static Future<String?> registeredEmployeeCode() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_kCode);
    return (c == null || c.isEmpty) ? null : c;
  }

  static Future<bool> isRegistered() async =>
      (await registeredEmployeeCode()) != null;

  /// Clear the local registration marker (e.g. if the record no longer exists
  /// server-side).
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCode);
    await p.remove(_kId);
    await p.remove(_kName);
  }
}
