import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jsonschema_form/src/screens/camera_resolution.dart';
import 'package:jsonschema_form/src/screens/camera_service.dart';
import 'package:jsonschema_form/src/utils/xfile_extension.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    required this.isPhotoAllowed,
    required this.isVideoAllowed,
    super.key,
    this.resolution = CameraResolution.max,
  });

  final bool isPhotoAllowed;
  final bool isVideoAllowed;
  final CameraResolution resolution;

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? _cameraController;
  Future<void>? cameraValue;
  bool isRecoring = false;
  bool flash = false;
  bool iscamerafront = true;
  double transform = 0;

  @override
  void initState() {
    super.initState();
    cameras = CameraService().cameras;
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0],
        widget.resolution.resolutionPreset,
      );
      cameraValue = _cameraController?.initialize();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    }
    //  else if (state == AppLifecycleState.resumed) {
    //    _initializeCamera();
    // }
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: cameraValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CameraPreview(_cameraController!),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          Positioned(
            bottom: 0,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          flash ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            flash = !flash;
                          });
                          flash
                              ? _cameraController?.setFlashMode(FlashMode.torch)
                              : _cameraController?.setFlashMode(FlashMode.off);
                        },
                      ),
                      GestureDetector(
                        onLongPress: () async {
                          await _cameraController?.startVideoRecording();
                          setState(() {
                            isRecoring = true;
                          });
                        },
                        onLongPressUp: () async {
                          final navigator = Navigator.of(context);
                          var videopath =
                              await _cameraController?.stopVideoRecording();
                          setState(() {
                            isRecoring = false;
                          });

                          if (!kIsWeb) {
                            videopath = await videopath
                                ?.rename(DateTime.now().toIso8601String());
                          }

                          navigator.pop(videopath);
                        },
                        onTap: () {
                          if (!isRecoring) takePhoto(context);
                        },
                        child: isRecoring
                            ? const Icon(
                                Icons.radio_button_on,
                                color: Colors.red,
                                size: 80,
                              )
                            : const Icon(
                                Icons.panorama_fish_eye,
                                color: Colors.white,
                                size: 70,
                              ),
                      ),
                      if ((cameras.length ?? 0) > 1)
                        IconButton(
                          icon: Transform.rotate(
                            angle: transform,
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onPressed: () async {
                            setState(() {
                              iscamerafront = !iscamerafront;
                              transform = transform + pi;
                            });
                            final cameraPos = iscamerafront ? 0 : 1;
                            _cameraController = CameraController(
                              cameras[cameraPos],
                              ResolutionPreset.high,
                            );
                            cameraValue = _cameraController?.initialize();
                          },
                        )
                      else
                        const SizedBox(
                          width: 50,
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'Hold for Video, tap for photo',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> takePhoto(BuildContext context) async {
    final navigator = Navigator.of(context);
    var file = await _cameraController?.takePicture();

    if (!kIsWeb) {
      file = await file?.rename(DateTime.now().toIso8601String());
    }

    navigator.pop(file);
  }
}

/// Extension for converting [CameraResolution] to [ResolutionPreset].
///
/// This extension provides a way to convert a [CameraResolution] value into
/// its corresponding [ResolutionPreset] value. It is useful when you need to
/// map different camera resolutions to preset values that
/// the camera API can use.
///
/// Example usage:
/// ```dart
/// CameraResolution resolution = CameraResolution.high;
/// ResolutionPreset preset = resolution.resolutionPreset;
/// ```
extension CameraResolutionExt on CameraResolution {
  /// Converts the [CameraResolution] to the corresponding [ResolutionPreset].
  ///
  /// This method maps the different camera resolution levels
  /// (low, medium, high, etc.) to the corresponding preset values available
  /// in the [ResolutionPreset] enum.
  ///
  /// Returns the appropriate [ResolutionPreset]
  /// based on the current [CameraResolution].
  ResolutionPreset get resolutionPreset {
    switch (this) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case CameraResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case CameraResolution.max:
        return ResolutionPreset.max;
    }
  }
}