import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'save_bytes.dart';

Future<void> downloadFile(
  BuildContext context, {
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final saved = await saveBytes(bytes: bytes, filename: filename, mimeType: mimeType);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(saved ? '$filename 저장을 시작했어요' : '저장을 취소했어요')),
  );
}
