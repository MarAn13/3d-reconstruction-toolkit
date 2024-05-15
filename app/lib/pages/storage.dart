import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum RecordingQuality { low, medium, high, veryHigh, ultra }

class SecureStorageData {
  final bool useKey;
  final String remoteAddress;
  final String remoteUser;
  final String remotePassword;
  final String remotePathToKey;
  final String remoteCommands;
  final RecordingQuality selectedRecordingQuality;
  const SecureStorageData(
      this.useKey,
      this.remoteAddress,
      this.remoteUser,
      this.remotePassword,
      this.remotePathToKey,
      this.remoteCommands,
      this.selectedRecordingQuality);
}

class SecureStorageDriver {
  final secureStorage = FlutterSecureStorage();

  void storageWrite(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  Future<SecureStorageData> storageRetrieveAll() async {
    bool useKey = false;
    String remoteAddress = "";
    String remoteUser = "";
    String remotePassword = "";
    String remotePathToKey = "";
    String remoteCommands = "";
    RecordingQuality selectedRecordingQuality = RecordingQuality.low;
    Map<String, String> allItems = await secureStorage.readAll();
    allItems.forEach((key, value) {
      switch (key) {
        case "remote-use-key":
          useKey = bool.parse(value);
          break;
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
    return SecureStorageData(useKey, remoteAddress, remoteUser, remotePassword,
        remotePathToKey, remoteCommands, selectedRecordingQuality);
  }
}
