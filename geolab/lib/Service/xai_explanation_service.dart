import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/features/Settings/components/localization.dart';

class XaiExplanationService {
  
  /// Generates a dynamic, human-readable explanation based on 3-stage hierarchical data.
  /// Generates a dynamic, human-readable explanation based on 3-stage hierarchical data.
  static String generateExplanation(ClassificationComplete state, {Map<String, dynamic>? translations}) {
    // 1. Check for detailed stage data for rich explanation
    final data = state.additionalData ?? {};
    final loc = LocalizationService.instance;
    
    // Convert translation map navigation to helper
    String t(String key) {
       if (translations != null) {
          final parts = key.split('.');
          dynamic value = translations;
          for (var part in parts) {
            if (value is Map && value.containsKey(part)) {
               value = value[part];
            } else {
               return key;
            }
          }
          return value.toString();
       }
       return loc.translate(key);
    }
    
    String tParams(String key, Map<String, String> params) {
       String val = t(key);
       params.forEach((k, v) => val = val.replaceAll('{$k}', v));
       return val;
    }

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
      return t('xai.detailedUnavailable');
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
          buffer.write('${t('xai.initialScreeningHigh')} ');
        } else if (conf1 > 0.8) {
           buffer.write('${t('xai.initialScreeningMedium')} ');
        } else {
           buffer.write('${t('xai.initialScreeningLow')} ');
        }
        buffer.writeln();
      }
      
      // STAGE 2 LOGIC
      if (stage2 != null) {
        final probs2 = stage2['probabilities'] as Map?;
        final mainType = stage2['main_category'] ?? stage2['class_name'] ?? 'Unknown';
        final conf2 = stage2['confidence'] as double? ?? 0.0;
        
        String phase2 = tParams('xai.mainCategory', {
          'type': mainType.toString(),
          'confidence': (conf2 * 100).toStringAsFixed(1)
        });
        buffer.write('$phase2 ');
        
        if (probs2 != null && probs2.isNotEmpty) {
           // Find 2nd best
           final sorted = probs2.entries.toList()..sort((a,b) => (b.value as num).compareTo(a.value as num));
           if (sorted.length > 1) {
             final second = sorted[1];
             final margin = conf2 - (second.value as num).toDouble();
             if (margin < 0.2) {
               String resemblance = tParams('xai.resemblance', {
                 'type': second.key.toString()
               });
               buffer.write('$resemblance ');
             } else {
               buffer.write('${t('xai.distinct')} ');
             }
           }
        }
        buffer.writeln();
      }

      // STAGE 3 LOGIC
      if (stage3 != null) {
        final subClass = stage3['class_name'] ?? state.rockType;
        final conf3 = stage3['confidence'] as double? ?? 0.0;
        
        String phase3 = tParams('xai.specificType', {
            'type': subClass.toString(),
            'confidence': (conf3 * 100).toStringAsFixed(1)
        });
        buffer.write('$phase3 ');
        
        // Detailed texture/feature check (hypothetical, based on margin)
        if (conf3 > 0.9) {
           buffer.write(t('xai.textureMatch'));
        } else {
           buffer.write(t('xai.variation'));
        }
        buffer.writeln();
      } else {
         buffer.writeln(t('xai.unrefined'));
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
          
      if (probabilities.isEmpty) return state.additionalData?['reasoning'] ?? t('xai.detailedUnavailable');

      final sortedEntries = probabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topMatch = sortedEntries[0];
      
      String fallbackId = tParams('xai.fallbackIdentified', {
        'type': topMatch.key.toString(),
        'confidence': (topMatch.value * 100).toStringAsFixed(1)
      });
      buffer.writeln(fallbackId);
      
      if (sortedEntries.length > 1) {
         final runnerUp = sortedEntries[1];
         if ((topMatch.value - runnerUp.value) < 0.2) {
             String fallbackRes = tParams('xai.fallbackResemblance', {
               'type': runnerUp.key.toString()
             });
            buffer.writeln(fallbackRes);
         }
      }
    }
    
    return buffer.toString().replaceAll('→', '->');
  }
}
