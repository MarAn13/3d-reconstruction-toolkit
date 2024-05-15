import 'package:flutter/material.dart';
import 'package:reconstruction_3d/pages/camera_page.dart';

class HomePage extends StatefulWidget {
  final Function updateGlobalAppBar;
  HomePage({super.key, required this.updateGlobalAppBar});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false;

  void _pressButton() {
    Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraPage()),
              );
    return;
    setState(() {
      _isPressed = !_isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppBar globalAppBar = AppBar(centerTitle: true, title: Text("Reconstruction"));
    widget.updateGlobalAppBar(globalAppBar);
    if (_isPressed) {
      return CameraPage();
    } else {
      return Scaffold(
          body: Center(
        child: ElevatedButton(child: Text("PRESS TO START RECORDING"), onPressed: _pressButton),
      ));
    }
  }
}
