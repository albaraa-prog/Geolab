import 'dart:io';

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
  final File image;

  const ClassifyRock(this.image);

  @override
  List<Object?> get props => [image];
}

class ResetClassification extends RockClassificationEvent {}
