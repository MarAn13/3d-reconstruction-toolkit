import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:screenshot/screenshot.dart';

class ModelViewPage extends StatelessWidget {
  RunInfo runInfo;
  ModelViewPage({super.key, required this.runInfo});

  void _takeScreenshot(screenshotController) async {
    await screenshotController
        .capture(delay: Duration(milliseconds: 10))
        .then((screenshotImage) async {
      final appDirPath = (await getApplicationDocumentsDirectory()).path;
      final String newPathToThumbnail =
          '${appDirPath}/model_${runInfo.id}_poster.jpg';
      File posterFile = await File(newPathToThumbnail).create();
      await posterFile.writeAsBytes(screenshotImage);
      runInfo.pathToThumbnail = newPathToThumbnail;
      DatabaseDriver databaseDriver = DatabaseDriver();
      await databaseDriver.init();
      await databaseDriver.update(runInfo);
      print('NEW THUMBNAIL: $newPathToThumbnail');
    }).catchError((error) {
      print('ERROR CAPTURE: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('THUMBNAIL: ${runInfo.pathToThumbnail}');
    ModelViewer modelViewer = ModelViewer(
      backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
      src: '${runInfo.pathToModel}', //'file://$pathToModel',
      alt: 'A 3D model',
      ar: true,
      autoRotate: true,
      disableZoom: false,
      cameraControls: true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Model Viewer')),
      body: () {
        final bool previewReady = File(runInfo.pathToThumbnail).existsSync();
        if (previewReady) {
          print("NO CAPTURE");
          return modelViewer;
        }
        print("CAPTURE");
        ScreenshotController screenshotController = ScreenshotController();
        Screenshot modelScreenshot =
            Screenshot(controller: screenshotController, child: modelViewer);
        Future.delayed(const Duration(seconds: 3)).then((val) {
          _takeScreenshot(screenshotController);
        });
        return modelScreenshot;
      }(),
    );
  }
}
