import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static late List<CameraDescription> cameras;
  static bool _initialized = false;

  // Initialize cameras
  static Future<void> initCameras() async {
    if (_initialized) return;
    
    try {
      cameras = await availableCameras();
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      _initialized = false;
    }
  }

  // Check if device has cameras
  static Future<bool> hasCameras() async {
    if (!_initialized) {
      await initCameras();
    }
    return cameras.isNotEmpty;
  }

  // Get camera controller for the front or back camera
  static Future<CameraController?> getCameraController({bool useFrontCamera = false}) async {
    if (!await hasCameras()) {
      return null;
    }

    // Find the right camera
    CameraDescription? selectedCamera;
    for (var camera in cameras) {
      if ((useFrontCamera && camera.lensDirection == CameraLensDirection.front) ||
          (!useFrontCamera && camera.lensDirection == CameraLensDirection.back)) {
        selectedCamera = camera;
        break;
      }
    }

    // If the preferred camera isn't found, use the first available one
    selectedCamera ??= cameras.first;

    // Create and initialize the controller
    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      await controller.dispose();
      return null;
    }
  }

  // Helper method to determine if we're running on desktop
  static bool get isDesktop {
    return kIsWeb ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  }
} 