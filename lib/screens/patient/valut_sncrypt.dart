import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

class VaultEncrypt {
  static final algorithm = AesGcm.with256bits();

  static final SecretKey secretKey = SecretKey(List.generate(32, (i) => i + 1));

  static Future<Directory> _vaultDir() async {
    final dir = await getApplicationDocumentsDirectory();

    final vault = Directory("${dir.path}/vault");

    if (!vault.existsSync()) {
      vault.createSync(recursive: true);
    }

    return vault;
  }

  /// ENCRYPT FILE
  static Future<void> encryptFile(File file, String fileId) async {
    final bytes = await file.readAsBytes();

    final nonce = algorithm.newNonce();

    final secretBox = await algorithm.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final vaultDir = await _vaultDir();

    final vaultFile = File("${vaultDir.path}/$fileId");

    await vaultFile.writeAsBytes([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    await file.delete();
  }

  /// DECRYPT TEMP FILE
  static Future<File?> decryptTempFile(String fileId) async {
    final dir = await getApplicationDocumentsDirectory();

    final vaultFile = File("${dir.path}/vault/$fileId");

    if (!vaultFile.existsSync()) return null;

    final data = await vaultFile.readAsBytes();

    final nonce = data.sublist(0, 12);

    final mac = Mac(data.sublist(data.length - 16));

    final cipherText = data.sublist(12, data.length - 16);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    final clear = await algorithm.decrypt(secretBox, secretKey: secretKey);

    final temp = File("${dir.path}/temp_$fileId");

    await temp.writeAsBytes(clear);

    return temp;
  }

  /// RESTORE FILE
  static Future<bool> restoreFile(String fileId, String originalPath) async {
    final temp = await decryptTempFile(fileId);

    if (temp == null) return false;

    final original = File(originalPath);

    if (!original.parent.existsSync()) return false;

    await temp.copy(originalPath);

    final dir = await getApplicationDocumentsDirectory();

    File("${dir.path}/vault/$fileId").deleteSync();

    return true;
  }
}
