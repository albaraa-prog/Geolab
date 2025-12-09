import 'package:camera/camera.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/Service/theme_service.dart';

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
      return Stack(
        children: [
          CameraPreview(state.controller),
          // App branding overlay at top
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'GeoLab',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-Powered Rock Classification',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state is ImageCaptured || state is Classifying) {
      final image =
          state is ImageCaptured ? state.image : (state as Classifying).image;
      return Stack(
        children: [
          Image.file(image!, fit: BoxFit.contain),
          if (state is Classifying)
            // Enhanced loading animation
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Lottie.asset(
                        'assets/animations/uploading_image.json',
                        width: 350,
                        height: 350,
                        delegates: LottieDelegates(
                          values: [
                            ValueDelegate.color(
                              const ['**'],
                              value: ThemeService.instance.primaryColor,
                            ),
                            ValueDelegate.strokeColor(
                              const ['**'],
                              value: ThemeService.instance.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          if (state is ImageCaptured) ...[
            // Remove/Retake Button
            OutlinedButton.icon(
              onPressed: () {
                context
                    .read<RockClassificationBloc>()
                    .add(ResetClassification());
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
            // Classify Button
            ElevatedButton.icon(
              onPressed: () {
                final image = state.image;
                if (image != null) {
                  context
                      .read<RockClassificationBloc>()
                      .add(ClassifyRock(image));
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Classify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else if (state is Classifying) ...[
             const Text('Processing...'),
          ] else if (state is ClassificationComplete) ...[
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
            ),
          ] else if (state is CameraInitialized) ...[
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

