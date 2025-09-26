import 'dart:async';
import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0;
  io.File? _capturedImage;
  Uint8List? _capturedImageBytes;
  bool _isTakingPicture = false;
  bool _isDisposed = false;

  // NEW: Track flash state
  bool _isFlashOn = false;

  // NEW: Track camera switching state
  bool _isSwitchingCamera = false;

  Future<void> _initializeCamera() async {
    try {
      // Skip camera initialization on web
      if (kIsWeb) {
        if (mounted && !_isDisposed) setState(() {});
        return;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.storage,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('camera.permissionRequired'))),
          );
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('camera.noCamerasFound'))),
          );
        }
        return;
      }

      // Dispose existing controller if any
      if (_controller != null) {
        await _controller?.dispose();
        _controller = null;
      }

      _controller = CameraController(
        cameras![_currentCameraIndex],
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller?.initialize();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
        );
      }
    }
  }

  void _classifyImage(io.File imageFile) {
    context.read<RockClassificationBloc>().add(ClassifyRock(imageFile));
  }

  Future<void> _captureImage() async {
    if (kIsWeb) {
      // On web, use image picker instead of camera
      await _pickImageFromGallery();
      return;
    }

    if (_isDisposed ||
        _isSwitchingCamera ||
        _controller == null ||
        !(_controller?.value.isInitialized ?? false)) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

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
        setState(() {
          _isTakingPicture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
        );
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

      if (image != null) {
        if (kIsWeb) {
          // On web, store the bytes directly
          final bytes = await image.readAsBytes();
          setState(() {
            _capturedImageBytes = bytes;
            _capturedImage = null;
          });
          // For web, we need to handle classification differently
          // TODO: Implement web image classification
        } else {
          setState(() {
            _capturedImage = io.File(image.path);
            _capturedImageBytes = null;
          });
          _classifyImage(_capturedImage!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
        );
      }
    }
  }

  void _flipCamera() async {
    if (_isDisposed ||
        kIsWeb ||
        cameras == null ||
        cameras!.length < 2 ||
        _isSwitchingCamera) {
      return;
    }

    try {
      _isSwitchingCamera = true;

      // Dispose current controller safely
      if (_controller != null) {
        await _controller?.dispose();
        _controller = null;
      }

      // Update camera index
      setState(() {
        _currentCameraIndex = (_currentCameraIndex + 1) % cameras!.length;
      });

      // Create new controller
      _controller = CameraController(
        cameras![_currentCameraIndex],
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller?.initialize();

      if (mounted && !_isDisposed) {
        setState(() {});
      }

      _isSwitchingCamera = false;
    } catch (e) {
      _isSwitchingCamera = false;
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: $e')),
        );
      }
    }
  }

  void _toggleFlash() async {
    if (_isDisposed ||
        _isSwitchingCamera ||
        kIsWeb ||
        _controller == null ||
        !(_controller?.value.isInitialized ?? false)) {
      return;
    }

    try {
      await _controller?.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
        );
      }
    }
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      if (kIsWeb) {
        // On web, use platform channel to trigger download
        try {
          const platform = MethodChannel('geolab/download');
          await platform.invokeMethod('downloadImage', {
            'bytes': bytes,
            'filename': 'rock_image.jpg',
          });
        } catch (e) {
          // Fallback: show message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Download not supported on this platform')),
            );
          }
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/rock_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageFile = io.File(imagePath);
        await imageFile.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('camera.saved'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.saveError')}: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (!kIsWeb &&
        _controller != null &&
        (_controller?.value.isInitialized ?? false)) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RockClassificationBloc, RockClassificationState>(
      listener: (context, state) {
        if (state is ClassificationComplete) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
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
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 12,
                                tablet: 16,
                                desktop: 20)),
                        Text(
                          '${context.t('rockClassification.rockType')}: ${state.rockType}',
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                          ),
                        ),
                        Text(
                          '${context.t('rockClassification.confidence')}: ${(state.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28)),
                        if (state.additionalData != null)
                          Builder(builder: (context) {
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
                                    child: Image.network(xaiUrl, height: 180, fit: BoxFit.cover),
                                  ),
                                const SizedBox(height: 12),
                                FutureBuilder<String>(
                                  future: api.explainPrediction(
                                    predictedClass: state.rockType,
                                    confidence: state.confidence,
                                  ),
                                  builder: (context, snap) {
                                    final text = snap.data ?? context.t('rockClassification.generatingExplanation');
                                    return Text(text, style: const TextStyle(color: Colors.black87));
                                  },
                                ),
                              ],
                            );
                          }),
                        Align(
                          alignment: RTLUtils.endAlignment(context),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.t('common.close')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else if (state is ClassificationError) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
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
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 12,
                                tablet: 16,
                                desktop: 20)),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 20,
                                tablet: 24,
                                desktop: 28)),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.t('common.close')),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MyDrawer(),
        body: ResponsiveBuilder(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        if (cameras != null &&
            cameras!.isNotEmpty &&
            !kIsWeb &&
            !_isDisposed &&
            !_isSwitchingCamera)
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  _controller != null &&
                  !_isDisposed &&
                  !_isSwitchingCamera &&
                  _controller!.value.isInitialized &&
                  !snapshot.hasError) {
                return SizedBox.expand(
                  child: CameraPreview(_controller!),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isSwitchingCamera
                          ? 'Switching camera...'
                          : context.t('common.loading'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 19),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sidebar button (left)
                      IconButton(
                        icon: Icon(
                          HugeIcons.strokeRoundedSidebarRight01,
                          color: Colors.white,
                          size: ResponsiveLayout.getResponsiveIconSize(context,
                              mobile: 45, tablet: 50, desktop: 55),
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState!.openDrawer(),
                      ),

                      // Flash toggle button (right) - only show on mobile
                      if (!kIsWeb)
                        IconButton(
                          icon: Icon(
                            _isFlashOn
                                ? HugeIcons.strokeRoundedFlash
                                : HugeIcons.strokeRoundedFlashOff,
                            color: Colors.white,
                            size: ResponsiveLayout.getResponsiveIconSize(
                                context,
                                mobile: 40,
                                tablet: 45,
                                desktop: 50),
                          ),
                          onPressed: _toggleFlash,
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: ResponsiveLayout.isWeb(context) ? 400 : 350,
                    height: ResponsiveLayout.isWeb(context) ? 400 : 350,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _capturedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb
                                ? Image.memory(
                                    _capturedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _capturedImage!,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : _isTakingPicture
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedCameraSmile01,
                                    color: Colors.white.withOpacity(0.8),
                                    size:
                                        ResponsiveLayout.getResponsiveIconSize(
                                            context,
                                            mobile: 50,
                                            tablet: 60,
                                            desktop: 70),
                                  ),
                                  SizedBox(
                                      height:
                                          ResponsiveLayout.getResponsiveSpacing(
                                              context,
                                              mobile: 16,
                                              tablet: 20,
                                              desktop: 24)),
                                  Text(
                                    kIsWeb
                                        ? context.t('camera.selectImage')
                                        : context.t('camera.positionRock'),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: ResponsiveLayout
                                          .getResponsiveFontSize(context,
                                              mobile: 16,
                                              tablet: 18,
                                              desktop: 20),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              if (_capturedImage != null || _capturedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _capturedImage = null;
                            _capturedImageBytes = null;
                          });
                        },
                        child: Text(
                          context.t('camera.remove'),
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 22,
                                desktop: 24),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                          width: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      TextButton(
                        onPressed: () {
                          if (kIsWeb && _capturedImageBytes != null) {
                            _saveImage(_capturedImageBytes!);
                          } else if (_capturedImage != null) {
                            _capturedImage!.readAsBytes().then((bytes) {
                              _saveImage(bytes);
                            });
                          }
                        },
                        child: Text(
                          context.t('camera.save'),
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getResponsiveFontSize(
                                context,
                                mobile: 20,
                                tablet: 22,
                                desktop: 24),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MyCircleButton(
                        icon: HugeIcons.strokeRoundedImage01,
                        onPressed: _pickImageFromGallery,
                      ),
                      GestureDetector(
                        onTap: _captureImage,
                        child: Container(
                          width: ResponsiveLayout.getResponsiveIconSize(context,
                              mobile: 70, tablet: 80, desktop: 90),
                          height: ResponsiveLayout.getResponsiveIconSize(
                              context,
                              mobile: 70,
                              tablet: 80,
                              desktop: 90),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
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
                                  padding: EdgeInsets.all(12.0),
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
                      ),
                      if (!kIsWeb)
                        MyCircleButton(
                          icon: HugeIcons.strokeRoundedCamera01,
                          onPressed: _flipCamera,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Use mobile layout for tablet for now
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar for desktop
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // App title
              Container(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Geolab',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
              // Navigation items
              ListTile(
                leading:
                    Icon(Icons.home, color: Theme.of(context).primaryColor),
                title: const Text('Home'),
                onTap: () {},
              ),
              ListTile(
                leading:
                    Icon(Icons.settings, color: Theme.of(context).primaryColor),
                title: const Text('Settings'),
                onTap: () => context.go('/settings'),
              ),
              const Spacer(),
              // User info or logout
              ListTile(
                leading:
                    Icon(Icons.person, color: Theme.of(context).primaryColor),
                title: const Text('Profile'),
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: _buildMobileLayout(),
        ),
      ],
    );
  }
}
