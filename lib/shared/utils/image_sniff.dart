import 'dart:typed_data';

/// Image type detected from bytes, then MIME, then the file name.
enum ImageKind { png, jpg, gif, webp, bmp, heic, unknown }

const heicUploadMessage = 'HEIC는 JPG 또는 PNG로 바꾼 뒤 올려 주세요';

ImageKind imageKindOf(Uint8List bytes, {String name = '', String? mimeType}) {
  final sniffed = _sniff(bytes);
  if (sniffed != ImageKind.unknown) return sniffed;

  final mime = (mimeType ?? '').split(';').first.trim().toLowerCase();
  final fromMime = switch (mime) {
    'image/png' => ImageKind.png,
    'image/jpeg' || 'image/jpg' || 'image/pjpeg' => ImageKind.jpg,
    'image/gif' => ImageKind.gif,
    'image/webp' => ImageKind.webp,
    'image/bmp' || 'image/x-ms-bmp' => ImageKind.bmp,
    'image/heic' || 'image/heif' => ImageKind.heic,
    _ => ImageKind.unknown,
  };
  if (fromMime != ImageKind.unknown) return fromMime;

  final lower = _baseName(name).toLowerCase();
  if (lower.endsWith('.png')) return ImageKind.png;
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.jfif') ||
      lower.endsWith('.jpe')) {
    return ImageKind.jpg;
  }
  if (lower.endsWith('.gif')) return ImageKind.gif;
  if (lower.endsWith('.webp')) return ImageKind.webp;
  if (lower.endsWith('.bmp')) return ImageKind.bmp;
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return ImageKind.heic;
  return ImageKind.unknown;
}

bool isZipPayload(Uint8List bytes, String name) {
  if (imageKindOf(bytes, name: name) != ImageKind.unknown) return false;
  if (_baseName(name).toLowerCase().endsWith('.zip')) return true;
  return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
}

bool looksLikePdf(Uint8List bytes) {
  return bytes.length >= 5 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

String ensureImageName(String name, ImageKind kind) {
  final ext = switch (kind) {
    ImageKind.png => 'png',
    ImageKind.jpg => 'jpg',
    ImageKind.gif => 'gif',
    ImageKind.webp => 'webp',
    ImageKind.bmp => 'bmp',
    ImageKind.heic => 'heic',
    ImageKind.unknown => 'img',
  };
  final base = _baseName(name);
  final lower = base.toLowerCase();
  const aliases = {
    ImageKind.jpg: ['.jpg', '.jpeg', '.jfif', '.jpe'],
  };
  final accepted = aliases[kind] ?? ['.$ext'];
  if (accepted.any(lower.endsWith)) return base.isEmpty ? 'image.$ext' : base;
  final stem = base.isEmpty
      ? 'image'
      : (base.contains('.') ? base.substring(0, base.lastIndexOf('.')) : base);
  return '$stem.$ext';
}

String _baseName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'[/\\]')).last;
}

ImageKind _sniff(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return ImageKind.png;
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return ImageKind.jpg;
  }
  if (bytes.length >= 6 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
    return ImageKind.gif;
  }
  if (bytes.length >= 12 &&
      _ascii(bytes, 0, 4) == 'RIFF' &&
      _ascii(bytes, 8, 4) == 'WEBP') {
    return ImageKind.webp;
  }
  if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return ImageKind.bmp;
  }
  if (bytes.length >= 12 && _ascii(bytes, 4, 4) == 'ftyp') {
    final brand = _ascii(bytes, 8, 4).toLowerCase();
    if (brand.startsWith('hei') || brand.startsWith('hev') || brand == 'mif1' || brand == 'msf1') {
      return ImageKind.heic;
    }
  }
  return ImageKind.unknown;
}

String _ascii(Uint8List bytes, int start, int length) {
  return String.fromCharCodes(bytes.sublist(start, start + length));
}
