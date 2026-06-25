import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_text.dart';
import 'admin_overview_screen.dart';

/// Password gate for the Manager / HR admin dashboard.
///
/// Previously the admin surface opened with no authentication, so anyone could
/// approve flagged attendance or leave. This screen requires the company's
/// username + password (the same bcrypt-checked credentials as the Streamlit
/// portal) before the dashboard is reachable.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.roleLabel});

  /// "Manager" or "HR Admin" — shown in the header for context.
  final String roleLabel;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = HrmsRepository.instance;
      final username = _username.text.trim();
      // Accept EITHER the company login OR a Manager/HR staff account created
      // in the web dashboard (staff_accounts).
      var account = await repo.companyLogin(username, _password.text);
      account ??= await repo.staffLogin(username, _password.text);
      if (!mounted) return;
      if (account == null) {
        setState(() => _error = 'Invalid username or password.');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminOverviewScreen()),
      );
    } on SocketException {
      if (!mounted) return;
      setState(() => _error = 'No internet connection. Check your network.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: HeadingMediumText('${widget.roleLabel} Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingMedium),
                    Icon(Icons.admin_panel_settings_outlined,
                        size: 56, color: AppTheme.primaryColor),
                    const SizedBox(height: AppTheme.spacingMedium),
                    const HeadingMediumText(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    const BodyMediumText(
                      'Enter your company admin credentials to access the '
                      'management dashboard.',
                      color: AppTheme.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    TextFormField(
                      controller: _username,
                      style: AppTheme.bodyLarge,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Company Username',
                        prefixIcon: Icon(Icons.business_outlined,
                            color: AppTheme.textSecondary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your username'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: AppTheme.bodyLarge,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTheme.spacingMedium),
                      BodySmallText(_error!, color: AppTheme.errorColor),
                    ],
                    const SizedBox(height: AppTheme.spacingLarge),
                    ThemedButton(
                      label: 'Sign In',
                      onPressed: _login,
                      isLoading: _busy,
                      icon: Icons.login,
                      textColor: AppTheme.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
