import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../config/app_theme.dart';
import 'themed_text.dart';

/// Face Scanner Widget
///
/// Widget for scanning and capturing face for attendance
class FaceScannerWidget extends StatefulWidget {
  final CameraController? cameraController;
  final VoidCallback? onCapture;
  final String? instructionText;
  final bool isScanning;

  const FaceScannerWidget({
    Key? key,
    this.cameraController,
    this.onCapture,
    this.instructionText,
    this.isScanning = false,
  }) : super(key: key);

  @override
  State<FaceScannerWidget> createState() => _FaceScannerWidgetState();
}

class _FaceScannerWidgetState extends State<FaceScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera preview
          if (widget.cameraController != null &&
              widget.cameraController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: CameraPreview(widget.cameraController!),
            )
          else
            Container(
              color: AppTheme.darkGray,
              child: const Center(
                child: BodyLargeText(
                  'Camera not initialized',
                  color: AppTheme.white,
                ),
              ),
            ),

          // Scanning overlay
          if (widget.isScanning)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),

          // Face detection frame
          _FaceDetectionFrame(
            isScanning: widget.isScanning,
            scaleAnimation: _scaleAnimation,
          ),

          // Instructions
          if (widget.instructionText != null)
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: BodySmallText(
                  widget.instructionText!,
                  color: AppTheme.white,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Capture button
          if (widget.onCapture != null && !widget.isScanning)
            Positioned(
              bottom: 20,
              child: GestureDetector(
                onTap: widget.onCapture,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.elevatedShadow(),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.white,
                    size: 28,
                  ),
                ),
              ),
            ),

          // Scanning indicator
          if (widget.isScanning)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                const BodyLargeText(
                  'Scanning face...',
                  color: AppTheme.white,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Face Detection Frame
class _FaceDetectionFrame extends StatelessWidget {
  final bool isScanning;
  final Animation<double> scaleAnimation;

  const _FaceDetectionFrame({
    required this.isScanning,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Container(
          width: 200 * scaleAnimation.value,
          height: 240 * scaleAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isScanning
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
              width: 3,
            ),
          ),
          child: CustomPaint(
            painter: _CornersPainter(
              color: isScanning
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }
}

/// Corners painter for frame
class _CornersPainter extends CustomPainter {
  final Color color;

  _CornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // Top left
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(0, cornerLength),
      paint,
    );

    // Top right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// Face Capture Preview
class FaceCapturePreview extends StatelessWidget {
  final String? imagePath;
  final VoidCallback? onRetake;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const FaceCapturePreview({
    Key? key,
    required this.imagePath,
    this.onRetake,
    this.onConfirm,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Stack(
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Image.file(
                imagePath as dynamic,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else
            Container(
              color: AppTheme.darkGray,
              child: const Center(
                child: BodyLargeText(
                  'No image captured',
                  color: AppTheme.white,
                ),
              ),
            ),
          Positioned(
            bottom: AppTheme.spacingLarge,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onRetake != null)
                  GestureDetector(
                    onTap: isLoading ? null : onRetake,
                    child: Container(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingMedium,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.elevatedShadow(),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: AppTheme.white,
                        size: 28,
                      ),
                    ),
                  ),
                if (onConfirm != null)
                  GestureDetector(
                    onTap: isLoading ? null : onConfirm,
                    child: Container(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingMedium,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.elevatedShadow(),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.check,
                              color: AppTheme.white,
                              size: 28,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
