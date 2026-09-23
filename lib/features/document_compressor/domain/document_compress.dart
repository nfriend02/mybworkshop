import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'zip_compressor.dart';

class HwpBlocked implements Exception {
  const HwpBlocked();

  final String message = 'PDF/Word로 변환 후 업로드';

  @override
  String toString() => message;
}

class CompressedFile {
  const CompressedFile({required this.name, required this.bytes, required this.note});

  final String name;
  final Uint8List bytes;
  final String note;
}

bool isHwpName(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.hwp') || lower.endsWith('.hwpx');
}

String compName(String name, String extension) {
  final slash = name.replaceAll('\\', '/').split('/').last;
  final dot = slash.lastIndexOf('.');
  final stem = dot <= 0 ? slash : slash.substring(0, dot);
  return '${stem}_comp.$extension';
}

CompressedFile compressDocument({required String name, required Uint8List bytes}) {
  if (isHwpName(name)) throw const HwpBlocked();
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return _compressPdf(name, bytes);
  if (_isRaster(lower)) return _compressRaster(name, bytes);
  return CompressedFile(
    name: compName(name, 'zip'),
    bytes: zipFiles({name: bytes}),
    note: '이미지/PDF가 아니라 ZIP으로 용량을 줄였어요',
  );
}

bool _isRaster(String lower) {
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp');
}

CompressedFile _compressRaster(String name, Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('이미지를 읽지 못했어요');
  }
  final fitted = _downscale(decoded, 1280);
  return CompressedFile(
    name: compName(name, 'jpg'),
    bytes: img.encodeJpg(fitted, quality: 38),
    note: '저화질 JPG로 저장했어요',
  );
}

CompressedFile _compressPdf(String name, Uint8List bytes) {
  final pages = <img.Image>[];
  for (final jpeg in _extractJpegs(bytes)) {
    final decoded = img.decodeJpg(jpeg);
    if (decoded == null) continue;
    pages.add(_downscale(decoded, 900));
    if (pages.length >= 20) break;
  }
  if (pages.isEmpty) {
    return CompressedFile(
      name: compName(name, 'pdf'),
      bytes: _textPdf('No raster pages were found. Upload a scanned PDF or export pages as images.'),
      note: '페이지 이미지가 없어 안내 PDF를 만들었어요',
    );
  }
  return CompressedFile(
    name: compName(name, 'pdf'),
    bytes: _imagePdf(pages),
    note: '${pages.length}페이지를 저화질 PDF로 다시 묶었어요',
  );
}

img.Image _downscale(img.Image src, int maxSide) {
  if (src.width <= maxSide && src.height <= maxSide) return src;
  if (src.width >= src.height) {
    return img.copyResize(src, width: maxSide);
  }
  return img.copyResize(src, height: maxSide);
}

List<Uint8List> _extractJpegs(Uint8List bytes) {
  final found = <Uint8List>[];
  final limit = bytes.length < 25000000 ? bytes.length : 25000000;
  var i = 0;
  while (i < limit - 1 && found.length < 20) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
      var j = i + 2;
      while (j < limit - 1) {
        if (bytes[j] == 0xFF && bytes[j + 1] == 0xD9) {
          final slice = Uint8List.sublistView(bytes, i, j + 2);
          if (img.decodeJpg(slice) != null) found.add(Uint8List.fromList(slice));
          i = j + 2;
          break;
        }
        j++;
      }
      if (j >= limit - 1) break;
    } else {
      i++;
    }
  }
  return found;
}

Uint8List _imagePdf(List<img.Image> pages) {
  final jpegs = [for (final page in pages) img.encodeJpg(page, quality: 32)];
  final objects = <Uint8List>[];
  void add(String source, [Uint8List? stream]) {
    final builder = BytesBuilder();
    builder.add(utf8.encode(source));
    if (stream != null) {
      builder.add(utf8.encode('stream\n'));
      builder.add(stream);
      builder.add(utf8.encode('\nendstream'));
    }
    builder.add(utf8.encode('\nendobj\n'));
    objects.add(builder.toBytes());
  }

  final kids = <String>[];
  var id = 3;
  final pageIds = <int>[];
  for (var index = 0; index < pages.length; index++) {
    pageIds.add(id);
    kids.add('$id 0 R');
    id += 3;
  }

  add('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\n');
  add('2 0 obj\n<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${pages.length} >>\n');

  id = 3;
  for (var index = 0; index < pages.length; index++) {
    final page = pages[index];
    final jpeg = jpegs[index];
    final pageId = id;
    final contentId = id + 1;
    final imageId = id + 2;
    final width = 540.0;
    final height = width * page.height / page.width;
    final content = 'q $width 0 0 $height 0 0 cm /Im0 Do Q';
    add(
      '$pageId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $width $height] '
      '/Contents $contentId 0 R /Resources << /XObject << /Im0 $imageId 0 R >> >> >>\n',
    );
    add(
      '$contentId 0 obj\n<< /Length ${utf8.encode(content).length} >>\n',
      utf8.encode(content),
    );
    add(
      '$imageId 0 obj\n<< /Type /XObject /Subtype /Image /Width ${page.width} /Height ${page.height} '
      '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\n',
      jpeg,
    );
    id += 3;
  }
  return _wrap(objects);
}

Uint8List _textPdf(String message) {
  final safe = message.replaceAll(RegExp(r'[^A-Za-z0-9 .,-]'), ' ');
  final content = 'BT /F1 16 Tf 48 720 Td ($safe) Tj ET';
  final objects = <Uint8List>[
    utf8.encode('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'),
    utf8.encode('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'),
    utf8.encode(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R '
      '/Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
    ),
    _streamObject(4, utf8.encode(content)),
    utf8.encode('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n'),
  ];
  return _wrap(objects);
}

Uint8List _streamObject(int id, Uint8List stream) {
  final builder = BytesBuilder();
  builder.add(utf8.encode('$id 0 obj\n<< /Length ${stream.length} >>\nstream\n'));
  builder.add(stream);
  builder.add(utf8.encode('\nendstream\nendobj\n'));
  return builder.toBytes();
}

Uint8List _wrap(List<Uint8List> objects) {
  final out = BytesBuilder();
  out.add(utf8.encode('%PDF-1.4\n'));
  final offsets = <int>[];
  for (final object in objects) {
    offsets.add(out.length);
    out.add(object);
  }
  final xref = out.length;
  final buffer = StringBuffer('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write('trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
  out.add(utf8.encode(buffer.toString()));
  return out.toBytes();
}
