import 'dart:io' as io;

import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeInitialized extends HomeEvent {
  const HomeInitialized();
}

class CameraCaptured extends HomeEvent {
  final io.File image;
  const CameraCaptured(this.image);

  @override
  List<Object?> get props => [image];
}

class CameraFlipped extends HomeEvent {
  const CameraFlipped();
}

class ImageRemoved extends HomeEvent {
  const ImageRemoved();
}

class ImageSaved extends HomeEvent {
  final io.File image;
  const ImageSaved(this.image);

  @override
  List<Object?> get props => [image];
}
