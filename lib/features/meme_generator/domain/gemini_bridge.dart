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
        '밈 생성기입니다. 답변 본문에 반드시 아래 두 줄을 포함하세요.\n'
        '**상단 자막:** "윗줄에 넣을 문구"\n'
        '**하단 자막:** "아랫줄에 넣을 문구"\n'
        '사진이 있으면 밈 이미지도 함께 만드세요. JSON으로만 답하지 마세요.',
  );
}
