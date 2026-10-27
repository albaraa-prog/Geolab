

import 'package:flutter/material.dart';
import 'package:geolab/Service/api_service.dart' as geolabApi;
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/features/Home/components/XaiDistributionChart.dart';
import 'package:geolab/features/Home/components/GradCamView.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/Service/pdf_generation_service.dart';
import 'package:geolab/Service/xai_explanation_service.dart';
import 'package:geolab/utils/pdf_handler/pdf_handler.dart';
import 'package:geolab/utils/error_handler.dart';

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
                '${context.t('rockClassification.rockType')}: ${state.rockType == "non_rock" ? "Not a Rock" : state.rockType.replaceAll('_', ' ')}',
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _shareResult(context),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      // Just hardcode Share for simplicity/safety vs localization map
                      label: Text(context.t('rockClassification.saveAnalysisPdf')), 
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeService.primaryColor,
                        side: BorderSide(color: themeService.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeService.primaryColor,
                      ),
                      child: Text(
                        context.t('common.close'),
                        style: TextStyle(color: themeService.onSurfaceColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalData(BuildContext context) {
    final api = geolabApi.ApiService();

    // Generate dynamic explanation
    final dynamicExplanation = XaiExplanationService.generateExplanation(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // 1. Dynamic Text Explanation
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeService.primaryColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.auto_awesome, size: 20, color: themeService.primaryColor),
                   const SizedBox(width: 8),
                   Text(
                    context.t('rockClassification.aiAnalysis'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeService.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dynamicExplanation.replaceAll('**', ''), 
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: themeService.textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // 2. Fetch Data & Display Charts + Image
        FutureBuilder<Map<String, dynamic>>(
          future: () {
            // Determine which image data to use
            final imageFile = state.image;
            final imageBytes = state.imageBytes;
            final imageUrl = state.additionalData != null ? state.additionalData!['image_url'] as String? : null;

            return api.explainPrediction(
              predictedClass: state.rockType,
              confidence: state.confidence,
              imageFile: imageFile, 
              imageBytes: imageBytes,
              imageUrl: imageUrl,
            );
          }(),
          builder: (context, snapshot) {

            
            // Prioritize stored additionalData if available (History)
            var data = state.additionalData;
            // Merge/Overwrite with fresh API response if available
            if (snapshot.hasData && snapshot.data != null) {
              // Creating a merged map, favoring API data
              final freshData = snapshot.data!;
              if (data == null) {
                data = freshData;
              } else {
                data = Map<String, dynamic>.from(data!);
                data!.addAll(freshData);
              }
            }
            
            if (data != null) {

            }

            // Parse Stages
            
            // Parse Stages
            Map<String, double> probs1 = {};
            Map<String, double> probs2 = {};
            Map<String, double> probs3 = {};
            
             // Helper for safe casting
            Map<String, double> safeParseProbs(dynamic input) {
               if (input == null || input is! Map) return {};
               try {
                 return Map<String, double>.from(
                   input.map((key, value) {
                     if (value is num) return MapEntry(key.toString(), value.toDouble());
                     if (value is String) return MapEntry(key.toString(), double.tryParse(value) ?? 0.0);
                     return MapEntry(key.toString(), 0.0);
                   })
                 );
               } catch (e) {
                 return {};
               }
            }
            
            
            if (data != null) {
               if (data!['stage1'] != null && data!['stage1'] is Map) {
                 probs1 = safeParseProbs(data!['stage1']['probabilities']);
               }
               if (data!['stage2'] != null && data!['stage2'] is Map) {
                 probs2 = safeParseProbs(data!['stage2']['probabilities']);
               }
               if (data!['stage3'] != null && data!['stage3'] is Map) {
                 probs3 = safeParseProbs(data!['stage3']['probabilities']);
               }
               
               // Fallback: if no stages found but 'probabilities' exists (Legacy/Flat history)
               if (probs1.isEmpty && probs2.isEmpty && probs3.isEmpty && data!['probabilities'] != null) {
                 probs3 = safeParseProbs(data!['probabilities']);
               }
            }

            return Column(
              children: [
                  if (probs1.isNotEmpty) _buildChartSection(context, context.t('rockClassification.stage1'), probs1),
                  
                  if (data!['stage2'] != null || data!['comparison_stage2'] != null) ...[
                    Text(context.t('rockClassification.stage2'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeService.textColor)),
                    const SizedBox(height: 8),
                    if (data!['comparison_stage2'] != null) 
                      _buildComparisonSection(context, data!['comparison_stage2'], probs2),
                    if (probs2.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 180,
                        child: XaiDistributionChart(
                          probabilities: probs2,
                          themeService: themeService
                        )
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  if (probs3.isNotEmpty) _buildChartSection(context, context.t('rockClassification.stage3'), probs3),

                  if (GradCamView.isAvailable(data!['gradcam']))
                    GradCamView(
                      gradcam: Map<String, dynamic>.from(data!['gradcam'] as Map),
                      themeService: themeService,
                    ),
                ],
              );
          },
        ),
      ],
    );
  }
  
   Widget _buildChartSection(BuildContext context, String title, Map<String, double> probs) {
      if (probs.isEmpty) return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeService.textColor)),
           const SizedBox(height: 8),
           SizedBox(
             height: 180, // Slightly smaller per chart
             child: XaiDistributionChart(
               probabilities: probs,
               themeService: themeService
             )
           ),
           const SizedBox(height: 24),
        ],
      );
  }

  Widget _buildComparisonSection(BuildContext context, dynamic comparisonData, Map<String, double> primaryProbs) {
    if (comparisonData == null || comparisonData is! Map) return const SizedBox.shrink();
    
    final resnet = comparisonData['resnet_model'];
    final dtree = comparisonData['decision_tree_model'];

    // Get primary model's top prediction if available
    String primaryPred = 'N/A';
    double primaryConf = 0.0;
    if (primaryProbs.isNotEmpty) {
      final sorted = primaryProbs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      primaryPred = sorted.first.key;
      primaryConf = sorted.first.value;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Hierarchical Model
            if (primaryProbs.isNotEmpty) ...[
              _buildComparisonRow(
                context,
                'Hierarchical',
                primaryPred,
                primaryConf,
              ),
              const SizedBox(height: 8),
              Divider(color: themeService.textColor.withOpacity(0.05)),
              const SizedBox(height: 8),
            ],
            _buildComparisonRow(
              context,
              'ResNet50',
              resnet?['prediction'] ?? 'N/A',
              (resnet?['confidence'] as num?)?.toDouble() ?? 0.0,
            ),
            const SizedBox(height: 8),
            Divider(color: themeService.textColor.withOpacity(0.05)),
            const SizedBox(height: 8),
            _buildComparisonRow(
              context,
              'Decision Tree',
              dtree?['prediction'] ?? 'N/A',
              (dtree?['confidence'] as num?)?.toDouble() ?? 0.0,
            ),
          ],
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String modelName, String prediction, double confidence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              modelName,
              style: TextStyle(
                fontSize: 10,
                color: themeService.textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: themeService.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 4,
                  width: constraints.maxWidth * confidence,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          prediction.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: themeService.textColor,
          ),
        ),
      ],
    );
  }

  Future<void> _shareResult(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
      );

      final pdfBytes = await PdfGenerationService.generateReport(state);
      final fileName = 'GeoLab_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      await PdfHandler.handlePdf(pdfBytes, fileName);
      
      } catch (e, stack) {
        print("Error sharing PDF: $e");
        print(stack);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getFriendlyErrorMessage(e))),
        );
      }
  }
}
