import '../../../shared/api/gemini_client.dart';

Future<GeminiAnswer> askQrGenerator(String request) {
  return GeminiClient().ask(
    request: request,
    json: true,
    instruction:
        'QR 생성기입니다. kind는 text, url, email, card, phone, event, app 중 하나입니다. '
        'JSON만 반환하세요. 예: {"tool":"qr","kind":"url","text":"https://mybaiworkshop.netlify.app","note":"사이트 주소로 만들게요"}',
  );
}
