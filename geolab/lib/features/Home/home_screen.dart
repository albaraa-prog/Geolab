import 'dart:async';
import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/config/theme_service.dart';
import 'package:geolab/features/Home/components/MyCircleButton.dart';
import 'package:geolab/features/Home/components/MyDrawer.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolab/Service/api_service.dart' as geolabApi;

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

  // Lifecycle state
  bool _isDisposed = false;

  // Theme service
  ThemeService get _themeService => ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeCamera();
    super.dispose();
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
        });
        _classifyImage(image);
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
        setState(() {
          _capturedImageBytes = bytes;
          _capturedImage = null;
        });
        // TODO: Implement web image classification
      } else {
        final imageFile = io.File(image.path);
        setState(() {
          _capturedImage = imageFile;
          _capturedImageBytes = null;
        });
        _classifyImage(imageFile);
      }
    } catch (e) {
      _showErrorMessage('${context.t('camera.error')}: $e');
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
    context.read<RockClassificationBloc>().add(ClassifyRock(imageFile));
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
        backgroundColor: _themeService.isDarkMode ? Colors.black : Colors.grey.shade900,
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
    return Row(
      children: [
        _buildDesktopSidebar(),
        Expanded(child: _buildMobileLayout()),
      ],
    );
  }

  Widget _buildCameraPreview() {
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
      color: _themeService.isDarkMode ? Colors.black : Colors.grey.shade900,
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
                fontSize: 16,
                color: _themeService.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
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
            if (!kIsWeb) _buildFlashButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _themeService.isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(
          HugeIcons.strokeRoundedSidebarRight01,
          color: Colors.white,
          size: ResponsiveLayout.getResponsiveIconSize(
            context,
            mobile: 24,
            tablet: 28,
            desktop: 32,
          ),
        ),
        onPressed: () => _scaffoldKey.currentState!.openDrawer(),
      ),
    );
  }

  Widget _buildFlashButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _themeService.isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(
          _isFlashOn
              ? HugeIcons.strokeRoundedFlash
              : HugeIcons.strokeRoundedFlashOff,
          color: _isFlashOn ? Colors.yellow : Colors.white,
          size: ResponsiveLayout.getResponsiveIconSize(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
        ),
        onPressed: _toggleFlash,
      ),
    );
  }

  Widget _buildCaptureArea() {
    return Expanded(
      child: Center(
        child: Container(
          width: ResponsiveLayout.isWeb(context) ? 400 : 350,
          height: ResponsiveLayout.isWeb(context) ? 400 : 350,
          decoration: BoxDecoration(
            border: Border.all(
              color: _themeService.primaryColor.withOpacity(0.8),
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
          ? Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
          : _capturedImage != null
              ? Image.file(_capturedImage!, fit: BoxFit.cover)
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
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: Text(
              context.t('camera.remove'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: _saveCapturedImage,
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: Text(
              context.t('camera.save'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
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
            if (!kIsWeb)
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
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isTakingPicture
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: _themeService.surfaceColor,
        border: Border(
          right: BorderSide(
            color: _themeService.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Geolab',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _themeService.primaryColor,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: _themeService.primaryColor),
            title: Text('Home', style: TextStyle(color: _themeService.textColor)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.settings, color: _themeService.primaryColor),
            title: Text('Settings', style: TextStyle(color: _themeService.textColor)),
            onTap: () => context.go('/settings'),
          ),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.person, color: _themeService.primaryColor),
            title: Text('Profile', style: TextStyle(color: _themeService.textColor)),
            onTap: () => context.go('/profile'),
          ),
        ],
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
        child: Padding(
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
              Align(
                alignment: RTLUtils.endAlignment(context),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeService.primaryColor,
                  ),
                  child: Text(
                    context.t('common.close'),
                    style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              xaiUrl,
              height: 180,
              fit: BoxFit.cover,
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
                         context.t('rockClassification.generatingExplanation');
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