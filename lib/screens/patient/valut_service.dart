import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:smartcare_app/screens/patient/valut_model.dart';
import 'package:smartcare_app/screens/patient/valut_sncrypt.dart';

class VaultService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;

    final path = await getDatabasesPath();

    _db = await openDatabase(
      "$path/vault.db",
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE vault_files(
          fileId TEXT PRIMARY KEY,
          originalName TEXT,
          originalPath TEXT,
          dateAdded INTEGER,
          isEncrypted INTEGER,
          mimeType TEXT
        )
        ''');
      },
    );

    return _db!;
  }

  static Future<List<VaultFile>> getVaultFiles() async {
    final database = await db;

    final res = await database.query("vault_files");

    return res.map((e) => VaultFile.fromMap(e)).toList();
  }

  static Future<void> addFileToVault() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    final file = File(result.files.single.path!);

    final fileId = const Uuid().v4();

    await VaultEncrypt.encryptFile(file, fileId);

    final database = await db;

    await database.insert(
      "vault_files",
      VaultFile(
        fileId: fileId,
        originalName: result.files.single.name,
        originalPath: result.files.single.path!,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
        isEncrypted: true,
        mimeType: result.files.single.extension,
      ).toMap(),
    );
  }

  static Future<File?> decryptTempFile(String fileId) {
    return VaultEncrypt.decryptTempFile(fileId);
  }

  static Future<bool> restoreFile(VaultFile file) {
    return VaultEncrypt.restoreFile(file.fileId, file.originalPath);
  }

  static Future<void> deleteFile(VaultFile file) async {
    final dir = await getApplicationDocumentsDirectory();

    File("${dir.path}/vault/${file.fileId}").deleteSync();

    final database = await db;

    await database.delete(
      "vault_files",
      where: "fileId=?",
      whereArgs: [file.fileId],
    );
  }
}
