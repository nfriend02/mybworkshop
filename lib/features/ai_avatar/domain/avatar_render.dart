import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum AvatarStyle { pastel, pixel, line, sticker }

const Map<AvatarStyle, String> kAvatarStyleLabels = {
  AvatarStyle.pastel: '파스텔',
  AvatarStyle.pixel: '픽셀',
  AvatarStyle.line: '라인',
  AvatarStyle.sticker: '스티커',
};

AvatarStyle avatarStyleFromName(String name) {
  for (final entry in kAvatarStyleLabels.entries) {
    if (entry.value == name || entry.key.name == name.trim().toLowerCase()) {
      return entry.key;
    }
  }
  return AvatarStyle.pastel;
}

Uint8List renderAvatar(Uint8List bytes, AvatarStyle style) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('사진을 읽지 못했어요');
  }
  final square = _square(decoded, 480);
  final styled = switch (style) {
    AvatarStyle.pastel => _border(square, img.ColorRgb8(255, 194, 212)),
    AvatarStyle.pixel => _pixel(square),
    AvatarStyle.line => _gray(square),
    AvatarStyle.sticker => _sticker(square),
  };
  return img.encodePng(styled);
}

img.Image _square(img.Image src, int size) {
  final side = src.width < src.height ? src.width : src.height;
  final x = ((src.width - side) / 2).round();
  final y = ((src.height - side) / 2).round();
  final cropped = img.copyCrop(src, x: x, y: y, width: side, height: side);
  return img.copyResize(cropped, width: size, height: size, interpolation: img.Interpolation.average);
}

img.Image _gray(img.Image src) {
  final copy = img.Image.from(src);
  for (final pixel in copy) {
    final tone = (0.3 * pixel.r + 0.59 * pixel.g + 0.11 * pixel.b).round();
    pixel
      ..r = tone
      ..g = tone
      ..b = tone;
  }
  return copy;
}

img.Image _pixel(img.Image src) {
  final tiny = img.copyResize(src, width: 32, height: 32, interpolation: img.Interpolation.average);
  final big = img.copyResize(tiny, width: src.width, height: src.height, interpolation: img.Interpolation.nearest);
  return _border(big, img.ColorRgb8(185, 166, 255));
}

img.Image _sticker(img.Image src) {
  final output = img.Image(width: src.width, height: src.height, numChannels: 4);
  img.fill(output, color: img.ColorRgba8(255, 247, 251, 0));
  final radius = src.width ~/ 2;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final dx = x - radius;
      final dy = y - radius;
      if (dx * dx + dy * dy <= radius * radius) {
        output.setPixel(x, y, src.getPixel(x, y));
      }
    }
  }
  for (var band = 0; band < 12; band++) {
    img.drawCircle(
      output,
      x: radius,
      y: radius,
      radius: radius - 4 - band,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  return output;
}

img.Image _border(img.Image src, img.Color color) {
  final framed = img.Image.from(src);
  img.drawRect(
    framed,
    x1: 8,
    y1: 8,
    x2: framed.width - 9,
    y2: framed.height - 9,
    color: color,
    thickness: 14,
  );
  return framed;
}
