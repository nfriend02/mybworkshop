import 'dart:typed_data';

class WavPcm {
  const WavPcm({required this.sampleRate, required this.samples});

  final int sampleRate;
  final List<int> samples;

  static WavPcm? tryParse(Uint8List bytes) {
    if (bytes.length < 44) return null;
    if (String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') return null;
    if (String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') return null;

    var offset = 12;
    var sampleRate = 22050;
    var channels = 1;
    var bits = 16;
    Uint8List? data;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0, Endian.little);
      final start = offset + 8;
      final end = start + size;
      if (end > bytes.length) break;
      if (id == 'fmt ' && size >= 16) {
        final view = ByteData.sublistView(bytes, start, start + 16);
        channels = view.getUint16(2, Endian.little);
        sampleRate = view.getUint32(4, Endian.little);
        bits = view.getUint16(14, Endian.little);
      } else if (id == 'data') {
        data = Uint8List.sublistView(bytes, start, end);
      }
      offset = end + (size.isOdd ? 1 : 0);
    }
    if (data == null || bits != 16 || channels < 1) return null;

    final samples = <int>[];
    final view = ByteData.sublistView(data);
    final frames = data.length ~/ (2 * channels);
    for (var i = 0; i < frames; i++) {
      var mixed = 0;
      for (var channel = 0; channel < channels; channel++) {
        mixed += view.getInt16((i * channels + channel) * 2, Endian.little);
      }
      samples.add((mixed / channels).round().clamp(-32768, 32767));
    }
    if (samples.isEmpty) return null;
    return WavPcm(sampleRate: sampleRate, samples: samples);
  }

  Uint8List encode() {
    final count = samples.length;
    final dataSize = count * 2;
    final buffer = ByteData(44 + dataSize);
    void write(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        buffer.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    write(0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    write(8, 'WAVE');
    write(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    write(36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < count; i++) {
      buffer.setInt16(44 + i * 2, samples[i].clamp(-32768, 32767), Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  List<double> peaks(int bars) {
    final count = bars.clamp(8, 120);
    final size = (samples.length / count).ceil().clamp(1, samples.length);
    return [
      for (var i = 0; i < count; i++)
        () {
          var peak = 0;
          final start = i * size;
          final end = (start + size).clamp(0, samples.length);
          for (var j = start; j < end; j++) {
            final abs = samples[j].abs();
            if (abs > peak) peak = abs;
          }
          return peak / 32768;
        }(),
    ];
  }

  WavPcm compress() {
    final next = <int>[];
    for (var i = 0; i < samples.length; i += 2) {
      next.add(samples[i]);
    }
    return WavPcm(sampleRate: (sampleRate / 2).round().clamp(8000, 48000), samples: next);
  }

  WavPcm convert() => WavPcm(sampleRate: sampleRate, samples: List<int>.from(samples));

  WavPcm atSpeed(double rate) {
    final step = rate.clamp(0.5, 2.0);
    final next = <int>[];
    var cursor = 0.0;
    while (cursor < samples.length) {
      next.add(samples[cursor.floor()]);
      cursor += step;
    }
    return WavPcm(sampleRate: sampleRate, samples: next);
  }

  WavPcm atVolume(double gain) {
    final factor = gain.clamp(0, 2);
    return WavPcm(
      sampleRate: sampleRate,
      samples: [
        for (final sample in samples) (sample * factor).round().clamp(-32768, 32767),
      ],
    );
  }

  WavPcm denoise() {
    const window = 5;
    final smooth = List<int>.filled(samples.length, 0);
    for (var i = 0; i < samples.length; i++) {
      var sum = 0;
      var count = 0;
      for (var j = i - window; j <= i + window; j++) {
        if (j < 0 || j >= samples.length) continue;
        sum += samples[j];
        count++;
      }
      smooth[i] = count == 0 ? samples[i] : (sum / count).round();
    }
    return WavPcm(
      sampleRate: sampleRate,
      samples: [
        for (final sample in smooth) sample.abs() < 400 ? 0 : sample,
      ],
    );
  }
}
