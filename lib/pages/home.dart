import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/incidentform.dart';

class HomeCameraScreen extends StatefulWidget {
  const HomeCameraScreen({super.key});

  @override
  State<HomeCameraScreen> createState() => _HomeCameraScreenState();
}

class _HomeCameraScreenState extends State<HomeCameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        setState(() => _isCameraInitialized = false);
        return;
      }

      _cameraController = CameraController(
        _cameras![_selectedCameraIndex.clamp(0, _cameras!.length - 1)],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final XFile file = await controller.takePicture();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidentFormPage(imageFile: File(file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (file == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidentFormPage(imageFile: File(file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gallery failed: $e')));
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _cameraController!.setFlashMode(_flashMode);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;

    await _cameraController?.dispose();
    _cameraController = null;

    await _initializeCamera();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Snap Tips'),
        content: Image.asset('assets/tips.png'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.55), Colors.transparent, Colors.black.withOpacity(0.65)],
              ),
            ),
          ),
          Positioned(
            top: 54,
            left: 12,
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(_flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                ),
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.switch_camera, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _pickFromGallery,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.photo, color: Colors.black),
                ),
                FloatingActionButton(
                  onPressed: _captureImage,
                  backgroundColor: const Color(0xFFFF6B35),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
                FloatingActionButton(
                  onPressed: _showHelp,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.help_outline, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
