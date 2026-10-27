import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
import 'package:geolab/Service/network_service.dart';
import 'package:geolab/Service/on_device_classifier.dart';
import 'package:geolab/Service/rock_classification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'rock_classification_event.dart';
import 'rock_classification_state.dart';

class RockClassificationBloc
    extends Bloc<RockClassificationEvent, RockClassificationState> {
  final RockClassificationService _classificationService;
  final ApiService _apiService;

  RockClassificationBloc({
    RockClassificationService? classificationService,
    ApiService? apiService,
  })  : _classificationService =
            classificationService ?? RockClassificationServiceImpl(),
        _apiService = apiService ?? ApiService(),
        super(RockClassificationInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CaptureImage>(_onCaptureImage);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<ClassifyRock>(_onClassifyRock);
    on<ClassifyRockFromBytes>(_onClassifyRockFromBytes);
    on<ResetClassification>(_onResetClassification);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<RockClassificationState> emit,
  ) async {
    emit(CameraInitializing());
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        emit(const CameraError('Camera permission is required'));
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(const CameraError('No cameras found'));
        return;
      }

      final controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );

      await controller.initialize();
      emit(CameraInitialized(controller: controller, cameras: cameras));
    } catch (e) {
      emit(CameraError('Camera error: $e'));
    }
  }

  Future<void> _onCaptureImage(
    CaptureImage event,
    Emitter<RockClassificationState> emit,
  ) async {
    if (state is CameraInitialized) {
      final currentState = state as CameraInitialized;
      try {
        final imageFile = await currentState.controller.takePicture();
        final image = io.File(imageFile.path);
        emit(ImageCaptured(image));
        // Await manual classification trigger from user
      } catch (e) {
        emit(CameraError('Error capturing image: $e'));
      }
    }
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event,
    Emitter<RockClassificationState> emit,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final image = io.File(pickedFile.path);
        emit(ImageCaptured(image));
        // Await manual classification trigger from user
      }
    } catch (e) {
      emit(CameraError('Error picking image: $e'));
    }
  }

  Future<void> _onClassifyRock(
    ClassifyRock event,
    Emitter<RockClassificationState> emit,
  ) async {
    emit(Classifying(event.image)); // File-based for mobile

    // No connection: use the bundled model when the app ships one
    if (!await NetworkService().checkConnectivity()) {
      final offline = await _classifyOnDevice(event.image);
      if (offline != null) {
        emit(offline);
        return;
      }
    }

    try {
      // Check if user is authenticated
      final user = await _apiService.getCurrentUser();
      if (user == null) {
        emit(const ClassificationError(
            'Please log in to use rock classification'));
        return;
      }

      // Check subscription status
      try {
        final subscription = await _apiService.getSubscriptionStatus();
        if (!subscription.canMakeRequests) {
          emit(const ClassificationError(
            'Daily limit reached. Please upgrade your subscription or try again tomorrow.',
          ));
          return;
        }
      } catch (e) {
        // If we can't get subscription status, continue with classification

      }

      // Validate image file exists and is readable
      if (!await event.image.exists()) {
        emit(const ClassificationError('Image file not found'));
        return;
      }

      final result = await _classificationService.classifyRock(event.image);
      emit(ClassificationComplete(
        rockType: result.rockType,
        confidence: result.confidence,
        image: event.image,
        additionalData: result.additionalData,
      ));
    } catch (e) {

      String errorMessage = e.toString();

      // Server unreachable: fall back to the bundled model
      if (_isConnectionError(errorMessage)) {
        final offline = await _classifyOnDevice(event.image);
        if (offline != null) {
          emit(offline);
          return;
        }
      }
      
      // Provide user-friendly error messages
      if (errorMessage.contains('Image processing failed')) {
        emit(const ClassificationError('Image processing failed. Please try a different image.'));
      } else if (errorMessage.contains('422')) {
        emit(const ClassificationError('Invalid image format. Please use JPG, PNG, or other supported formats.'));
      } else if (errorMessage.contains('Authentication required')) {
        emit(const ClassificationError('Please log in to use rock classification'));
      } else if (errorMessage.contains('Daily limit reached')) {
        emit(const ClassificationError('Daily limit reached. Please upgrade your subscription or try again tomorrow.'));
      } else {
        emit(ClassificationError('Classification error: ${e.toString()}'));
      }
    }
  }

  static bool _isConnectionError(String message) =>
      message.contains('internet connection') ||
      message.contains('Connection timeout') ||
      message.contains('Connection error') ||
      message.contains('Network error');

  /// Classify with the on-device model, or null when it isn't bundled
  Future<ClassificationComplete?> _classifyOnDevice(io.File image) async {
    final classifier = await OnDeviceClassifier.load();
    if (classifier == null) return null;
    try {
      final result = await classifier.classify(await image.readAsBytes());
      final finalPrediction = result['final_prediction'] as Map<String, dynamic>;
      final isRock = finalPrediction['classification'] != 'non-rock';
      return ClassificationComplete(
        rockType: isRock
            ? (finalPrediction['subclass'] ?? finalPrediction['main_category'] ?? 'rock') as String
            : 'non_rock',
        confidence: (finalPrediction['confidence'] as num).toDouble(),
        image: image,
        additionalData: result,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _onClassifyRockFromBytes(
    ClassifyRockFromBytes event,
    Emitter<RockClassificationState> emit,
  ) async {
    // For web, we use bytes directly
    try {
      emit(Classifying(null, imageBytes: event.imageBytes));
      // Check if user is authenticated
      final user = await _apiService.getCurrentUser();
      if (user == null) {
        emit(const ClassificationError(
            'Please log in to use rock classification'));
        return;
      }

      // Check subscription status
      try {
        final subscription = await _apiService.getSubscriptionStatus();
        if (!subscription.canMakeRequests) {
          emit(const ClassificationError(
            'Daily limit reached. Please upgrade your subscription or try again tomorrow.',
          ));
          return;
        }
      } catch (e) {
        // If we can't get subscription status, continue with classification

      }

      // Validate image size (max 10MB)
      if (event.imageBytes.length > 10 * 1024 * 1024) {
        emit(const ClassificationError('Image size too large. Maximum size is 10MB.'));
        return;
      }

      final result = await _classificationService.classifyRockFromBytes(
        event.imageBytes,
        event.fileName,
      );
      
      // For web, image is null since we don't have File objects
      emit(ClassificationComplete(
        rockType: result.rockType,
        confidence: result.confidence,
        image: null, // Web doesn't have File, so we pass null
        imageBytes: event.imageBytes,
        additionalData: result.additionalData,
      ));
    } catch (e) {

      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('Image processing failed')) {
        emit(const ClassificationError('Image processing failed. Please try a different image.'));
      } else if (errorMessage.contains('size too large')) {
        emit(const ClassificationError('Image size too large. Please use an image under 10MB.'));
      } else {
        emit(ClassificationError('Classification failed: ${errorMessage.replaceAll('Exception: ', '')}'));
      }
    }
  }

  void _onResetClassification(
    ResetClassification event,
    Emitter<RockClassificationState> emit,
  ) {
    if (state is CameraInitialized) {
      emit(state);
    } else {
      emit(RockClassificationInitial());
    }
  }

  @override
  Future<void> close() {
    if (state is CameraInitialized) {
      (state as CameraInitialized).controller.dispose();
    }
    return super.close();
  }
}
