import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void playBytes(Uint8List bytes, String mime) {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final audio = web.HTMLAudioElement()..src = url;
  audio.play();
}
