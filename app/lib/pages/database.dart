import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ReconstructionParameters {
  final String runDirName;
  final String reconstructionMethod;
  final String reconstructionQuality;
  final String maskingMethod;
  final String deblurringMethod;
  final String computingUnit;
  final String reconstructionRepresentation;

  ReconstructionParameters(
      this.runDirName,
      this.reconstructionMethod,
      this.reconstructionQuality,
      this.maskingMethod,
      this.deblurringMethod,
      this.computingUnit,
      this.reconstructionRepresentation);

  Map<String, dynamic> toJson() => {
        'runDirName': runDirName,
        'reconstructionMethod': reconstructionMethod,
        'reconstructionQuality': reconstructionQuality,
        'maskingMethod': maskingMethod,
        'deblurringMethod': deblurringMethod,
        'computingUnit': computingUnit,
        'reconstructionRepresentation': reconstructionRepresentation
      };

  Future<void> writeToJsonFile(String pathToFile) async {
    File file = File(pathToFile);
    final spaces = ' ' * 4;
    final encoder = JsonEncoder.withIndent(spaces);
    await file.writeAsString(encoder.convert(toJson()));
  }
}

class RunInfo {
  late int id;
  final DateTime dateTime;
  String pathToThumbnail;
  final String pathToModel;
  final String reconstructionMethod;
  final String reconstructionQuality;
  final String maskingMethod;
  final String deblurringMethod;
  final String computingUnit;
  final String reconstructionRepresentation;

  late String dateTimeString;

  RunInfo(
      this.pathToThumbnail,
      this.dateTime,
      this.pathToModel,
      this.reconstructionMethod,
      this.reconstructionQuality,
      this.maskingMethod,
      this.deblurringMethod,
      this.computingUnit,
      this.reconstructionRepresentation) {
    setDateTimeString();
  }

  RunInfo.get(
      this.id,
      this.pathToThumbnail,
      this.dateTime,
      this.pathToModel,
      this.reconstructionMethod,
      this.reconstructionQuality,
      this.maskingMethod,
      this.deblurringMethod,
      this.computingUnit,
      this.reconstructionRepresentation) {
    setDateTimeString();
  }

  void setDateTimeString() {
    dateTimeString =
        '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}:${dateTime.millisecond}';
  }

  Map<String, Object?> toMap() {
    return {
      'pathToThumbnail': pathToThumbnail,
      'dateTime': dateTime.toString(),
      'pathToModel': pathToModel,
      'reconstructionMethod': reconstructionMethod,
      'reconstructionQuality': reconstructionQuality,
      'maskingMethod': maskingMethod,
      'deblurringMethod': deblurringMethod,
      'computingUnit': computingUnit,
      'reconstructionRepresentation': reconstructionRepresentation
    };
  }
}

class DatabaseDriver {
  final String databaseName = "runInfo";
  late String databasePath;
  late Future<Database> database;
  DatabaseDriver();

  Future<void> init() async {
    await setDatabasePath();
    database = open();
    await create();
  }

  Future<void> setDatabasePath() async {
    databasePath = join(await getDatabasesPath(), '$databaseName.db');
  }

  Future<Database> open() async {
    return openDatabase(databasePath, version: 1);
  }

  Future<void> insert(RunInfo runInfo) async {
    final db = await database;
    await db.insert(
      databaseName,
      runInfo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(RunInfo runInfo) async {
    final db = await database;
    await db.update(databaseName, runInfo.toMap(),
        where: 'id = ?', whereArgs: [runInfo.id]);
  }

  Future<List<RunInfo>> getAll() async {
    final db = await database;

    final List<Map<String, Object?>> runInfoMaps = await db.query(databaseName);

    return [
      for (final {
            'id': id as int,
            'pathToThumbnail': pathToThumbnail as String,
            'dateTime': dateTime as String,
            'pathToModel': pathToModel as String,
            'reconstructionMethod': reconstructionMethod as String,
            'reconstructionQuality': reconstructionQuality as String,
            'maskingMethod': maskingMethod as String,
            'deblurringMethod': deblurringMethod as String,
            'computingUnit': computingUnit as String,
            'reconstructionRepresentation':
                reconstructionRepresentation as String
          } in runInfoMaps)
        RunInfo.get(
            id,
            pathToThumbnail,
            DateTime.parse(dateTime),
            pathToModel,
            reconstructionMethod,
            reconstructionQuality,
            maskingMethod,
            deblurringMethod,
            computingUnit,
            reconstructionRepresentation),
    ];
  }

  Future<void> delete(int id) async {
    final db = await database;

    await db.delete(databaseName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> drop() async {
    final bool exists = await databaseExists(databasePath);
    if (exists) {
      final db = await database;
      await db.execute('DROP TABLE $databaseName');
    }
  }

  Future<bool> doesTableExist() async {
    try {
      final db = await database;
      await db.rawQuery("SELECT * FROM $databaseName LIMIT 1");
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> create() async {
    bool exists = await doesTableExist();
    if (exists) {
      return;
    }
    final db = await database;
    await db.execute('''
    create table $databaseName ( 
      id integer primary key autoincrement, 
      pathToThumbnail text not null,
      dateTime text not null,
      pathToModel text not null,
      reconstructionMethod text not null,
      reconstructionQuality text not null,
      maskingMethod text not null,
      deblurringMethod text not null,
      computingUnit text not null,
      reconstructionRepresentation text not null
    )
    ''');
  }
}
