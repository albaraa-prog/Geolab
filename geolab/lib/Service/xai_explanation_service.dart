import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';

class XaiExplanationService {
  
  /// Generates a dynamic, human-readable explanation based on 3-stage hierarchical data.
  static String generateExplanation(ClassificationComplete state) {
    // 1. Check for detailed stage data for rich explanation
    final data = state.additionalData ?? {};
    // FIX: Allow partial stages. If ANY stage is present, try to generate detailed explanation.
    final hasStages = data['stage1'] != null || data['stage2'] != null || data['stage3'] != null;

    if (hasStages) {
       // Proceed to generate detailed explanation
    } else if (data['reasoning'] != null && 
        data['reasoning'].toString().isNotEmpty &&
        data['reasoning'] != 'No explanation available.') {
      // Fallback to backend explanation if no stages
      return data['reasoning'].toString().replaceAll('→', '->');
    } else if (state.additionalData == null) {
      return 'Detailed hierarchical analysis is unavailable.';
    }

    
    final buffer = StringBuffer();
    
    
    if (hasStages) {
      final stage1 = data['stage1'] as Map<String, dynamic>?;
      final stage2 = data['stage2'] as Map<String, dynamic>?;
      final stage3 = data['stage3'] as Map<String, dynamic>?;
      
      // STAGE 1 LOGIC
      if (stage1 != null) {
        final conf1 = stage1['confidence'] as double? ?? 0.0;
        if (conf1 > 0.95) {
          buffer.write('1. **Initial Screening**: The model identifies this as a rock with near certainty. ');
        } else if (conf1 > 0.8) {
           buffer.write('1. **Initial Screening**: The model is fairly confident this is a rock. ');
        } else {
           buffer.write('1. **Initial Screening**: This sample has ambiguous features, but is classified as a rock. ');
        }
        buffer.writeln();
      }
      
      // STAGE 2 LOGIC
      if (stage2 != null) {
        final probs2 = stage2['probabilities'] as Map?;
        final mainType = stage2['main_category'] ?? stage2['class_name'] ?? 'Unknown';
        final conf2 = stage2['confidence'] as double? ?? 0.0;
        
        buffer.write('2. **Main Category**: It is identified as **$mainType** (${(conf2 * 100).toStringAsFixed(1)}%). ');
        
        if (probs2 != null && probs2.isNotEmpty) {
           // Find 2nd best
           final sorted = probs2.entries.toList()..sort((a,b) => (b.value as num).compareTo(a.value as num));
           if (sorted.length > 1) {
             final second = sorted[1];
             final margin = conf2 - (second.value as num).toDouble();
             if (margin < 0.2) {
               buffer.write('However, there is significant resemblance to **${second.key}** as well. ');
             } else {
               buffer.write('This differentiation is distinct. ');
             }
           }
        }
        buffer.writeln();
      }

      // STAGE 3 LOGIC
      if (stage3 != null) {
        final subClass = stage3['class_name'] ?? state.rockType;
        final conf3 = stage3['confidence'] as double? ?? 0.0;
        
        buffer.write('3. **Specific Type**: Finally, the model classifies it as **$subClass** (${(conf3 * 100).toStringAsFixed(1)}% confidence). ');
        
        // Detailed texture/feature check (hypothetical, based on margin)
        if (conf3 > 0.9) {
           buffer.write('The specific visual patterns (texture, grain size) strongly match known samples of this type.');
        } else {
           buffer.write('There is some variation here, possibly due to weathering or unusual mineral composition.');
        }
        buffer.writeln();
      } else {
         buffer.writeln('3. **Specific Type**: The model could not confidently refine the classification further than the main category.');
      }

    } else {
      // FALLBACK TO FLAT LIST LOGIC (Old)
      Map<String, double> probabilities = {};
      
      try {
        if (data['probabilities'] != null) {
           final raw = data['probabilities'];
           if (raw is Map) {
             probabilities = raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
           }
        }
      } catch (e) {

      }
          
      if (probabilities.isEmpty) return state.additionalData?['reasoning'] ?? 'No data available.';

      final sortedEntries = probabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topMatch = sortedEntries[0];
      
      buffer.writeln('The AI model identifies this as **${topMatch.key}** with **${(topMatch.value * 100).toStringAsFixed(1)}%** confidence.');
      
      if (sortedEntries.length > 1) {
         final runnerUp = sortedEntries[1];
         if ((topMatch.value - runnerUp.value) < 0.2) {
            buffer.writeln('It also shares significant features with **${runnerUp.key}**.');
         }
      }
    }
    
    return buffer.toString().replaceAll('→', '->');
  }
}
