import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedBytes {
  const PickedBytes({required this.name, required this.bytes, this.mimeType});

  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

/// Reads picked files into memory. An empty list means the user cancelled.
Future<List<PickedBytes>> pickWorkshopFiles({
  FileType type = FileType.any,
  bool multiple = false,
}) async {
  if (!multiple) {
    final file = await FilePicker.pickFile(type: type);
    if (file == null) return const [];
    return [PickedBytes(name: file.name, bytes: await file.readAsBytes())];
  }

  final files = await FilePicker.pickFiles(type: type);
  final picked = <PickedBytes>[];
  for (final file in files) {
    picked.add(PickedBytes(name: file.name, bytes: await file.readAsBytes()));
  }
  return picked;
}
