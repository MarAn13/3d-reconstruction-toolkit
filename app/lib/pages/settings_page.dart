import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageData {
  final String remoteAddress;
  final String remoteUser;
  final String remotePassword;
  final String remotePathToKey;
  final String remoteCommands;
  final RecordingQuality selectedRecordingQuality;
  const SecureStorageData(
      this.remoteAddress,
      this.remoteUser,
      this.remotePassword,
      this.remotePathToKey,
      this.remoteCommands,
      this.selectedRecordingQuality);
}

class SettingsPage extends StatefulWidget {
  final Function updateGlobalAppBar;
  const SettingsPage({super.key, required this.updateGlobalAppBar});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum RecordingQuality { low, medium, high, veryHigh, ultra }

class _SettingsPageState extends State<SettingsPage> {
  bool _isInit = true;
  bool _useKey = false;
  String remoteAddress = "";
  String remoteUser = "";
  String remotePassword = "";
  String remotePathToKey = "";
  String remoteCommands = "";
  RecordingQuality selectedRecordingQuality = RecordingQuality.ultra;
  final MaterialStateProperty<Icon?> _thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  final secureStorage = FlutterSecureStorage();

  void storageWrite(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  Future<SecureStorageData> storageRetrieveAll(bool init) async {
    if (!init) {
      return SecureStorageData(remoteAddress, remoteUser, remotePassword,
          remotePathToKey, remoteCommands, selectedRecordingQuality);
    }
    Map<String, String> allItems = await secureStorage.readAll();
    allItems.forEach((key, value) {
      switch (key) {
        case "remote-address":
          remoteAddress = value;
          break;
        case "remote-user":
          remoteUser = value;
          break;
        case "remote-password":
          remotePassword = value;
          break;
        case "remote-pathToKey":
          remotePathToKey = value;
          break;
        case "remote-commands":
          remoteCommands = value;
          break;
        case "recording-quality":
          selectedRecordingQuality = RecordingQuality.values[int.parse(value)];
      }
    });
    return SecureStorageData(remoteAddress, remoteUser, remotePassword,
        remotePathToKey, remoteCommands, selectedRecordingQuality);
  }

  @override
  Widget build(BuildContext context) {
    AppBar globalAppBar = AppBar(centerTitle: true, title: Text("Settings"));
    widget.updateGlobalAppBar(globalAppBar);
    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: FutureBuilder<SecureStorageData>(
                    future: storageRetrieveAll(_isInit),
                    builder: (BuildContext context,
                        AsyncSnapshot<SecureStorageData> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        SecureStorageData data = snapshot.data!;
                        TextField dynamicTextField;
                        if (_useKey) {
                          dynamicTextField = TextField(
                            controller:
                                TextEditingController(text: data.remotePathToKey),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter path to private key',
                            ),
                            onChanged: (text) {
                              remotePathToKey = text;
                            },
                          );
                        } else {
                          dynamicTextField = TextField(
                            controller:
                                TextEditingController(text: data.remotePassword),
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Enter remote password',
                            ),
                            onChanged: (text) {
                              remotePassword = text;
                            },
                          );
                        }
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Center(
                                  child: Text("Select Remote Options",
                                      style: TextStyle(fontSize: 25))),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
                                child: Row(children: <Widget>[
                                  Text("Use key"),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 10.0, 0),
                                    child: Switch(
                                      thumbIcon: _thumbIcon,
                                      value: _useKey,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _useKey = value;
                                          _isInit = false;
                                        });
                                      },
                                    ),
                                  ),
                                ]),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                controller: TextEditingController(
                                    text: data.remoteAddress),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Enter remote address',
                                ),
                                onChanged: (text) {
                                  remoteAddress = text;
                                },
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                controller:
                                    TextEditingController(text: data.remoteUser),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Enter remote user',
                                ),
                                onChanged: (text) {
                                  remoteUser = text;
                                },
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              dynamicTextField,
                              SizedBox(
                                height: 10.0,
                              ),
                              TextField(
                                controller: TextEditingController(
                                    text: data.remoteCommands),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText:
                                      'Enter remote commands (e.g. cd "path" && echo "success")',
                                ),
                                onChanged: (text) {
                                  remoteCommands = text;
                                },
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("Select camera recording quality",
                                        style: TextStyle(fontSize: 18.0)),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    SegmentedButton<RecordingQuality>(
                                      segments: const <ButtonSegment<
                                          RecordingQuality>>[
                                        ButtonSegment<RecordingQuality>(
                                            value: RecordingQuality.low,
                                            label: Text('Low')),
                                        ButtonSegment<RecordingQuality>(
                                            value: RecordingQuality.medium,
                                            label: Text('Medium')),
                                        ButtonSegment<RecordingQuality>(
                                            value: RecordingQuality.high,
                                            label: Text('High')),
                                        ButtonSegment<RecordingQuality>(
                                            value: RecordingQuality.veryHigh,
                                            label: Text('Very High')),
                                        ButtonSegment<RecordingQuality>(
                                            value: RecordingQuality.ultra,
                                            label: Text('Ultra')),
                                      ],
                                      onSelectionChanged:
                                          (Set<RecordingQuality> newSelection) {
                                        // By default there is only a single segment that can be
                                        // selected at one time, so its value is always the first
                                        // item in the selected set.
                                        setState(() {
                                          selectedRecordingQuality =
                                              newSelection.first;
                                          _isInit = false;
                                        });
                                      },
                                      selected: <RecordingQuality>{
                                        data.selectedRecordingQuality
                                      },
                                    )
                                  ]),
                              SizedBox(
                                height: 10.0,
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    String key = "remote-use-key";
                                    String value = _useKey.toString();
                                    storageWrite(key, value);
                                    key = "remote-address";
                                    value = remoteAddress;
                                    storageWrite(key, value);
                                    key = "remote-user";
                                    value = remoteUser;
                                    storageWrite(key, value);
                                    key = "remote-password";
                                    value = remotePassword;
                                    storageWrite(key, value);
                                    key = "remote-pathToKey";
                                    value = remotePathToKey;
                                    storageWrite(key, value);
                                    key = "remote-commands";
                                    value = remoteCommands;
                                    storageWrite(key, value);
                                    key = "recording-quality";
                                    value = '${selectedRecordingQuality.index}';
                                    storageWrite(key, value);
                                    setState(() {});
                                  },
                                  child: const Text('Save'))
                            ]);
                      }
                    }))
          ]),
        ));
  }
}
