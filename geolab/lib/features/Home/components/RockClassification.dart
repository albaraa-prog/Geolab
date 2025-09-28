import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/config/theme_service.dart';

class RockClassificationPage extends StatelessWidget {
  const RockClassificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RockClassificationBloc()..add(InitializeCamera()),
      child: const RockClassificationView(),
    );
  }
}

class RockClassificationView extends StatelessWidget {
  const RockClassificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rock Classification'),
        backgroundColor: themeService.primaryColor,
        foregroundColor: themeService.onPrimaryColor,
      ),
      body: BlocBuilder<RockClassificationBloc, RockClassificationState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: _buildMainContent(context, state),
                ),
              ),
              _buildBottomControls(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, RockClassificationState state) {
    if (state is CameraInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CameraError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (state is CameraInitialized) {
      return CameraPreview(state.controller);
    }

    if (state is ImageCaptured || state is Classifying) {
      final image =
          state is ImageCaptured ? state.image : (state as Classifying).image;
      return Stack(
        children: [
          Image.file(image, fit: BoxFit.contain),
          if (state is Classifying)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      );
    }

    if (state is ClassificationComplete) {
      return Stack(
        children: [
          Image.file(
            (state as dynamic).image,
            fit: BoxFit.contain,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rock Type: ${state.rockType}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Confidence: ${(state.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text(
        'Something went wrong',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, RockClassificationState state) {
    final themeService = ThemeService.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      color: themeService.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (state is ImageCaptured ||
              state is Classifying ||
              state is ClassificationComplete)
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<RockClassificationBloc>()
                    .add(ResetClassification());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('New Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
              ),
            )
          else if (state is CameraInitialized) ...[
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<RockClassificationBloc>()
                    .add(PickImageFromGallery());
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                context.read<RockClassificationBloc>().add(CaptureImage());
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
