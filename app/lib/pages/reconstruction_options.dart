import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reconstruction_3d/main.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/ssh.dart';

class ReconstructionOptionsPage extends StatefulWidget {
  final String filePath;
  const ReconstructionOptionsPage({super.key, required this.filePath});

  @override
  State<ReconstructionOptionsPage> createState() =>
      _ReconstructionOptionsPageState();
}

enum ReconstructionMethod { classic, deep }

enum ReconstructionQuality { low, medium, high }

enum ImageMaskingMethod { none, segment }

enum ImageDeblurringMethod { none, wiener, deblurganV2 }

enum ComputingUnit { cpu, gpu }

enum ReconstructionRepresentation { pointcloud, mesh }

enum ProcessStatus { waiting, processing, error, done }

class _ReconstructionOptionsPageState extends State<ReconstructionOptionsPage> {
  ReconstructionMethod selectedReconstructionMethod =
      ReconstructionMethod.classic;
  ReconstructionQuality selectedReconstructionQuality =
      ReconstructionQuality.low;
  ImageMaskingMethod selectedMaskingMethod = ImageMaskingMethod.none;
  ImageDeblurringMethod selectedDeblurringMethod = ImageDeblurringMethod.none;
  ComputingUnit selectedComputingUnit = ComputingUnit.cpu;
  ReconstructionRepresentation selectedReconstructionRepresentation =
      ReconstructionRepresentation.pointcloud;

