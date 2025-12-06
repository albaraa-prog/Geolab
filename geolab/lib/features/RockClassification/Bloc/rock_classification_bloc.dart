import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/api_service.dart';
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
        // Removed automatic classification - user must press Classify button
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
        // Removed automatic classification - user must press Classify button
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
    try {
      // Check if user is authenticated
      // BYPASS AUTH CHECK FOR TESTING
      /*
      final isAuthenticated = await _apiService.isAuthenticated();
      if (!isAuthenticated) {
        emit(const ClassificationError(
            'Please log in to use rock classification'));
        return;
      }
      */

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
        print('Warning: Could not verify subscription status: $e');
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
      print('Classification error: $e');
      String errorMessage = e.toString();
      
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

  Future<void> _onClassifyRockFromBytes(
    ClassifyRockFromBytes event,
    Emitter<RockClassificationState> emit,
  ) async {
    // For web, we use bytes directly
    try {
      emit(const Classifying(null));
      // Check if user is authenticated
      // BYPASS AUTH CHECK FOR TESTING
      /*
      final isAuthenticated = await _apiService.isAuthenticated();
      if (!isAuthenticated) {
        emit(const ClassificationError(
            'Please log in to use rock classification'));
        return;
      }
      */

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
        print('Warning: Could not verify subscription status: $e');
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
        additionalData: result.additionalData,
      ));
    } catch (e) {
      print('Classification error: $e');
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
