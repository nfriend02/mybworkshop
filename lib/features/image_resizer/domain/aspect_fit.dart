import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

enum FitMode { padding, crop }

class AspectChoice {
  const AspectChoice(this.label, this.widthOverHeight);

  final String label;
  final double? widthOverHeight;

  bool get isCustom => widthOverHeight == null;
}

const List<AspectChoice> kAspectChoices = [
  AspectChoice('1:1', 1),
  AspectChoice('3:4', 3 / 4),
  AspectChoice('4:3', 4 / 3),
  AspectChoice('9:16', 9 / 16),
  AspectChoice('16:9', 16 / 9),
  AspectChoice('Custom', null),
];

bool isImageName(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}

(int, int) boxForAspect(double aspect, {int longSide = 1080}) {
  final ratio = aspect.clamp(0.2, 5);
  if (ratio >= 1) {
    return (longSide, (longSide / ratio).round().clamp(8, longSide));
  }
  return ((longSide * ratio).round().clamp(8, longSide), longSide);
}

Uint8List fitToBox(
  Uint8List bytes, {
  required int width,
  required int height,
  required FitMode mode,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('이미지를 읽지 못했어요');
  }
  final tw = width.clamp(8, 4096);
  final th = height.clamp(8, 4096);
  final fitted = mode == FitMode.crop
      ? _cover(decoded, tw, th)
      : _contain(decoded, tw, th);
  return img.encodePng(fitted);
}

img.Image _cover(img.Image src, int tw, int th) {
  final scale = math.max(tw / src.width, th / src.height);
  final rw = math.max(tw, (src.width * scale).round());
  final rh = math.max(th, (src.height * scale).round());
  final resized = img.copyResize(src, width: rw, height: rh);
  final x = ((rw - tw) / 2).round().clamp(0, rw - tw);
  final y = ((rh - th) / 2).round().clamp(0, rh - th);
  return img.copyCrop(resized, x: x, y: y, width: tw, height: th);
}

img.Image _contain(img.Image src, int tw, int th) {
  final scale = math.min(tw / src.width, th / src.height);
  final rw = math.max(1, (src.width * scale).round());
  final rh = math.max(1, (src.height * scale).round());
  final resized = img.copyResize(src, width: rw, height: rh);
  final canvas = img.Image(width: tw, height: th);
  img.fill(canvas, color: img.ColorRgb8(255, 247, 251));
  img.compositeImage(
    canvas,
    resized,
    dstX: ((tw - rw) / 2).round(),
    dstY: ((th - rh) / 2).round(),
  );
  return canvas;
}

class UnzippedImage {
  const UnzippedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

List<UnzippedImage> unzipImages(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final images = <UnzippedImage>[];
  for (final file in archive.files) {
    if (!file.isFile || !isImageName(file.name)) continue;
    final name = file.name.split('/').last;
    if (name.isEmpty) continue;
    images.add(UnzippedImage(name: name, bytes: file.content));
  }
  return images;
}
