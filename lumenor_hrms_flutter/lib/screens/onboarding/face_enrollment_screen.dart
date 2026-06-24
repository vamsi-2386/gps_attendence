import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_theme.dart';
import '../../models/employee_registration.dart';
import '../../services/api_service.dart';
import '../../services/face_detection_service.dart';
import '../../widgets/themed_button.dart';
import '../../widgets/themed_text.dart';
import 'profile_confirmation_screen.dart';

/// Face Enrollment Screen
///
/// Live camera enrollment with on-device ML Kit **face detection only** —
/// no liveness gesture.
///
/// Flow: Face alignment → Scan Face → Submit.
///  1. Requests camera permission, shows a live front-camera preview.
///  2. The oval guide turns green when a single real face is centered/sized.
///  3. Once a face is aligned, "Scan Face" enables; tapping it captures the
///     frame, sends it to the backend for verification, and advances on.
class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key, this.registration});

  /// Registration details collected on the previous screen; the captured
  /// photo path is attached here and carried to profile confirmation.
  final EmployeeRegistration? registration;

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final FaceDetectionService _faceDetection = FaceDetectionService();

  bool _initializing = true;
  bool _permissionDenied = false;
  String? _setupError;
  bool _streaming = false;
  bool _capturing = false;

  FacePosition _position = FacePosition.none;

  // Live debug values.
  double? _leftEyeOpen;
  double? _rightEyeOpen;

  bool get _aligned => _position == FacePosition.aligned;
  bool get _faceDetected =>
      _position != FacePosition.none && _position != FacePosition.multiple;
  bool get _readyToCapture => _aligned && !_capturing && _streaming;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        imageFormatGroup: ImageFormatGroup.nv21, // ML Kit-friendly on Android
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      await controller.startImageStream(_onFrame);
      _streaming = true;

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
    _streaming = false;
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
    if (controller == null || _capturing) return;

    _faceDetection
        .analyze(image, controller.description.sensorOrientation)
        .then((analysis) {
      if (analysis == null || !mounted) return;
      setState(() {
        _position = analysis.position;
        _leftEyeOpen = analysis.leftEyeOpen;
        _rightEyeOpen = analysis.rightEyeOpen;
      });
    });
  }

  Future<void> _scanFace() async {
    final controller = _controller;
    if (controller == null || !_readyToCapture) return;

    setState(() => _capturing = true);
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      _streaming = false;

      final XFile shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();

      // Attach the captured photo to the registration for confirmation/create.
      widget.registration?.facePhotoPath = shot.path;

      String? verifyNote;
      try {
        final res = await ApiService().verifyFaceFrame(bytes);
        verifyNote = res['status']?.toString();
      } catch (e) {
        verifyNote = 'offline';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verifyNote == 'offline'
                ? 'Face captured. Saved locally (backend offline).'
                : 'Face captured and sent for verification.',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileConfirmationScreen(registration: widget.registration),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capture failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(title: const HeadingMediumText('Enroll Face')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            children: [
              BodyLargeText(
                _instruction(),
                color: AppTheme.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              Expanded(child: Center(child: _preview())),
              const SizedBox(height: AppTheme.spacingMedium),
              _faceStatus(),
              const SizedBox(height: AppTheme.spacingSmall),
              _debugPanel(),
              const SizedBox(height: AppTheme.spacingMedium),
              ThemedButton(
                label: _capturing
                    ? 'Capturing…'
                    : _readyToCapture
                        ? 'Scan Face'
                        : 'Position your face',
                onPressed: _scanFace,
                isLoading: _capturing,
                isEnabled: _readyToCapture,
                icon: Icons.camera_alt_outlined,
                backgroundColor: _readyToCapture
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _instruction() {
    if (_permissionDenied) return 'Camera permission is required to enroll.';
    if (_setupError != null) return _setupError!;
    if (_initializing) return 'Starting camera…';
    switch (_position) {
      case FacePosition.none:
        return 'Position your face inside the oval.';
      case FacePosition.multiple:
        return 'Multiple faces detected — only you should be in frame.';
      case FacePosition.tooFar:
        return 'Move a little closer.';
      case FacePosition.tooClose:
        return 'Move back slightly.';
      case FacePosition.misaligned:
        return 'Center your face in the oval.';
      case FacePosition.aligned:
        return 'Face detected — tap Scan Face.';
    }
  }

  Widget _preview() {
    if (_permissionDenied) {
      return _stateCard(
        icon: Icons.no_photography_outlined,
        title: 'Camera blocked',
        message: 'Enable camera access to continue enrollment.',
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
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Color frameColor =
        _aligned ? AppTheme.successColor : AppTheme.primaryColor;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _coveredPreview(controller),
            Container(color: Colors.black.withValues(alpha: 0.10)),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 210,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(140),
                  border: Border.all(color: frameColor, width: 4),
                  boxShadow: _aligned
                      ? [
                          BoxShadow(
                            color: AppTheme.successColor.withValues(alpha: 0.5),
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
                    color: AppTheme.successColor, size: 32),
              ),
          ],
        ),
      ),
    );
  }

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
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkElements,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.borders, width: 0.5),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingMedium),
            HeadingMediumText(title),
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

  /// Single status indicator: face detected.
  Widget _faceStatus() {
    final Color color = _aligned ? AppTheme.successColor : AppTheme.primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _aligned
                ? AppTheme.successColor.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            _aligned ? Icons.check : Icons.face_outlined,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        BodyLargeText(
          _aligned ? 'Face detected' : 'Detecting face…',
          color: color,
        ),
      ],
    );
  }

  /// Live debug overlay for tuning detection on-device.
  Widget _debugPanel() {
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _debugRow('faceDetected', _faceDetected.toString()),
          _debugRow('position', _position.name),
          _debugRow('leftEyeOpenProbability', fmt(_leftEyeOpen)),
          _debugRow('rightEyeOpenProbability', fmt(_rightEyeOpen)),
        ],
      ),
    );
  }

  Widget _debugRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BodySmallText(key, color: AppTheme.textSecondary),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
