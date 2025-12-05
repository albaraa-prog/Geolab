import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
/// This widget does nothing on mobile/desktop platforms
class FileDropZone extends StatelessWidget {
  final Function(Uint8List bytes, String fileName)? onFileSelected;
  final double? width;
  final double? height;

  const FileDropZone({
    super.key,
    this.onFileSelected,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

