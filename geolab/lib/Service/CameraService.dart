/*import 'dart:async';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0;

  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Camera permission is required');
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw Exception('No cameras found');
      }

      _controller = CameraController(
        cameras![_currentCameraIndex],
        ResolutionPreset.medium,
      );
      await _controller!.initialize();
    } catch (e) {
      throw Exception('Camera error: $e');
    }
  }

  Future<XFile?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return await _controller!.takePicture();
  }

  Future<void> flipCamera() async {
    if (cameras == null || cameras!.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % cameras!.length;
    await _controller?.dispose();
    _controller = CameraController(
      cameras![_currentCameraIndex],
      ResolutionPreset.medium,
    );
    await _controller!.initialize();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
  }
}
*/