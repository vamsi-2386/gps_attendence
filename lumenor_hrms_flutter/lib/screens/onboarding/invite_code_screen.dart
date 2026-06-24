import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';
import 'face_enrollment_screen.dart';

/// Invite Code Screen
///
/// Validates the company invite code during onboarding, then advances to
/// face enrollment.
class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Validate invite code with backend (mocked here).
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FaceEnrollmentScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Company Invite Code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingMedium),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.vpn_key_outlined,
                    color: AppTheme.primaryColor,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const HeadingLargeText(
                'Join your company',
                color: AppTheme.textPrimary,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              const BodyLargeText(
                'Enter the invite code shared by your HR admin to '
                'link your account.',
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _inviteCodeController,
                  validator: Validators.validateInviteCode,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g., LUMN24',
                    labelText: 'Invite Code',
                    prefixIcon: Icon(Icons.vpn_key, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.darkElements,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.borders, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.infoColor, size: 20),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: BodySmallText(
                        'Codes are 6+ characters, uppercase letters and '
                        'numbers only.',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              ThemedButton(
                label: 'Validate',
                onPressed: _validateAndProceed,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
