import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

/// Face Recognition Service
///
/// Handles face enrollment, verification, and recognition
class FaceService {
  static final FaceService _instance = FaceService._internal();

  factory FaceService() {
    return _instance;
  }

  FaceService._internal();

  late CameraController _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize camera controller
  Future<void> initializeCamera(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
    } catch (e) {
      throw Exception('Error initializing camera: $e');
    }
  }

  /// Get camera controller
  CameraController get cameraController => _cameraController;

  /// Check if camera is initialized
  bool get isCameraInitialized => _cameraController.value.isInitialized;

  /// Take picture from camera
  Future<XFile?> takePicture() async {
    try {
      if (!_cameraController.value.isInitialized) {
        throw Exception('Camera is not initialized');
      }

      final image = await _cameraController.takePicture();
      return image;
    } catch (e) {
      throw Exception('Error taking picture: $e');
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      return image;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }

  /// Enroll face - captures multiple images for training
  Future<List<XFile>> enrollFace({
    required int requiredSnapshots,
    Duration? timeout,
  }) async {
    try {
      final snapshots = <XFile>[];

      for (int i = 0; i < requiredSnapshots; i++) {
        final snapshot = await takePicture();
        if (snapshot != null) {
          snapshots.add(snapshot);
        }

        // Add delay between captures
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (snapshots.isEmpty) {
        throw Exception('No snapshots captured for face enrollment');
      }

      return snapshots;
    } catch (e) {
      throw Exception('Error enrolling face: $e');
    }
  }

  /// Verify face during login
  Future<bool> verifyFace(XFile image) async {
    try {
      // This is a placeholder for actual face verification logic
      // In production, this would:
      // 1. Extract face embedding from the image
      // 2. Compare with stored embeddings
      // 3. Return confidence score
      // 4. Return true if confidence > threshold

      // For now, we return true as placeholder
      return true;
    } catch (e) {
      throw Exception('Error verifying face: $e');
    }
  }

  /// Extract face embedding from image
  Future<List<double>> extractFaceEmbedding(XFile image) async {
    try {
      // This is a placeholder for actual face embedding extraction
      // In production, this would use ML models like FaceNet, VGGFace2, etc.
      // to extract 128/512 dimensional embeddings

      // Return dummy embeddings for now
      return List<double>.filled(128, 0.0);
    } catch (e) {
      throw Exception('Error extracting face embedding: $e');
    }
  }

  /// Compare two face embeddings
  Future<double> compareFaceEmbeddings(
    List<double> embedding1,
    List<double> embedding2,
  ) async {
    try {
      // Calculate Euclidean distance between embeddings
      if (embedding1.length != embedding2.length) {
        throw Exception('Embedding dimensions do not match');
      }

      double sumSquaredDifferences = 0;
      for (int i = 0; i < embedding1.length; i++) {
        final diff = embedding1[i] - embedding2[i];
        sumSquaredDifferences += diff * diff;
      }

      final distance = math.sqrt(sumSquaredDifferences);
      // Convert distance to similarity score (0-1)
      // Lower distance = higher similarity
      final similarity = 1 / (1 + distance);
      return similarity;
    } catch (e) {
      throw Exception('Error comparing embeddings: $e');
    }
  }

  /// Check if a face is detectable in the image
  Future<bool> isFaceDetectable(XFile image) async {
    try {
      // Placeholder for actual face detection logic
      // This would use ML models to detect if a face is present

      return true;
    } catch (e) {
      throw Exception('Error detecting face: $e');
    }
  }

  /// Dispose camera controller
  Future<void> disposeCamera() async {
    try {
      await _cameraController.dispose();
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  /// Get available cameras
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw Exception('Error getting available cameras: $e');
    }
  }

  /// Get front-facing camera
  static Future<CameraDescription?> getFrontCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      return frontCamera;
    } catch (e) {
      throw Exception('Error getting front camera: $e');
    }
  }
}
