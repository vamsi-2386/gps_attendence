import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/face_detection_service.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_text.dart';
import 'scanning_state_screen.dart';

/// Position Your Face (login) screen.
///
/// Live front-camera preview with on-device face-alignment detection. Login is
/// Employee Code + Face Verification: the code is looked up in Supabase, then
/// the face scan completes auth. The "Verify Code & Scan Face" button only
/// enables once a single face is detected and aligned inside the oval.
///
/// Layout only — registration, backend APIs, and verification logic unchanged.
class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key, this.employeeName = 'Priya Sharma'});

  /// Name shown as a subtle hint while positioning the face.
  final String employeeName;

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen>
    with WidgetsBindingObserver {
  final _employeeCode = TextEditingController();

  CameraController? _controller;
  final FaceDetectionService _faceDetection = FaceDetectionService();

  bool _initializing = true;
  bool _permissionDenied = false;
  String? _setupError;
  bool _verifyingCode = false;

  FacePosition _position = FacePosition.none;
  bool get _aligned => _position == FacePosition.aligned;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _employeeCode.dispose();
    _teardownCamera();
    _faceDetection.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _teardownCamera();
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  Future<void> _setup() async {
    setState(() {
      _initializing = true;
      _setupError = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _initializing = false;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      await controller.startImageStream(_onFrame);

      setState(() {
        _initializing = false;
        _permissionDenied = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _setupError = 'Could not start the camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _teardownCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}
      await controller.dispose();
    }
  }

  void _onFrame(CameraImage image) {
    final controller = _controller;
    if (controller == null || _verifyingCode) return;
    _faceDetection
        .analyze(image, controller.description.sensorOrientation)
        .then((analysis) {
      if (analysis == null || !mounted) return;
      if (analysis.position != _position) {
        setState(() => _position = analysis.position);
      }
    });
  }

  // --- Verification logic (unchanged): Employee Code lookup → face scan. ---
  Future<void> _verifyCodeAndScan() async {
    final code = _employeeCode.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your Employee Code first.')),
      );
      return;
    }

    setState(() => _verifyingCode = true);
    try {
      final emp = await HrmsRepository.instance.employeeByCode(code);
      if (!mounted) return;
      if (emp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No employee found for code "$code".'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      // Code verified → switch the active identity to this employee so the
      // scan, attendance marking, dashboard, and history reflect them.
      await AppSession.instance.signInAs(emp);
      await _teardownCamera();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanningStateScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lookup failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLarge,
            AppTheme.spacingMedium,
            AppTheme.spacingLarge,
            AppTheme.spacingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeadingLargeText(
                'Position Your Face',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXSmall),
              const BodyMediumText(
                'Position your face inside the oval.',
                color: AppTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              // Large camera preview fills the available vertical space.
              Expanded(child: _preview()),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: _employeeCode,
                textCapitalization: TextCapitalization.characters,
                style: AppTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Employee Code',
                  hintText: 'e.g., EMP-1042',
                  prefixIcon: Icon(Icons.tag, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              ThemedButton(
                label: _aligned
                    ? 'Verify Code & Scan Face'
                    : 'Align your face to continue',
                icon: Icons.face_retouching_natural,
                onPressed: _verifyCodeAndScan,
                isEnabled: _aligned,
                isLoading: _verifyingCode,
                backgroundColor:
                    _aligned ? AppTheme.primaryColor : AppTheme.darkElements,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    if (_permissionDenied) {
      return _stateCard(
        icon: Icons.no_photography_outlined,
        title: 'Camera blocked',
        message: 'Enable camera access to log in with your face.',
        action: ThemedButton(
          label: 'Open Settings',
          onPressed: openAppSettings,
          icon: Icons.settings_outlined,
        ),
      );
    }
    if (_setupError != null) {
      return _stateCard(
        icon: Icons.error_outline,
        title: 'Camera error',
        message: _setupError!,
        action: ThemedButton(
          label: 'Retry',
          onPressed: _setup,
          icon: Icons.refresh,
        ),
      );
    }

    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return _frameCard(child: const Center(child: CircularProgressIndicator()));
    }

    final Color ringColor =
        _aligned ? AppTheme.successColor : AppTheme.primaryColor;

    return _frameCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Oval sized relative to the card; positioned slightly above center.
          final ovalH =
              (constraints.maxHeight * 0.66).clamp(180.0, 340.0).toDouble();
          final ovalW = ovalH * 0.78;
          return Stack(
            fit: StackFit.expand,
            children: [
              _coveredPreview(controller),
              Container(color: Colors.black.withValues(alpha: 0.08)),
              Align(
                alignment: const Alignment(0, -0.18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: ovalW,
                  height: ovalH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ovalW),
                    border: Border.all(color: ringColor, width: 4),
                    boxShadow: _aligned
                        ? [
                            BoxShadow(
                              color: AppTheme.successColor
                                  .withValues(alpha: 0.5),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              if (_aligned)
                const Positioned(
                  top: AppTheme.spacingMedium,
                  right: AppTheme.spacingMedium,
                  child: Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 30),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Rounded card wrapper that clips the camera feed to the theme corners.
  Widget _frameCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: AppTheme.borders, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Scale the preview so it covers the card without distortion.
  Widget _coveredPreview(CameraController controller) {
    final preview = controller.value.previewSize;
    if (preview == null) return CameraPreview(controller);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: preview.height,
        height: preview.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return _frameCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingMedium),
            HeadingMediumText(title, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingSmall),
            BodySmallText(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLarge),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
