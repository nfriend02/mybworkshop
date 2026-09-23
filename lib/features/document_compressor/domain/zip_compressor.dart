import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Packs named files into a ZIP archive.
Uint8List zipFiles(Map<String, Uint8List> files) {
  if (files.isEmpty) {
    throw StateError('압축할 파일이 없어요');
  }
  final archive = Archive();
  final used = <String>{};
  files.forEach((name, bytes) {
    var safe = name.trim().isEmpty ? 'file' : name.trim();
    safe = safe.replaceAll(RegExp(r'[\\/]+'), '_');
    var unique = safe;
    var n = 2;
    while (!used.add(unique)) {
      unique = '$n-$safe';
      n++;
    }
    archive.addFile(ArchiveFile.bytes(unique, bytes));
  });
  return ZipEncoder().encodeBytes(archive);
}
