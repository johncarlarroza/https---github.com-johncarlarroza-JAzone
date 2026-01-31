import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jazone_1/screens/incidentform.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
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
    _cameras = await availableCameras();

    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(_flashMode);

    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  void _toggleFlash() {
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    _cameraController!.setFlashMode(_flashMode);
    setState(() {});
  }

  void _switchCamera() async {
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    setState(() => _isCameraInitialized = false);
    await _initializeCamera();
  }

  Future<void> _captureImage() async {
    if (!_cameraController!.value.isInitialized) return;

    XFile file = await _cameraController!.takePicture();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentFormPage(imageFile: File(file.path)),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentFormPage(imageFile: File(file.path)),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Snap Tips"),
        content: const Text(
          "Tips for capturing incident evidence will be displayed here.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
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
    double focusWidth = 320;
    double focusHeight = 550;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          _isCameraInitialized
              ? Center(
                  child: Container(
                    width: focusWidth,
                    height: focusHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade400, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          /// DARK GRADIENT OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),

          /// LOGO + TITLE
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade400.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png', // <-- make sure this matches your asset path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // const Text(
                //   'JAZone Alert',
                //   style: TextStyle(
                //     fontSize: 22,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //   ),
                // ),
                // const SizedBox(height: 4),
                // const Text(
                //   'Capture incident evidence',
                //   style: TextStyle(fontSize: 14, color: Colors.white70),
                // ),
              ],
            ),
          ),

          /// TOP CONTROLS
          Positioned(
            top: 120,
            left: 30,
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.switch_camera, color: Colors.white),
                ),
              ],
            ),
          ),

          /// BOTTOM CONTROLS
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  onPressed: _pickFromGallery,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.photo, color: Colors.black),
                ),
                FloatingActionButton(
                  onPressed: _captureImage,
                  backgroundColor: Colors.blue.shade400,
                  child: const Icon(Icons.camera, color: Colors.white),
                ),
                FloatingActionButton(
                  onPressed: _showHelpDialog,
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