  int _selectedPageIndex = 1;
  void _navigateBottomBar(int index) {
    setState(() {
      _selectedPageIndex = index;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => MainApp(initPageIndex: _selectedPageIndex)),
        (Route<dynamic> route) => false,
      );
    });
  }

  ProcessStatus _processStatus = ProcessStatus.waiting;

  Future<bool> _runRemote() async {
    {
      setState(() {
        _processStatus = ProcessStatus.processing;
      });
      // init variables
      final nowUtc = DateTime.now().toUtc();
      final String runDirName =
          'run-${nowUtc.year}-${nowUtc.month}-${nowUtc.day}-${nowUtc.hour}-${nowUtc.minute}-${nowUtc.second}-${nowUtc.millisecond}';
      final String reconstructionMethod = selectedReconstructionMethod.name;
      final String reconstructionQuality = selectedReconstructionQuality.name;
      final String maskingMethod = selectedMaskingMethod.name;
      final String deblurringMethod = selectedDeblurringMethod.name;
      final String computingUnit = selectedComputingUnit.name;
      final String reconstructionRepresentation =
          selectedReconstructionRepresentation.name;
      ReconstructionParameters reconstructionOptions = ReconstructionParameters(
          runDirName,
          reconstructionMethod,
          reconstructionQuality,
          maskingMethod,
          deblurringMethod,
          computingUnit,
          reconstructionRepresentation);
      Directory tempDir = await getTemporaryDirectory();
      final String pathToOptionsJson =
          '${tempDir.path}/reconstruction-options.json';
      await reconstructionOptions.writeToJsonFile(pathToOptionsJson);
      // get remotely reconstructed and saved locally model path
      final String localVideoFilePath = widget.filePath;
      String modelFilePath;
      try {
        modelFilePath = await SSHDriver()
            .runPipeline(runDirName, localVideoFilePath, pathToOptionsJson);
      } catch (error) {
        debugPrint(error.toString());
        tempDir.deleteSync(recursive: true);
        tempDir.create();
        setState(() {
          _processStatus = ProcessStatus.error;
        });
        Future.delayed(const Duration(seconds: 2)).then((val) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainApp(initPageIndex: 1)),
          (Route<dynamic> route) => false,
        );
      });
        return false;
      }
      debugPrint('RECEIVED MODEL PATH: $modelFilePath');
      // insert into the database
      RunInfo newRunInfo = RunInfo(
          "",
          nowUtc,
          modelFilePath,
          reconstructionMethod,
          reconstructionQuality,
          maskingMethod,
          deblurringMethod,
          computingUnit,
          reconstructionRepresentation);
      DatabaseDriver databaseDriver = DatabaseDriver();
      await databaseDriver.init();
      await databaseDriver.insert(newRunInfo);
      tempDir.deleteSync(recursive: true);
      tempDir.create();
      setState(() {
        _processStatus = ProcessStatus.done;
      });
      Future.delayed(const Duration(seconds: 2)).then((val) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainApp(initPageIndex: 1)),
          (Route<dynamic> route) => false,
        );
      });
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? dynamicWidget;
    if (_processStatus == ProcessStatus.waiting) {
      dynamicWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text('3D Reconstruction method'),
                  SegmentedButton<ReconstructionMethod>(
                    segments: const <ButtonSegment<ReconstructionMethod>>[
                      ButtonSegment<ReconstructionMethod>(
                          value: ReconstructionMethod.classic,
                          label: Text('Classic')),
                      ButtonSegment<ReconstructionMethod>(
                          value: ReconstructionMethod.deep,
                          label: Text('Deep')),
                    ],
                    selected: <ReconstructionMethod>{
                      selectedReconstructionMethod
                    },
                    onSelectionChanged:
                        (Set<ReconstructionMethod> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedReconstructionMethod = newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text("Reconstruction quality"),
                  SegmentedButton<ReconstructionQuality>(
                    segments: const <ButtonSegment<ReconstructionQuality>>[
                      ButtonSegment<ReconstructionQuality>(
                          value: ReconstructionQuality.low, label: Text('Low')),
                      ButtonSegment<ReconstructionQuality>(
                          value: ReconstructionQuality.medium,
                          label: Text('Medium')),
                      ButtonSegment<ReconstructionQuality>(
                          value: ReconstructionQuality.high,
                          label: Text('High')),
                    ],
                    selected: <ReconstructionQuality>{
                      selectedReconstructionQuality
                    },
                    onSelectionChanged:
                        (Set<ReconstructionQuality> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedReconstructionQuality = newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text("Masking method"),
                  SegmentedButton<ImageMaskingMethod>(
                    segments: const <ButtonSegment<ImageMaskingMethod>>[
                      ButtonSegment<ImageMaskingMethod>(
                          value: ImageMaskingMethod.none, label: Text('None')),
                      ButtonSegment<ImageMaskingMethod>(
                          value: ImageMaskingMethod.segment,
                          label: Text('Segment')),
                    ],
                    selected: <ImageMaskingMethod>{selectedMaskingMethod},
                    onSelectionChanged: (Set<ImageMaskingMethod> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedMaskingMethod = newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text("Deblurring method"),
                  SegmentedButton<ImageDeblurringMethod>(
                    segments: const <ButtonSegment<ImageDeblurringMethod>>[
                      ButtonSegment<ImageDeblurringMethod>(
                          value: ImageDeblurringMethod.none,
                          label: Text('None')),
                      ButtonSegment<ImageDeblurringMethod>(
                          value: ImageDeblurringMethod.wiener,
                          label: Text('Classic (wiener)')),
                    ],
                    selected: <ImageDeblurringMethod>{selectedDeblurringMethod},
                    onSelectionChanged:
                        (Set<ImageDeblurringMethod> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedDeblurringMethod = newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text("Computing unit"),
                  SegmentedButton<ComputingUnit>(
                    segments: const <ButtonSegment<ComputingUnit>>[
                      ButtonSegment<ComputingUnit>(
                          value: ComputingUnit.cpu, label: Text('CPU')),
                      ButtonSegment<ComputingUnit>(
                          value: ComputingUnit.gpu, label: Text('GPU')),
                    ],
                    selected: <ComputingUnit>{selectedComputingUnit},
                    onSelectionChanged: (Set<ComputingUnit> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedComputingUnit = newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Text("Reconstruction representation"),
                  SegmentedButton<ReconstructionRepresentation>(
                    segments: const <ButtonSegment<
                        ReconstructionRepresentation>>[
                      ButtonSegment<ReconstructionRepresentation>(
                          value: ReconstructionRepresentation.pointcloud,
                          label: Text('Pointcloud')),
                      ButtonSegment<ReconstructionRepresentation>(
                          value: ReconstructionRepresentation.mesh,
                          label: Text('Mesh')),
                    ],
                    selected: <ReconstructionRepresentation>{
                      selectedReconstructionRepresentation
                    },
                    onSelectionChanged:
                        (Set<ReconstructionRepresentation> newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        selectedReconstructionRepresentation =
                            newSelection.first;
                      });
                    },
                  )
                ])),
            Expanded(
                flex: 2,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: SizedBox(), flex: 6),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: _runRemote,
                              child: const Text('Process')),
                          flex: 2),
                      Expanded(child: SizedBox(), flex: 2),
                    ]))
          ]);
    } else if (_processStatus == ProcessStatus.processing) {
      dynamicWidget = CircularProgressIndicator();
    }else if (_processStatus == ProcessStatus.error){
      dynamicWidget = Icon(Icons.close, color: Colors.red);
    } else {
      dynamicWidget = Icon(Icons.check, color: Colors.green);
    }
    return Scaffold(
        appBar: AppBar(
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
            centerTitle: true,
            title: Text("Reconstruction options")),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedPageIndex,
          onTap: _navigateBottomBar,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "history"),
            BottomNavigationBarItem(
                icon: Icon(Icons.radio_button_checked),
                label: "reconstruction"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "settings")
          ],
        ),
        body: Center(child: dynamicWidget));
  }
}
