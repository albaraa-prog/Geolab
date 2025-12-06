import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolab/Service/api_service.dart' as geolabApi;
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';


class ClassificationResultModal extends StatelessWidget {
  final ClassificationComplete state;
  final ThemeService themeService;

  const ClassificationResultModal({
    super.key,
    required this.state,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: ResponsiveLayout.isWeb(context) ? 500 : null,
      child: RTLWrapper(
        child: SingleChildScrollView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('rockClassification.result'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeService.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${context.t('rockClassification.rockType')}: ${state.rockType}',
                style: TextStyle(
                  fontSize: 18,
                  color: themeService.textColor,
                ),
              ),
              Text(
                '${context.t('rockClassification.confidence')}: ${(state.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: themeService.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              _buildAdditionalData(context),
              const SizedBox(height: 20),
              Align(
                alignment: RTLUtils.endAlignment(context),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeService.primaryColor,
                  ),
                  child: Text(
                    context.t('common.close'),
                    style: TextStyle(color: themeService.onSurfaceColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalData(BuildContext context) {
    // Check if additional data handles images internally
    
    final api = geolabApi.ApiService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: () {
            // Determine which image data to use
            final imageFile = (state as dynamic).image as io.File?;
            final imageUrl = state.additionalData != null ? state.additionalData!['image_url'] as String? : null;

            return api.explainPrediction(
              predictedClass: state.rockType,
              confidence: state.confidence,
              imageFile: imageFile, 
              imageUrl: imageUrl,
              fileName: 'rock_visualization.jpg',
            );
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Could not generate explanation. ${snapshot.error}',
                style: TextStyle(color: Colors.red.withOpacity(0.8), fontStyle: FontStyle.italic),
              );
            }
            
            if (!snapshot.hasData) {
              final loadingText = context.t('rockClassification.generatingExplanation') !=
                      'rockClassification.generatingExplanation'
                  ? context.t('rockClassification.generatingExplanation')
                  : 'Generating explanation...';
              return Text(
                loadingText,
                style: TextStyle(color: themeService.textColor.withOpacity(0.8)),
              );
            }

            final data = snapshot.data!;
            final explanation = data['explanation'] as String;
            final xaiPath = data['xai_visualization'] as String?;
            final xaiUrl = xaiPath != null ? api.buildFileUrl(xaiPath) : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (xaiUrl != null) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: double.infinity,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        xaiUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  explanation,
                  style: TextStyle(
                      color: themeService.textColor.withOpacity(0.8)),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
