import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/Service/xai_explanation_service.dart';
import 'package:geolab/features/Settings/components/localization.dart';



class PdfGenerationService {
  
  static Future<Uint8List> generateReport(ClassificationComplete state) async {
    try {
      final pdf = pw.Document();
      
      // 1. Force Load English Translations
      Map<String, dynamic> enTranslations = {};
      try {
         final String jsonString = await rootBundle.loadString('assets/translations/en.json');
         enTranslations = json.decode(jsonString);
      } catch (e) {
         print("Error loading en.json: $e");
         // Fallback? If we can't load English, we might be in trouble, but let's proceed empty.
      }
      
      // Helper for English translation
      String t(String key) {
          final parts = key.split('.');
          dynamic value = enTranslations;
          for (var part in parts) {
            if (value is Map && value.containsKey(part)) {
               value = value[part];
            } else {
               return key;
            }
          }
          return value.toString();
      }

      // Prepare Data (Force English)
      final explanation = XaiExplanationService.generateExplanation(state, translations: enTranslations);
      final data = state.additionalData ?? {};
      
      // Parse Stages
      Map<String, double> probs1 = {};
      Map<String, double> probs2 = {};
      Map<String, double> probs3 = {};
      
      Map<String, double> safeParseProbs(dynamic input) {
        if (input == null || input is! Map) return {};
        return Map<String, double>.from(
          input.map((key, value) => MapEntry(key.toString(), (value as num).toDouble()))
        );
      }

      if (data['stage1'] != null) {
        probs1 = safeParseProbs(data['stage1']['probabilities']);
      }
      if (data['stage2'] != null) {
        probs2 = safeParseProbs(data['stage2']['probabilities']);
      }
      if (data['stage3'] != null) {
        probs3 = safeParseProbs(data['stage3']['probabilities']);
      }
      
      // Fallback logic
      if (probs1.isEmpty && probs2.isEmpty && probs3.isEmpty && data['probabilities'] != null) {
         probs3 = Map<String, double>.from(data['probabilities']);
      }

      // Handle Image
      pw.MemoryImage? pdfImage;
      if (state.imageBytes != null && state.imageBytes!.isNotEmpty) {
        pdfImage = pw.MemoryImage(state.imageBytes!);
      } else if (state.image != null) {
        try {
          final bytes = await state.image!.readAsBytes();
          pdfImage = pw.MemoryImage(bytes);
        } catch (e) {
             print("Error loading image for PDF: $e");
        }
      }
      
      // No custom font loaded - using default (English/Latin support)
      pw.ThemeData? theme;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr, // Force LTR
          theme: theme,
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(t('pdf.reportTitle'), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(DateTime.now().toString().split('.')[0], style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Main Summary Block
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                     if (pdfImage != null)
                      pw.Container(
                        width: 120,
                        height: 120,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(8),
                          image: pw.DecorationImage(image: pdfImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    if (pdfImage != null) pw.SizedBox(width: 16),
                    
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(t('pdf.finalClassification'), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(state.rockType, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          pw.SizedBox(height: 8),
                          pw.Text('${t('pdf.globalConfidence')}: ${(state.confidence * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 8),
                          pw.Text(t('pdf.intro'), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // AI Explanation Narrative
              pw.Text(t('pdf.aiAnalysisNarrative'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              
              pw.Text(explanation.replaceAll('**', ''), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.6)),
              
              pw.SizedBox(height: 24),
              
              // 3-Stage Charts
              if (probs1.isNotEmpty) _buildPdfChart(context, t('pdf.stage1'), probs1),
              
              // Stage 2 Group (Comparison + Distribution)
              if (probs2.isNotEmpty || data['comparison_stage2'] != null) ...[
                pw.Text(t('pdf.stage2'), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                pw.SizedBox(height: 10),
                if (data['comparison_stage2'] != null) 
                  _buildPdfComparisonSection(context, '', data['comparison_stage2'], probs2),
                if (probs2.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _buildPdfChart(context, '', probs2, isSubChart: true),
                ],
              ],

              if (probs3.isNotEmpty) _buildPdfChart(context, t('pdf.stage3'), probs3),
              
              pw.Footer(
                margin: const pw.EdgeInsets.only(top: 20),
                leading: pw.Text(t('pdf.generatedBy'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e, stack) {
      print("CRITICAL ERROR IN PDF GENERATION: $e");
      print(stack);
      rethrow;
    }
  }
  


  static pw.Widget _buildPdfChart(pw.Context context, String title, Map<String, double> probs, {bool isSubChart = false}) {
    // Sort
    final sorted = probs.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final display = sorted.take(6).toList(); // Max 6 items per chart to keep it short

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 6),
        ],
        
        // Bar Chart via Table
        pw.Table(
           children: display.map((e) {
             return pw.TableRow(
               children: [
                 pw.Container(
                   padding: const pw.EdgeInsets.symmetric(vertical: 2),
                   width: 120,
                   child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                 ),
                 pw.Expanded(
                   child: pw.Stack(
                     alignment: pw.Alignment.centerLeft,
                     children: [
                       // Background rail
                       pw.Container(height: 8, color: PdfColors.grey200),
                       // Foreground bar
                       pw.Container(
                         height: 8, 
                         width: 250 * e.value, // Scaling factor
                         color: e.value > 0.8 ? PdfColors.green500 : (e.value > 0.4 ? PdfColors.blue500 : PdfColors.orange400),
                       ),
                     ]
                   )
                 ),
                 pw.Container(
                   width: 40,
                   alignment: pw.Alignment.centerRight,
                   child: pw.Text('${(e.value * 100).toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))
                 ),
               ]
             );
           }).toList(),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildPdfComparisonSection(pw.Context context, String title, dynamic comparisonData, Map<String, double> primaryProbs) {
    if (comparisonData == null || comparisonData is! Map) return pw.SizedBox.shrink();

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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 10),
        ],
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40),
          child: pw.Column(
            children: [
                if (primaryProbs.isNotEmpty) ...[
                  _buildPdfComparisonRow('Hierarchical', primaryPred, primaryConf),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 8),
                ],
                _buildPdfComparisonRow('ResNet50', resnet?['prediction'], (resnet?['confidence'] as num?)?.toDouble() ?? 0.0),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                pw.SizedBox(height: 8),
              _buildPdfComparisonRow('Decision Tree', dtree?['prediction'], (dtree?['confidence'] as num?)?.toDouble() ?? 0.0),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildPdfComparisonRow(String model, String? prediction, double confidence) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(model, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
            pw.Text('${(confidence * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          width: 380, // Consistent fixed width for the chart area in PDF
          child: pw.Stack(
            alignment: pw.Alignment.centerLeft,
            children: [
              pw.Container(height: 4, width: 380, color: PdfColors.grey200),
              pw.Container(
                height: 4, 
                width: 380 * confidence, 
                color: PdfColors.blue700
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text((prediction ?? 'N/A').replaceAll('_', ' ').toUpperCase(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
      ],
    );
  }
}
