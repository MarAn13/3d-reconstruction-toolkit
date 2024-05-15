import 'package:flutter/material.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/model_card.dart';

class HistoryPage extends StatefulWidget {
  final Function updateGlobalAppBar;
  const HistoryPage({super.key, required this.updateGlobalAppBar});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // update page when signal is recieved from ModelCard
  void handleResetSignal() {
    setState(() {});
  }

  Future<List<RunInfo>> _getFromDatabase() async {
    DatabaseDriver databaseDriver = DatabaseDriver();
    await databaseDriver.init();
    //await databaseDriver.drop();
    return databaseDriver.getAll();
  }

  Future<List<RunInfo>> _test() async {
    DatabaseDriver databaseDriver = DatabaseDriver();
    await databaseDriver.init();
    await databaseDriver.drop();

    RunInfo runInfo1 = RunInfo("lib/assets/bowl_asset.jpg", DateTime.now().toUtc(), "lib/assets/bowl_asset.glb", 
    "Classic", "Low", "Segment", "None", "CPU", "Mesh");
    RunInfo runInfo2 = RunInfo("lib/assets/orange_asset.jpg", DateTime.now().toUtc(), "lib/assets/orange_asset.glb", 
    "Deep", "High", "Segment", "None", "GPU", "Mesh");
    RunInfo runInfo3 = RunInfo("lib/assets/teddybear_asset.jpg", DateTime.now().toUtc(), "lib/assets/teddybear_asset.glb", 
    "Deep", "High", "Segment", "None", "GPU", "Mesh");
    await databaseDriver.create();
    await databaseDriver.insert(runInfo1);
    await databaseDriver.insert(runInfo2);
    await databaseDriver.insert(runInfo3);
    return _getFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    AppBar globalAppBar = AppBar(centerTitle: true, title: Text("History"));
    widget.updateGlobalAppBar(globalAppBar);

    return FutureBuilder<List<RunInfo>>(
      future: _getFromDatabase(),
      builder: (BuildContext context, AsyncSnapshot<List<RunInfo>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<RunInfo> runInfos = snapshot.data!;
          List<ModelCard> cards = runInfos
              .map((info) => ModelCard(
                  resetPageSignal: handleResetSignal, modelInfo: info))
              .toList();
          cards.sort((a, b) {
            if (a.modelInfo.dateTime.isAfter(b.modelInfo.dateTime)) {
              return -1;
            }
            return 1;
          });

          return Scaffold(
            body: Scrollbar(
              child: ListView(
                children: <Widget>[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: cards.map((ModelCard card) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 2 -
                            12.0, // Half of the screen width with spacing adjustment
                        child: card,
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
