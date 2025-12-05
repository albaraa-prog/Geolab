import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:hugeicons/hugeicons.dart';

/// Web-specific file drop zone widget with drag-and-drop support
class FileDropZone extends StatefulWidget {
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
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;
  bool _isProcessing = false;
  final ThemeService _themeService = ThemeService.instance;
  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dropSub;
  StreamSubscription<html.MouseEvent>? _dragEnterSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;

  @override
  void initState() {
    super.initState();
    // Set up document-level drag-and-drop listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDragAndDrop();
    });
  }

  @override
  void dispose() {
    _dragOverSub?.cancel();
    _dropSub?.cancel();
    _dragEnterSub?.cancel();
    _dragLeaveSub?.cancel();
    super.dispose();
  }

  void _setupDragAndDrop() {
    final body = html.document.body;
    if (body == null) return;
    
    // Prevent default drag behavior to allow drops
    _dragOverSub = body.onDragOver.listen((e) {
      e.preventDefault();
      e.stopPropagation();
    });

    // Handle file drop
    _dropSub = body.onDrop.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      
      // Access dataTransfer from the event
      final dataTransfer = (e as dynamic).dataTransfer as html.DataTransfer?;
      final files = dataTransfer?.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        _handleFile(file);
      }
      
      if (mounted) {
        setState(() => _isDragging = false);
      }
    });

    // Handle drag enter
    _dragEnterSub = body.onDragEnter.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      if (mounted) {
        setState(() => _isDragging = true);
      }
    });

    // Handle drag leave
    _dragLeaveSub = body.onDragLeave.listen((e) {
      e.preventDefault();
      e.stopPropagation();
      // Debounce to avoid flickering when moving between child elements
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isDragging = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing ? null : _openFilePicker,
      child: MouseRegion(
        cursor: _isProcessing ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Container(
          width: widget.width ?? 400,
          height: widget.height ?? 400,
          decoration: BoxDecoration(
            color: _isDragging
                ? _themeService.primaryColor.withOpacity(0.1)
                : _themeService.surfaceColor,
            border: Border.all(
              color: _isDragging
                  ? _themeService.primaryColor
                  : _themeService.primaryColor.withOpacity(0.5),
              width: _isDragging ? 3 : 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: _themeService.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: _isProcessing
              ? _buildProcessingView()
              : _buildDropZoneContent(),
        ),
      ),
    );
  }

  Widget _buildDropZoneContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isDragging
              ? HugeIcons.strokeRoundedUpload01
              : HugeIcons.strokeRoundedImage01,
          color: _isDragging
              ? _themeService.primaryColor
              : _themeService.primaryColor.withOpacity(0.8),
          size: 80,
        ),
        const SizedBox(height: 24),
        Text(
          context.t('camera.dragDropTitle'),
          style: TextStyle(
            color: _themeService.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.t('camera.dragDropSubtitle'),
          style: TextStyle(
            color: _themeService.textColor.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.t('camera.dragDropDescription'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _themeService.textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _openFilePicker,
          icon: const Icon(Icons.folder_open),
          label: Text(context.t('camera.browseFiles')),
          style: ElevatedButton.styleFrom(
            backgroundColor: _themeService.primaryColor,
            foregroundColor: _themeService.onSurfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Supported formats: JPG, PNG, WEBP',
          style: TextStyle(
            color: _themeService.textColor.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: _themeService.primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          context.t('common.loading'),
          style: TextStyle(
            color: _themeService.textColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _openFilePicker() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        _handleFile(files[0]);
      }
    });

    input.click();
  }

  Future<void> _handleFile(html.File file) async {
    // Validate file type
    if (!_isValidImageFile(file)) {
      _showError(context.t('camera.unsupportedFile'));
      return;
    }

    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      _showError(context.t('camera.fileTooLarge'));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();

      reader.onLoadEnd.listen((e) {
        if (reader.result != null) {
          final bytes = reader.result as Uint8List;
          completer.complete(bytes);
        } else {
          completer.completeError('Failed to read file');
        }
      });

      reader.onError.listen((e) {
        completer.completeError('Error reading file: $e');
      });

      reader.readAsArrayBuffer(file);

      final bytes = await completer.future;

      if (mounted) {
        widget.onFileSelected?.call(bytes, file.name);
      }
    } catch (e) {
      if (mounted) {
        _showError('${context.t('camera.error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  bool _isValidImageFile(html.File file) {
    final extension = file.name.split('.').last.toLowerCase();
    final validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
    return validExtensions.contains(extension);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _themeService.isDarkMode ? Colors.red.shade800 : Colors.red,
      ),
    );
  }
}

