import 'dart:async';
import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/Service/theme_service.dart';
import 'package:geolab/features/Home/components/MyCircleButton.dart';
import 'package:geolab/features/Home/components/MyDrawer.dart';
import 'package:geolab/features/Home/components/FileDropZone.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolab/Service/api_service.dart' as geolabApi;
import 'package:geolab/Service/network_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keys and Controllers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // Camera related state
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isSwitchingCamera = false;
  bool _isTakingPicture = false;

  // Image state
  io.File? _capturedImage;
  Uint8List? _capturedImageBytes;
  bool _isClassificationComplete = false;

  // Lifecycle state
  bool _isDisposed = false;

  // Network connectivity state
  bool _isConnected = true;
  final NetworkService _networkService = NetworkService();
  Timer? _connectivityTimer;

  // Theme service
  ThemeService get _themeService => ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkConnectivity();
    _startConnectivityTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeCamera();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // NETWORK CONNECTIVITY MANAGEMENT
  // ============================================================================

  Future<void> _checkConnectivity() async {
    try {
      final isConnected = await _networkService.checkConnectivity();
      if (mounted && !_isDisposed) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  void _startConnectivityTimer() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isDisposed) {
        _checkConnectivity();
      } else {
        timer.cancel();
      }
    });
  }

  // ============================================================================
  // CAMERA INITIALIZATION AND MANAGEMENT
  // ============================================================================

  Future<void> _initializeCamera() async {
    try {
      if (kIsWeb) {
        if (mounted && !_isDisposed) setState(() {});
        return;
      }

      await _requestCameraPermissions();
      await _setupCamera();
    } catch (e) {
      _showErrorMessage('${context.t('camera.error')}: $e');
    }
  }

  Future<void> _requestCameraPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      _showErrorMessage(context.t('camera.permissionRequired'));
      return;
    }
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();
    
    if (_cameras == null || _cameras!.isEmpty) {
      _showErrorMessage(context.t('camera.noCamerasFound'));
      return;
    }

    await _createCameraController();
  }

  Future<void> _createCameraController() async {
    await _disposeCamera();

    _controller = CameraController(
      _cameras![_currentCameraIndex],
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller?.initialize();
    if (mounted && !_isDisposed) setState(() {});
  }

  Future<void> _disposeCamera() async {
    if (!kIsWeb && 
        _controller != null && 
        (_controller?.value.isInitialized ?? false)) {
      await _controller?.dispose();
      _controller = null;
    }
  }

  // ============================================================================
  // CAMERA ACTIONS
  // ============================================================================

  Future<void> _captureImage() async {
    if (kIsWeb) {
      await _pickImageFromGallery();
      return;
    }

    if (!_canTakePicture()) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile imageFile = await _controller!.takePicture();
      final io.File image = io.File(imageFile.path);
      
      if (mounted && !_isDisposed) {
        setState(() {
          _capturedImage = image;
          _isTakingPicture = false;
          _isClassificationComplete = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isTakingPicture = false);
        _showErrorMessage('${context.t('camera.error')}: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        _handleWebFileSelected(bytes, image.name);
      } else {
        final imageFile = io.File(image.path);
        setState(() {
          _capturedImage = imageFile;
          _capturedImageBytes = null;
          _isClassificationComplete = false;
        });
      }
    } catch (e) {
      _showErrorMessage('${context.t('camera.error')}: $e');
    }
  }

  void _handleWebFileSelected(Uint8List bytes, String fileName) {
    setState(() {
      _capturedImageBytes = bytes;
      _capturedImage = null;
      _isClassificationComplete = false;
    });
  }

  void _classifyWebImage(Uint8List bytes) {
    try {
      context.read<RockClassificationBloc>().add(ClassifyRockFromBytes(bytes, fileName: 'rock_image.jpg'));
    } catch (e) {
      _showErrorMessage('Error starting classification: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (!_canFlipCamera()) return;

    try {
      _isSwitchingCamera = true;
      await _disposeCamera();

      setState(() {
        _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
      });

      await _createCameraController();
      _isSwitchingCamera = false;
    } catch (e) {
      _isSwitchingCamera = false;
      _showErrorMessage('Error switching camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (!_canToggleFlash()) return;

    try {
      await _controller?.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      
      if (mounted && !_isDisposed) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } catch (e) {
      _showErrorMessage('${context.t('camera.error')}: $e');
    }
  }

  // ============================================================================
  // IMAGE MANAGEMENT
  // ============================================================================

  void _classifyImage(io.File imageFile) {
    try {
      context.read<RockClassificationBloc>().add(ClassifyRock(imageFile));
    } catch (e) {
      _showErrorMessage('Error starting classification: $e');
    }
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      if (kIsWeb) {
        await _saveImageWeb(bytes);
      } else {
        await _saveImageMobile(bytes);
      }
    } catch (e) {
      _showErrorMessage('${context.t('camera.saveError')}: $e');
    }
  }

  Future<void> _saveImageWeb(Uint8List bytes) async {
    try {
      const platform = MethodChannel('geolab/download');
      await platform.invokeMethod('downloadImage', {
        'bytes': bytes,
        'filename': 'rock_image.jpg',
      });
    } catch (e) {
      _showErrorMessage('Download not supported on this platform');
    }
  }

  Future<void> _saveImageMobile(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/rock_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageFile = io.File(imagePath);
    await imageFile.writeAsBytes(bytes);
    
    _showSuccessMessage(context.t('camera.saved'));
  }

  void _clearCapturedImage() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _isClassificationComplete = false;
    });
  }

  void _saveCapturedImage() {
    if (kIsWeb && _capturedImageBytes != null) {
      _saveImage(_capturedImageBytes!);
    } else if (_capturedImage != null) {
      _capturedImage!.readAsBytes().then(_saveImage);
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  bool _canTakePicture() {
    return !_isDisposed &&
           !_isSwitchingCamera &&
           _controller != null &&
           (_controller?.value.isInitialized ?? false);
  }

  bool _canFlipCamera() {
    return !_isDisposed &&
           !kIsWeb &&
           _cameras != null &&
           _cameras!.length >= 2 &&
           !_isSwitchingCamera;
  }

  bool _canToggleFlash() {
    return !_isDisposed &&
           !_isSwitchingCamera &&
           !kIsWeb &&
           _controller != null &&
           (_controller?.value.isInitialized ?? false);
  }

  bool get _hasValidCamera {
    return _cameras != null &&
           _cameras!.isNotEmpty &&
           !kIsWeb &&
           !_isDisposed &&
           !_isSwitchingCamera;
  }

  bool get _isCameraReady {
    return _controller != null &&
           !_isDisposed &&
           !_isSwitchingCamera &&
           _controller!.value.isInitialized;
  }

  bool get _hasImage {
    return _capturedImage != null || _capturedImageBytes != null;
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _themeService.isDarkMode ? Colors.red.shade800 : Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _themeService.isDarkMode ? Colors.green.shade800 : Colors.green,
        ),
      );
    }
  }

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<RockClassificationBloc, RockClassificationState>(
      listener: _handleClassificationState,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MyDrawer(),
        backgroundColor: _themeService.backgroundColor,
        body: ResponsiveBuilder(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }

  void _handleClassificationState(BuildContext context, RockClassificationState state) {
    if (state is ClassificationComplete) {
      setState(() {
        _isClassificationComplete = true;
      });
      _showClassificationResult(state);
    } else if (state is ClassificationError) {
      _showClassificationError(state);
    }
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        _buildCameraPreview(),
        _buildOverlay(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    // Use mobile layout with drawer (same as mobile/tablet)
    return _buildMobileLayout();
  }

  Widget _buildCameraPreview() {
    // On web, show file drop zone or image preview
    if (kIsWeb) {
      // If we have an image, show preview instead of drop zone
      if (_hasImage) {
        return Container(
          color: _themeService.backgroundColor,
          child: Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _themeService.primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _capturedImageBytes != null
                    ? Image.memory(_capturedImageBytes!, fit: BoxFit.contain)
                    : _capturedImage != null
                        ? Image.file(_capturedImage!, fit: BoxFit.contain)
                        : const SizedBox(),
              ),
            ),
          ),
        );
      }
      
      // Show drop zone when no image
      return Container(
        color: _themeService.backgroundColor,
        child: Center(
          child: FileDropZone(
            width: 400,
            height: 400,
            onFileSelected: _handleWebFileSelected,
          ),
        ),
      );
    }

    if (!_hasValidCamera) {
      return _buildLoadingView();
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _isCameraReady &&
            !snapshot.hasError) {
          return SizedBox.expand(
            child: CameraPreview(_controller!),
          );
        }
        return _buildLoadingView();
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: _themeService.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _themeService.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _isSwitchingCamera
                  ? 'Switching camera...'
                  : context.t('common.loading'),
              style: TextStyle(
                color: _themeService.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    // On web, show simplified overlay
    if (kIsWeb) {
      return Positioned.fill(
        child: Column(
          children: [
            _buildTopBar(),
            // Spacer to center content
            const Spacer(),
            // Show image actions (remove/save) when image is selected
            if (_hasImage) _buildImageActions(),
            // Bottom controls are hidden on web (returns SizedBox.shrink)
            _buildBottomControls(),
            // Extra spacer at bottom for better centering
            const Spacer(),
          ],
        ),
      );
    }
    
    // Mobile/tablet layout with capture area
    return Positioned.fill(
      child: Column(
        children: [
          _buildTopBar(),
          _buildCaptureArea(),
          if (_hasImage) _buildImageActions(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSidebarButton(),
            Row(
              children: [
                //_buildConnectivityIndicator(),
                const SizedBox(width: 8),
                if (!kIsWeb) _buildFlashButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _themeService.surfaceColor.withOpacity(0.2),
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            onTap: () => _scaffoldKey.currentState!.openDrawer(),
            child: Center(
              child: Icon(
                HugeIcons.strokeRoundedSidebarRight01,
                color: _themeService.onSurfaceColor,
                size: ResponsiveLayout.getResponsiveIconSize(
                  context,
                  mobile: 32,
                  tablet: 36,
                  desktop: 40,
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildFlashButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _themeService.surfaceColor.withOpacity(0.2),
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            onTap: _toggleFlash,
            child: Center(
              child: Icon(
                _isFlashOn ? HugeIcons.strokeRoundedFlash : HugeIcons.strokeRoundedFlashOff,
                color: _isFlashOn ? Colors.yellow : _themeService.onSurfaceColor,
                size: ResponsiveLayout.getResponsiveIconSize(
                  context,
                  mobile: 28,
                  tablet: 32,
                  desktop: 36,
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildCaptureArea() {
    // On web, this is not used (FileDropZone handles its own styling)
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    
    return Expanded(
      child: Center(
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(
              color: _themeService.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _buildCaptureAreaContent(),
        ),
      ),
    );
  }

  Widget _buildCaptureAreaContent() {
    if (_hasImage) {
      return _buildImagePreview();
    }

    if (_isTakingPicture) {
      return Center(
        child: CircularProgressIndicator(
          color: _themeService.primaryColor,
        ),
      );
    }

    return _buildCapturePrompt();
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: kIsWeb && _capturedImageBytes != null
          ? Image.memory(_capturedImageBytes!, fit: BoxFit.contain)
          : _capturedImage != null
              ? Image.file(_capturedImage!, fit: BoxFit.contain)
              : const SizedBox(),
    );
  }

  Widget _buildCapturePrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          HugeIcons.strokeRoundedCameraSmile01,
          color: _themeService.primaryColor.withOpacity(0.8),
          size: ResponsiveLayout.getResponsiveIconSize(
            context,
            mobile: 50,
            tablet: 60,
            desktop: 70,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          kIsWeb
              ? context.t('camera.selectImage')
              : context.t('camera.positionRock'),
          style: TextStyle(
            color: _themeService.textColor.withOpacity(0.8),
            fontSize: ResponsiveLayout.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: _clearCapturedImage,
            icon: Icon(Icons.delete_outline, color: _themeService.onSurfaceColor),
            label: Text(
              context.t('camera.remove'),
              style: TextStyle(color: _themeService.onSurfaceColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 24),
          // Show classify button if not classified yet
          if (!_isClassificationComplete)
            _buildClassifyButton()
          // Show save button only after classification is complete
          else
            TextButton.icon(
              onPressed: _saveCapturedImage,
              icon: Icon(Icons.save_alt, color: _themeService.onSurfaceColor),
              label: Text(
                context.t('camera.save'),
                style: TextStyle(color: _themeService.onSurfaceColor, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassifyButton() {
    return BlocBuilder<RockClassificationBloc, RockClassificationState>(
      builder: (context, state) {
        final isClassifying = state is Classifying;
        
        return ElevatedButton.icon(
          onPressed: isClassifying ? null : _handleClassifyButtonPressed,
          icon: isClassifying
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_themeService.onSurfaceColor),
                  ),
                )
              : Icon(
                  Icons.auto_awesome,
                  color: _themeService.onSurfaceColor,
                  size: 20,
                ),
          label: Text(
            isClassifying ? context.t('rockClassification.classifying') : context.t('rockClassification.classify'),
            style: TextStyle(
              color: _themeService.onSurfaceColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _themeService.primaryColor,
            foregroundColor: _themeService.onSurfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            disabledBackgroundColor: _themeService.primaryColor.withOpacity(0.6),
          ),
        );
      },
    );
  }

  void _handleClassifyButtonPressed() {
    if (kIsWeb && _capturedImageBytes != null) {
      _classifyWebImage(_capturedImageBytes!);
    } else if (_capturedImage != null) {
      _classifyImage(_capturedImage!);
    }
  }

  Widget _buildBottomControls() {
    // On web, hide all controls (FileDropZone handles everything)
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    
    // Mobile/tablet layout with all controls
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            MyCircleButton(
              icon: HugeIcons.strokeRoundedImage01,
              onPressed: _pickImageFromGallery,
            ),
            _buildCaptureButton(),
            MyCircleButton(
              icon: HugeIcons.strokeRoundedCamera01,
              onPressed: _flipCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _themeService.onSurfaceColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: _themeService.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isTakingPicture
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: _themeService.onSurfaceColor,
                  strokeWidth: 3,
                ),
              )
            : Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _themeService.onSurfaceColor,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }


  // ============================================================================
  // MODAL DIALOGS
  // ============================================================================

  void _showClassificationResult(ClassificationComplete state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _themeService.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildResultModal(state),
    );
  }

  void _showClassificationError(ClassificationError state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _themeService.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildErrorModal(state),
    );
  }

  Widget _buildResultModal(ClassificationComplete state) {
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
                  color: _themeService.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${context.t('rockClassification.rockType')}: ${state.rockType}',
                style: TextStyle(
                  fontSize: 18,
                  color: _themeService.textColor,
                ),
              ),
              Text(
                '${context.t('rockClassification.confidence')}: ${(state.confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: _themeService.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (state.additionalData != null) _buildAdditionalData(state),
              const SizedBox(height: 20),
              Align(
                alignment: RTLUtils.endAlignment(context),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeService.primaryColor,
                  ),
                  child: Text(
                    context.t('common.close'),
                    style: TextStyle(color: _themeService.onSurfaceColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorModal(ClassificationError state) {
    return ResponsiveContainer(
      maxWidth: ResponsiveLayout.isWeb(context) ? 500 : null,
      child: RTLWrapper(
        child: Padding(
          padding: ResponsiveLayout.getResponsivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('rockClassification.error'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _themeService.isDarkMode ? Colors.red.shade300 : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: TextStyle(
                  fontSize: 16,
                  color: _themeService.textColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeService.primaryColor,
                ),
                child: Text(
                  context.t('common.close'),
                  style: TextStyle(color: _themeService.onSurfaceColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalData(ClassificationComplete state) {
    final data = state.additionalData!;
    final xai = data['xai_visualization'] as String?;
    final api = geolabApi.ApiService();
    final xaiUrl = xai != null ? api.buildFileUrl(xai) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (xaiUrl != null)
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: _themeService.dividerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: _themeService.textColor.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'XAI visualization unavailable',
                            style: TextStyle(
                              color: _themeService.textColor.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 12),
        FutureBuilder<String>(
          future: api.explainPrediction(
            predictedClass: state.rockType,
            confidence: state.confidence,
          ),
          builder: (context, snapshot) {
            final text = snapshot.data ?? 
                         (context.t('rockClassification.generatingExplanation') != 'rockClassification.generatingExplanation'
                          ? context.t('rockClassification.generatingExplanation')
                          : 'Generating explanation...');
            return Text(
              text,
              style: TextStyle(color: _themeService.textColor.withOpacity(0.8)),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}