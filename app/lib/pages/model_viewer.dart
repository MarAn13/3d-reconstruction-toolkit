import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewPage extends StatelessWidget {
  final String pathToModel;
  const ModelViewPage({super.key, required this.pathToModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Viewer')),
      body: ModelViewer(
        backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
        src: '$pathToModel',//'file://$pathToModel',
        alt: 'A 3D model',
        ar: true,
        autoRotate: true,
        disableZoom: false,
        cameraControls: true,
      ),
    );
  }
}
