import '../../../shared/api/gemini_client.dart';

Future<GeminiAnswer> askDocumentCompressor(String request) {
  return GeminiClient().ask(
    request: request,
    instruction:
        '문서 압축기입니다. HWP는 받을 수 없고 PDF 또는 Word로 바꾼 뒤 올리라고 안내합니다. '
        'PDF는 페이지를 저화질로 다시 묶고, 이미지는 _comp 파일로 저장합니다. 한국어로 짧게 답하세요.',
  );
}
