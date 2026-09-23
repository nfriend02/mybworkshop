import 'dart:math' as math;
import 'dart:typed_data';

/// 16-bit mono PCM WAV.
Uint8List buildSineWav({
  required double frequencyHz,
  double seconds = 0.5,
  double volume = 0.35,
  int sampleRate = 22050,
}) {
  final count = (sampleRate * seconds).round().clamp(1, sampleRate * 8);
  final dataSize = count * 2;
  final buffer = ByteData(44 + dataSize);

  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + dataSize, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, 1, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little);
  buffer.setUint16(32, 2, Endian.little);
  buffer.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  buffer.setUint32(40, dataSize, Endian.little);

  final fade = sampleRate * 0.02;
  for (var i = 0; i < count; i++) {
    var envelope = 1.0;
    if (i < fade) envelope = i / fade;
    if (i > count - fade) envelope = (count - i) / fade;
    final sample = (math.sin(2 * math.pi * frequencyHz * i / sampleRate) *
            volume *
            envelope *
            32767)
        .round()
        .clamp(-32768, 32767);
    buffer.setInt16(44 + i * 2, sample, Endian.little);
  }
  return buffer.buffer.asUint8List();
}
