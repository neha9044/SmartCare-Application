class VaultFile {
  final String fileId;
  final String originalName;
  final String originalPath;
  final int dateAdded;
  final bool isEncrypted;
  final String? mimeType;

  VaultFile({
    required this.fileId,
    required this.originalName,
    required this.originalPath,
    required this.dateAdded,
    required this.isEncrypted,
    this.mimeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'originalName': originalName,
      'originalPath': originalPath,
      'dateAdded': dateAdded,
      'isEncrypted': isEncrypted ? 1 : 0,
      'mimeType': mimeType,
    };
  }

  factory VaultFile.fromMap(Map<String, dynamic> map) {
    return VaultFile(
      fileId: map['fileId'],
      originalName: map['originalName'],
      originalPath: map['originalPath'],
      dateAdded: map['dateAdded'],
      isEncrypted: map['isEncrypted'] == 1,
      mimeType: map['mimeType'],
    );
  }
}
