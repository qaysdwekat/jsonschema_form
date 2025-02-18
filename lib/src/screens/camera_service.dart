import 'package:camera/camera.dart';

class CameraService {
  // Factory constructor that returns the same instance every time
  factory CameraService() => _instance;

  // Private constructor to prevent direct instantiation
  CameraService._privateConstructor();

  // The single instance of CameraService
  static final CameraService _instance = CameraService._privateConstructor();

  List<CameraDescription>? _availableCameras;

  // Initializes the available cameras and the camera controller
  Future<void> initAvailableCameras() async {
    try {
      // Get available cameras
      _availableCameras = await availableCameras();

      if (_availableCameras == null || _availableCameras!.isEmpty) {
        throw Exception('No cameras available.');
      }
    } catch (e) {
      _availableCameras = [];
      print('Error initializing cameras: $e');
    }
  }

  // Accessor method to get the list of available cameras
  List<CameraDescription> get cameras => _availableCameras ?? [];
}
