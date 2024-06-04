import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/storage.dart';

enum AuthMode { password, key }

class SSHDriver {
  SecureStorageDriver secureStorageDriver = SecureStorageDriver();
  SSHDriver();

  Future<SSHClient> connect() async {
    SecureStorageData storageData =
        await secureStorageDriver.storageRetrieveAll();
    late SSHClient client;
    if (!storageData.useKey) {
      client = SSHClient(
        await SSHSocket.connect(storageData.remoteAddress, 22),
        username: storageData.remoteUser,
        onPasswordRequest: () => storageData.remotePassword,
      );
    } else {
      client = SSHClient(
        await SSHSocket.connect(storageData.remoteAddress, 22),
        username: storageData.remoteUser,
        identities: [
          // A single private key file may contain multiple keys.
          ...SSHKeyPair.fromPem(
              await File(storageData.remotePathToKey).readAsString())
        ],
      );
    }
    return client;
  }

  Future<bool> runRemotePipeline(final String commandsStr) async {
    SSHClient sshClient = await connect();
    print("CLIENT CONNECTED");
    final pwd = await sshClient.run(commandsStr);
    print(utf8.decode(pwd));
    print("REMOTE PIPELINE DONE");
    sshClient.close();
    return true;
  }

  Future<String> downloadRemoteFile(final String remoteModelFilePath) async {
    SSHClient sshClient = await connect();
    print("CLIENT CONNECTED");
    final sftp = await sshClient.sftp();
    final remoteFile = await sftp.open(
      remoteModelFilePath,
      mode: SftpFileOpenMode.read,
    );
    final data = await remoteFile.readBytes();
    final localDirPath = (await getApplicationDocumentsDirectory()).path;
    final localFilePath = '${localDirPath}/model_final.glb';
    final localFile = File(localFilePath);
    print(localFilePath);
    try {
      await localFile.writeAsBytes(data);
    } catch (e) {
      print(e);
    }
    print('FILE DOWNLOADED');
    sftp.close();
    sshClient.close();
    return localFilePath;
  }

  Future<void> uploadLocalFile(
      final String localFilePath, final String remoteFilePath) async {
    SSHClient sshClient = await connect();
    final sftp = await sshClient.sftp();
    final file = await sftp.open(remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
    await file.write(File(localFilePath).openRead().cast());
    sftp.close();
    sshClient.close();
  }

  Future<String> runPipeline(final String runDirName,
      final String localVideoFilePath, final String pathToOptionsJson) async {
    SecureStorageDriver secureStorageDriver = SecureStorageDriver();
    SecureStorageData storageData =
        await secureStorageDriver.storageRetrieveAll();
    List<String> commands = storageData.remoteCommands.split('&&');
    String remoteRepoDirPath = commands[0].trim();
    remoteRepoDirPath = remoteRepoDirPath.replaceAll(RegExp(r'["]+'),'');
    commands = commands.sublist(1, commands.length);
    commands = [
      'cd "$remoteRepoDirPath"',
      ...commands,
      'bash ./app_pipeline.sh -d "$runDirName"'
    ];
    final String commandsStr = commands.join(' && ');
    print(remoteRepoDirPath);
    print(commandsStr);
    final String remoteVideosDirPath = "$remoteRepoDirPath/runs-data/videos";
    final String remoteVideoFileName = "video-$runDirName.mp4";
    final String remoteVideoFilePath =
        "$remoteVideosDirPath/$remoteVideoFileName";
    await uploadLocalFile(localVideoFilePath, remoteVideoFilePath);
    final String remoteOptionsDirPath = "$remoteRepoDirPath/runs-data/options";
    final String remoteOptionsFileName = "options-$runDirName.json";
    final String remoteOptionsFilePath =
        "$remoteOptionsDirPath/$remoteOptionsFileName";
    await uploadLocalFile(pathToOptionsJson, remoteOptionsFilePath);
    await runRemotePipeline(commandsStr);
    final String remoteModelFilePath = "$remoteRepoDirPath/runs/$runDirName/project/mvs/model_final.glb";
    String modelFilePath = await downloadRemoteFile(remoteModelFilePath);
    print(modelFilePath);
    return modelFilePath;
  }
}
