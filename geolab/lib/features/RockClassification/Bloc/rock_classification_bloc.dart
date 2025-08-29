import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/rock_classification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'rock_classification_event.dart';
import 'rock_classification_state.dart';

class RockClassificationBloc
    extends Bloc<RockClassificationEvent, RockClassificationState> {
  final RockClassificationService _classificationService;

  RockClassificationBloc({
    RockClassificationService? classificationService,
  })  : _classificationService =
            classificationService ?? RockClassificationServiceImpl(),
        super(RockClassificationInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CaptureImage>(_onCaptureImage);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<ClassifyRock>(_onClassifyRock);
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
        final image = File(imageFile.path);
        emit(ImageCaptured(image));
        add(ClassifyRock(image));
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
        final image = File(pickedFile.path);
        emit(ImageCaptured(image));
        add(ClassifyRock(image));
      }
    } catch (e) {
      emit(CameraError('Error picking image: $e'));
    }
  }

  Future<void> _onClassifyRock(
    ClassifyRock event,
    Emitter<RockClassificationState> emit,
  ) async {
    emit(Classifying(event.image));
    try {
      final result = await _classificationService.classifyRock(event.image);
      emit(ClassificationComplete(
        rockType: result.rockType,
        confidence: result.confidence,
        image: event.image,
        additionalData: result.additionalData,
      ));
    } catch (e) {
      emit(ClassificationError('Classification error: $e'));
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
