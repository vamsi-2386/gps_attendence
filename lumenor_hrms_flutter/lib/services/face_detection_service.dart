import 'dart:io';
import 'dart:ui' show Size, Rect;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// How well the detected face is positioned inside the on-screen oval guide.
enum FacePosition {
  /// No face detected in the frame.
  none,

  /// More than one face — ambiguous, reject.
  multiple,

  /// A single face is present but not centered correctly.
  misaligned,

  /// Face too far (small) — ask the user to move closer.
  tooFar,

  /// Face too close (large) — ask the user to move back.
  tooClose,

  /// A single face is correctly centered and sized inside the oval.
  aligned,
}

/// Result of analysing a single camera frame.
class FaceAnalysis {
  const FaceAnalysis({
    required this.position,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smiling,
    this.headEulerY,
    this.boundingBox,
  });

  final FacePosition position;
  final double? leftEyeOpen; // probability eye is open (0..1)
  final double? rightEyeOpen;
  final double? smiling; // probability smiling (0..1)
  final double? headEulerY; // head turn left/right in degrees
  final Rect? boundingBox;

  bool get hasFace =>
      position != FacePosition.none && position != FacePosition.multiple;
}

/// Wraps ML Kit's [FaceDetector] for the camera image stream.
///
/// Responsibilities:
///  - run on-device face detection over each [CameraImage]
///  - decide whether the single face is correctly placed in the oval guide
///  - surface eye-open / smile / head-turn signals used for liveness
class FaceDetectionService {
  FaceDetectionService();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // eye-open + smile probabilities
      enableLandmarks: false,
      enableContours: false,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  bool _busy = false;

  /// Analyse a single camera frame. Returns `null` if a frame is already being
  /// processed (we drop frames to keep the stream real-time).
  Future<FaceAnalysis?> analyze(
    CameraImage image,
    int sensorOrientation,
  ) async {
    if (_busy) return null;
    _busy = true;
    try {
      final input = _toInputImage(image, sensorOrientation);
      if (input == null) {
        return const FaceAnalysis(position: FacePosition.none);
      }

      final faces = await _detector.processImage(input);
      if (faces.isEmpty) {
        return const FaceAnalysis(position: FacePosition.none);
      }
      if (faces.length > 1) {
        return const FaceAnalysis(position: FacePosition.multiple);
      }

      final face = faces.first;
      final imageSize =
          Size(image.width.toDouble(), image.height.toDouble());
      final position = _classifyPosition(face.boundingBox, imageSize);

      return FaceAnalysis(
        position: position,
        leftEyeOpen: face.leftEyeOpenProbability,
        rightEyeOpen: face.rightEyeOpenProbability,
        smiling: face.smilingProbability,
        headEulerY: face.headEulerAngleY,
        boundingBox: face.boundingBox,
      );
    } catch (e) {
      debugPrint('Face detection error: $e');
      return const FaceAnalysis(position: FacePosition.none);
    } finally {
      _busy = false;
    }
  }

  /// Decide how well the face fills the central oval target.
  FacePosition _classifyPosition(Rect box, Size imageSize) {
    final faceArea = box.width * box.height;
    final frameArea = imageSize.width * imageSize.height;
    final ratio = faceArea / frameArea;

    // Centering: the face center should be near the middle of the frame.
    final cx = box.center.dx / imageSize.width;
    final cy = box.center.dy / imageSize.height;
    final centered = (cx - 0.5).abs() < 0.22 && (cy - 0.5).abs() < 0.24;

    if (!centered) return FacePosition.misaligned;
    if (ratio < 0.10) return FacePosition.tooFar;
    if (ratio > 0.55) return FacePosition.tooClose;
    return FacePosition.aligned;
  }

  /// Convert a [CameraImage] to ML Kit's [InputImage].
  InputImage? _toInputImage(CameraImage image, int sensorOrientation) {
    final rotation = _rotationFromSensor(sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (image.planes.isEmpty) return null;

    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format ??
            (Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888),
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
