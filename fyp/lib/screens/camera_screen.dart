// In camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0], // Use the first available camera
        ResolutionPreset.high,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _controller!.takePicture();
      // Pass the image path back to the previous screen
      if (mounted) {
         Navigator.of(context).pop(file.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}