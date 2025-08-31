import 'dart:io' as io;

import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final io.File? capturedImage;
  final bool isTakingPicture;
  final int currentCameraIndex;

  const HomeLoaded({
    this.capturedImage,
    this.isTakingPicture = false,
    this.currentCameraIndex = 0,
  });

  @override
  List<Object?> get props =>
      [capturedImage, isTakingPicture, currentCameraIndex];

  HomeLoaded copyWith({
    io.File? capturedImage,
    bool? isTakingPicture,
    int? currentCameraIndex,
  }) {
    return HomeLoaded(
      capturedImage: capturedImage ?? this.capturedImage,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      currentCameraIndex: currentCameraIndex ?? this.currentCameraIndex,
    );
  }
}
