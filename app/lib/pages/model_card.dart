import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/model_viewer.dart';
import 'package:share_plus/share_plus.dart';

class ModelCard extends StatelessWidget {
  const ModelCard(
      {super.key, required this.resetPageSignal, required this.modelInfo});

  final VoidCallback resetPageSignal;
  final RunInfo modelInfo;

  Future<File> generateNoisyImageFile() async {
    final width = 200; // Image width
    final height = 200; // Image height
    final Random random = Random();
    final image = img.Image(width: width, height: height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final color = img.ColorRgba8(0, 255, 0, 255);
        image.setPixel(x, y, color);
      }
    }

    final systemTempDir = Directory.systemTemp;
    final tempFilePath = '${systemTempDir.path}/noisy_image.png';
    File(tempFilePath)
      ..writeAsBytesSync(
          img.encodePng(image)); // Write the image data to a file

    return File(tempFilePath);
  }

  Future<File> getPosterFile(final String posterPath) async {
    File posterFile;
    if (!await File(posterPath).exists()) {
      posterFile = await getImageFileFromAsset();
    } else {
      posterFile = File(posterPath);
    }
    return posterFile;
  }

  // get sample model preview (asset)
  Future<File> getImageFileFromAsset() async {
    final String assetPath = "lib/assets/sample_model.jpg";
    final fileName = assetPath.split("/").last;
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    if (await tempFile.exists()) {
      return tempFile;
    }
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  void _shareModel() async {
    String text =
        'RECONSTRUCTION OPTIONS Reconstruction Method:${modelInfo.reconstructionMethod}\nReconstruction Quality:${modelInfo.reconstructionQuality}\nImage Masking Method:${modelInfo.maskingMethod}\nImage Deblurring Method:${modelInfo.deblurringMethod}\nComputing Unit:${modelInfo.computingUnit}\nReconstruction Representation:${modelInfo.reconstructionRepresentation}';
    Share.shareXFiles([XFile(modelInfo.pathToModel)], text: text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FutureBuilder<File>(
            future: getPosterFile(modelInfo.pathToThumbnail),
            builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return GestureDetector(
                  onTap: () {
                    debugPrint('MODELCARD:${modelInfo.pathToModel}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ModelViewPage(runInfo: modelInfo)),
                    ).then((value) => resetPageSignal());
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      image: DecorationImage(
                          image: FileImage(snapshot.data!), fit: BoxFit.cover),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return GestureDetector(
                    onTap: () {
                      debugPrint('MODELCARD:${modelInfo.pathToModel}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ModelViewPage(runInfo: modelInfo)),
                      ).then((value) => resetPageSignal());
                    },
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 5,
                        child: Text('Error loading image')));
              } else {
                return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 5,
                    child: CircularProgressIndicator());
              }
            }),
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Expanded(
                  child: Text(modelInfo.dateTimeString,
                      softWrap: true, overflow: TextOverflow.ellipsis)),
              ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            width: MediaQuery.of(context).size.width / 100 * 80,
                            height: MediaQuery.of(context).size.height / 2,
                            child: Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.share),
                                          onPressed: _shareModel,
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_forever),
                                          color: Colors.red,
                                          onPressed: () {
                                            if (modelInfo.id != null) {
                                              Navigator.pop(context);
                                              int id = modelInfo.id ?? 0;
                                              DatabaseDriver().delete(id);
                                              resetPageSignal();
                                            }
                                          },
                                        )
                                      ]),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 8.0,
                                                runSpacing: 8.0,
                                                children: <Widget>[
                                                  Text('RECONSTRUCTION OPTIONS',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall,
                                                      textAlign:
                                                          TextAlign.center),
                                                  SizedBox(height: 20),
                                                  Text(
                                                      'Reconstruction Method: ${modelInfo.reconstructionMethod}'),
                                                  Text(
                                                      'Reconstruction Quality: ${modelInfo.reconstructionQuality}'),
                                                  Text(
                                                      'Image Masking Method: ${modelInfo.maskingMethod}'),
                                                  Text(
                                                      'Image Deblurring Method: ${modelInfo.deblurringMethod}'),
                                                  Text(
                                                      'Computing Unit: ${modelInfo.computingUnit}'),
                                                  Text(
                                                    'Reconstruction Representation: ${modelInfo.reconstructionRepresentation}',
                                                    softWrap: true,
                                                  )
                                                ])
                                          ]),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                          context); // Close the dialog
                                    },
                                    child: Text('Close'),
                                  ),
                                ])),
                          ),
                        );
                      },
                    );
                  },
                  child: Text("options"))
            ])),
      ],
    ));
  }
}
