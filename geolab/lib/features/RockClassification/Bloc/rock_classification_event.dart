import 'dart:io' as io;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class RockClassificationEvent extends Equatable {
  const RockClassificationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCamera extends RockClassificationEvent {}

class CaptureImage extends RockClassificationEvent {}

class PickImageFromGallery extends RockClassificationEvent {}

class ClassifyRock extends RockClassificationEvent {
  final io.File image;

  const ClassifyRock(this.image);

  @override
  List<Object?> get props => [image];
}

class ClassifyRockFromBytes extends RockClassificationEvent {
  final Uint8List imageBytes;
  final String fileName;

  const ClassifyRockFromBytes(this.imageBytes, {this.fileName = 'image.jpg'});

  @override
  List<Object?> get props => [imageBytes, fileName];
}

class ResetClassification extends RockClassificationEvent {}
