import 'dart:typed_data';

import '../../../shared/api/gemini_client.dart';
import '../../../shared/utils/byte_label.dart';

Future<GeminiAnswer> askMeme({
  required String request,
  Uint8List? image,
  String filename = 'meme.png',
}) {
  return GeminiClient().ask(
    request: request,
    wantImage: image != null,
    attachment: image,
    mimeType: mimeForName(filename),
    instruction:
        '밈 생성기입니다. 올린 사진과 문구로 밈 스타일 이미지를 만들고, 짧은 캡션을 함께 적어 주세요. '
        '이미지가 어려우면 위/아래 자막 문구만 JSON이 아닌 일반 문장으로 제안하세요.',
  );
}
