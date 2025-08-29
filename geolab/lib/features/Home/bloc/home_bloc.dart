import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Home/bloc/home_event.dart';
import 'package:geolab/features/Home/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<HomeInitialized>(_onHomeInitialized);
    on<CameraCaptured>(_onCameraCaptured);
    on<CameraFlipped>(_onCameraFlipped);
    on<ImageRemoved>(_onImageRemoved);
    on<ImageSaved>(_onImageSaved);
  }

  void _onHomeInitialized(
    HomeInitialized event,
    Emitter<HomeState> emit,
  ) {
    emit(const HomeLoading());
    emit(const HomeLoaded());
  }

  void _onCameraCaptured(
    CameraCaptured event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        capturedImage: event.image,
        isTakingPicture: false,
      ));
    }
  }

  void _onCameraFlipped(
    CameraFlipped event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(
        currentCameraIndex: (currentState.currentCameraIndex + 1) % 2,
      ));
    }
  }

  void _onImageRemoved(
    ImageRemoved event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(capturedImage: null));
    }
  }

  void _onImageSaved(
    ImageSaved event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      // Handle image saving logic here
      emit(currentState);
    }
  }
}
