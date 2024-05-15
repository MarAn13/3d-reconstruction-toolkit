import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:reconstruction_3d/main.dart';
import 'package:reconstruction_3d/pages/home_page.dart';
import 'package:reconstruction_3d/pages/video_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  late CameraController _cameraController;

  _initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    _cameraController =
        CameraController(back, ResolutionPreset.max, enableAudio: false);
    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => VideoPage(filePath: file.path),
          ));
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  int _selectedPageIndex = 1;

  void _navigateBottomBar(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainApp(initPageIndex: index)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainApp(initPageIndex: 1)),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            title: Text("Recording")),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedPageIndex,
          onTap: _navigateBottomBar,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "history"),
            BottomNavigationBarItem(icon: Icon(Icons.radio_button_checked), label: "reconstruction"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "settings")
          ],
        ),
        body: Center(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CameraPreview(_cameraController),
              Padding(
                padding: const EdgeInsets.all(25),
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  child: Icon(_isRecording ? Icons.stop : Icons.circle),
                  onPressed: () => _recordVideo(),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
