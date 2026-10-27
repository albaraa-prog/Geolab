import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/utils/app_localizations.dart';

/// Shows the Grad-CAM heatmap returned by /xai/explain on top of the image
/// the model saw, with a slider to fade the heatmap in and out.
class GradCamView extends StatefulWidget {
  final Map<String, dynamic> gradcam;
  final ThemeService themeService;

  const GradCamView({
    super.key,
    required this.gradcam,
    required this.themeService,
  });

  /// True when the backend response holds a usable Grad-CAM result
  static bool isAvailable(dynamic gradcam) =>
      gradcam is Map && gradcam['image'] is String && gradcam['heatmap'] is String;

  @override
  State<GradCamView> createState() => _GradCamViewState();
}

class _GradCamViewState extends State<GradCamView> {
  double _opacity = 0.5;
  late Uint8List _image;
  late Uint8List _heatmap;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(GradCamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gradcam['heatmap'] != widget.gradcam['heatmap']) {
      _decode();
    }
  }

  void _decode() {
    _image = base64Decode(widget.gradcam['image'] as String);
    _heatmap = base64Decode(widget.gradcam['heatmap'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeService;
    final target = (widget.gradcam['target_class'] ?? '').toString().replaceAll('_', ' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('xai.gradcamTitle'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textColor),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_image, fit: BoxFit.cover, gaplessPlayback: true),
                Opacity(
                  opacity: _opacity,
                  child: Image.memory(_heatmap, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Text(
              context.t('xai.gradcamOpacity'),
              style: TextStyle(fontSize: 12, color: theme.textColor.withOpacity(0.7)),
            ),
            Expanded(
              child: Slider(
                value: _opacity,
                onChanged: (value) => setState(() => _opacity = value),
                activeColor: theme.primaryColor,
              ),
            ),
          ],
        ),
        Text(
          context.t('xai.gradcamCaption', {
            'type': target,
            'stage': '${widget.gradcam['stage'] ?? ''}',
            'method': (widget.gradcam['method'] ?? 'gradcam').toString(),
          }),
          style: TextStyle(fontSize: 12, height: 1.4, color: theme.textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
