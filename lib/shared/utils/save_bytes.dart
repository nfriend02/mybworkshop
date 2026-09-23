import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Saves bytes with the platform save dialog (web download or mobile share sheet).
Future<bool> saveBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: filename,
    bytes: bytes,
    mimeType: mimeType,
  );
  return uri != null;
}
