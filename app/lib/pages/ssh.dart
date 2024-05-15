import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/storage.dart';

enum AuthMode { password, key }

class SSHDriver {
  SecureStorageDriver secureStorageDriver = SecureStorageDriver();
  late Future<SSHClient> client;
  SSHDriver();

  Future<SSHClient> connect() async {
    SecureStorageData storageData =
        await secureStorageDriver.storageRetrieveAll();
    if (!storageData.useKey) {
      final client = SSHClient(
        await SSHSocket.connect(storageData.remoteAddress, 22),
        username: storageData.remoteUser,
        onPasswordRequest: () => storageData.remotePassword,
      );
    } else {
      final client = SSHClient(
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

  Future<bool> runRemotePipeline(final SSHClient sshClient) async {
    print("CLIENT CONNECTED");
    final pwd = await sshClient.run(
        'cd "C:/Users/marem/dev/projects/unn/cw/current_year_run/final" && bash ./test.sh');
    print(utf8.decode(pwd));
    print("REMOTE PIPELINE DONE");
    return true;
  }

  Future<String> downloadRemoteFile(final SSHClient sshClient) async {
    print("CLIENT CONNECTED");
    final sftp = await sshClient.sftp();
    final remoteFile = await sftp.open(
      "C:/Users/marem/dev/projects/unn/cw/current_year_run/final/runs/teddybear/project/mvs/model_final.glb",
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
    return localFilePath;
  }

  Future<void> uploadLocalFile(
      final SSHClient sshClient, final String localFilePath, final String remoteFilePath) async {
    final sftp = await sshClient.sftp();
    final file = await sftp.open(remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
    await file.write(File(localFilePath).openRead().cast());
    sftp.close();
  }

  Future<String> runPipeline(final String localVideoFilePath, final String pathToOptionsJson) async {
    SSHClient sshClient = await connect();
    //await uploadLocalFile(sshClient, localVideoFilePath, "C:/Users/marem/dev/projects/unn/cw/current_year_run/final/runs/teddybear/video.mp4");
    //await uploadLocalFile(sshClient, pathToOptionsJson, "C:/Users/marem/dev/projects/unn/cw/current_year_run/final/runs/teddybear/reconstruction-options.json");
    //await runRemotePipeline(sshClient);
    String modelFilePath = await downloadRemoteFile(sshClient);
    print(localVideoFilePath);
    sshClient.close();
    return modelFilePath;
  }
}
