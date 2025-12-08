import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/Service/xai_explanation_service.dart';

class PdfGenerationService {
  
  static Future<Uint8List> generateReport(ClassificationComplete state) async {
    final pdf = pw.Document();

    // Prepare Data
    final explanation = XaiExplanationService.generateExplanation(state);
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

      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GeoLab Analysis Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
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
                        pw.Text('Final Classification', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(state.rockType, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.SizedBox(height: 8),
                        pw.Text('Global Confidence: ${(state.confidence * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('This document details the hierarchical analysis performed by the GeoLab AI system.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // AI Explanation Narrative
            pw.Text('AI Analysis Narrative', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Text(explanation.replaceAll('**', ''), style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.6)),
            
            pw.SizedBox(height: 24),
            
            // 3-Stage Charts
            if (probs1.isNotEmpty) _buildPdfChart(context, 'Stage 1: Initial Screening', probs1),
            if (probs2.isNotEmpty) _buildPdfChart(context, 'Stage 2: Main Rock Type', probs2),
            if (probs3.isNotEmpty) _buildPdfChart(context, 'Stage 3: Subclass Identification', probs3),
            
            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 20),
              leading: pw.Text('Generated by GeoLab App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfChart(pw.Context context, String title, Map<String, double> probs) {
    // Sort
    final sorted = probs.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final display = sorted.take(6).toList(); // Max 6 items per chart to keep it short

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
        pw.SizedBox(height: 6),
        
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
}
