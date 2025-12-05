// Conditional import for web
import 'FileDropZone_stub.dart'
    if (dart.library.html) 'FileDropZone_web.dart' as file_drop_zone;

import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Web-specific file drop zone widget with drag-and-drop support
/// This is a wrapper that delegates to the platform-specific implementation
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
    return file_drop_zone.FileDropZone(
      onFileSelected: onFileSelected,
      width: width,
      height: height,
    );
  }
}
