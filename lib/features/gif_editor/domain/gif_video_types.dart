import 'dart:typed_data';

class EncodedVideo {
  const EncodedVideo({required this.bytes, required this.mime, required this.extension});

  final Uint8List bytes;
  final String mime;
  final String extension;
}
