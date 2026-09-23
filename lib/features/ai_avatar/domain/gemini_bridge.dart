import 'dart:typed_data';

import '../../../shared/api/gemini_client.dart';
import '../../../shared/utils/byte_label.dart';

Future<GeminiAnswer> askAvatar({
  required String request,
  required String style,
  Uint8List? photo,
  String filename = 'avatar.png',
}) {
  return GeminiClient().ask(
    request: '$request\n스타일: $style',
    wantImage: photo != null,
    attachment: photo,
    mimeType: mimeForName(filename),
    instruction:
        '아바타 생성기입니다. 올린 사진을 $style 스타일의 아바타 이미지로 바꿔 주세요. '
        '얼굴의 인상은 유지하고 배경은 파스텔로 단순하게 만드세요.',
  );
}
