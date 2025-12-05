import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

abstract class RockClassificationState extends Equatable {
  const RockClassificationState();

  @override
  List<Object?> get props => [];
}

class RockClassificationInitial extends RockClassificationState {}

class CameraInitializing extends RockClassificationState {}

class CameraInitialized extends RockClassificationState {
  final CameraController controller;
  final List<CameraDescription> cameras;

  const CameraInitialized({
    required this.controller,
    required this.cameras,
  });

  @override
  List<Object?> get props => [controller, cameras];
}

class CameraError extends RockClassificationState {
  final String message;

  const CameraError(this.message);

  @override
  List<Object?> get props => [message];
}

class ImageCaptured extends RockClassificationState {
  final io.File image;

  const ImageCaptured(this.image);

  @override
  List<Object?> get props => [image];
}

class Classifying extends RockClassificationState {
  final io.File? image; // Nullable for web (bytes-based)

  const Classifying(this.image);

  @override
  List<Object?> get props => [image];
}

class ClassificationComplete extends RockClassificationState {
  final String rockType;
  final double confidence;
  final io.File? image; // Nullable for web (bytes-based)
  final Map<String, dynamic>? additionalData;

  const ClassificationComplete({
    required this.rockType,
    required this.confidence,
    this.image, // Can be null for web
    this.additionalData,
  });

  @override
  List<Object?> get props => [rockType, confidence, image, additionalData];
}

class ClassificationError extends RockClassificationState {
  final String message;

  const ClassificationError(this.message);

  @override
  List<Object?> get props => [message];
}
