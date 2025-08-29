import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Home/components/MyCircleButton.dart';
import 'package:geolab/features/Home/components/MyDrawer.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_bloc.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_event.dart';
import 'package:geolab/features/RockClassification/Bloc/rock_classification_state.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0;
  File? _capturedImage;
  bool _isTakingPicture = false;

  // NEW: Track flash state
  bool _isFlashOn = false;

  Future<void> _initializeCamera() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.storage,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('camera.permissionRequired'))),
          );
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('camera.noCamerasFound'))),
          );
        }
        return;
      }

      _controller = CameraController(
        cameras![_currentCameraIndex],
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
        );
      }
    }
  }

  void _classifyImage(File imageFile) {
    context.read<RockClassificationBloc>().add(ClassifyRock(imageFile));
  }

  Future<void> _captureImage() async {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile imageFile = await _controller.takePicture();
      final File image = File(imageFile.path);
      setState(() {
        _capturedImage = image;
        _isTakingPicture = false;
      });
      _classifyImage(image);
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.captureError')}: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File imageFile = File(image.path);
        setState(() {
          _capturedImage = imageFile;
        });
        _classifyImage(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.galleryError')}: $e')),
        );
      }
    }
  }

  void _flipCamera() {
    if (cameras != null && cameras!.length > 1) {
      setState(() {
        _currentCameraIndex = (_currentCameraIndex + 1) % cameras!.length;
        _initializeCamera();
      });
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    if (_isFlashOn) {
      _controller.setFlashMode(FlashMode.torch);
    } else {
      _controller.setFlashMode(FlashMode.off);
    }
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/rock_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('camera.saved'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.t('camera.error')}: $e')),
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
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: BlocListener<RockClassificationBloc, RockClassificationState>(
        listener: (context, state) {
          if (state is ClassificationComplete) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return RTLWrapper(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('rockClassification.result'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${context.t('rockClassification.rockType')}: ${state.rockType}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          '${context.t('rockClassification.confidence')}: ${(state.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
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
                return RTLWrapper(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.t('rockClassification.error'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.t('common.close')),
                        ),
                      ],
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
          body: Stack(
            children: [
              if (cameras != null && cameras!.isNotEmpty)
                FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return SizedBox.expand(
                        child: CameraPreview(_controller),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            context.t('common.loading'),
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
                              icon: const Icon(
                                HugeIcons.strokeRoundedSidebarRight01,
                                color: Colors.white,
                                size: 45,
                              ),
                              onPressed: () =>
                                  _scaffoldKey.currentState!.openDrawer(),
                            ),

                            // Flash toggle button (right)
                            IconButton(
                              icon: Icon(
                                _isFlashOn
                                    ? HugeIcons.strokeRoundedFlash
                                    : HugeIcons.strokeRoundedFlashOff,
                                color: Colors.white,
                                size: 40,
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
                          width: 350,
                          height: 350,
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
                                  child: Image.file(
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
                                          size: 50,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          context.t('camera.positionRock'),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    if (_capturedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _capturedImage = null;
                                });
                              },
                              child: Text(
                                context.t('camera.remove'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                if (_capturedImage != null) {
                                  _capturedImage!.readAsBytes().then((bytes) {
                                    _saveImage(bytes);
                                  });
                                }
                              },
                              child: Text(
                                context.t('camera.save'),
                                style: const TextStyle(
                                  fontSize: 20,
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
                                width: 70,
                                height: 70,
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
          ),
        ),
      ),
    );
  }
}
