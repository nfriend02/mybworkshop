import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GeminiAnswer {
  const GeminiAnswer({required this.text, this.imageBytes, this.usedFallback = false});

  final String text;
  final Uint8List? imageBytes;
  final bool usedFallback;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
}

/// Shared Gemini client. Every feature calls this with its own instruction.
class GeminiClient {
  GeminiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const missingKeyMessage =
      'Gemini API 키가 아직 없어요. .env 또는 Netlify의 GEMINI_API_KEY에 키를 넣으면 이 창이 바로 호출해요.';

  Future<GeminiAnswer> ask({
    required String request,
    required String instruction,
    bool json = false,
    Uint8List? attachment,
    String mimeType = 'image/png',
    bool wantImage = false,
  }) async {
    final key = AppConfig.geminiApiKey;
    if (key == null) {
      return const GeminiAnswer(text: missingKeyMessage, usedFallback: true);
    }

    final trimmed = request.trim();
    if (trimmed.isEmpty && attachment == null) {
      return const GeminiAnswer(text: '요청 문장을 먼저 입력해 주세요.');
    }

    final models = <String>{
      if (wantImage) 'gemini-2.5-flash-image',
      if (wantImage) 'gemini-2.0-flash-preview-image-generation',
      AppConfig.geminiModel,
      'gemini-flash-latest',
      'gemini-2.0-flash',
      'gemini-2.5-flash',
    };

    final parts = <Map<String, dynamic>>[
      {'text': '$instruction\n\n사용자 요청:\n$trimmed'},
    ];
    if (attachment != null && attachment.isNotEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType,
          'data': base64Encode(attachment),
        },
      });
    }

    Object? lastError;
    for (final model in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$key',
        );
        final generation = <String, dynamic>{'temperature': wantImage ? 0.8 : 0.4};
        if (json && !wantImage) {
          generation['responseMimeType'] = 'application/json';
        }
        if (wantImage) {
          generation['responseModalities'] = ['TEXT', 'IMAGE'];
        }

        final res = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {'role': 'user', 'parts': parts},
                ],
                'generationConfig': generation,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 404) continue;
        if (res.statusCode >= 400) {
          debugPrint('Gemini $model HTTP ${res.statusCode}');
          lastError = 'Gemini 응답 ${res.statusCode}';
          continue;
        }

        final body = jsonDecode(res.body);
        if (body is! Map<String, dynamic>) continue;
        final parsed = _readParts(body);
        if (parsed.text.trim().isEmpty && parsed.imageBytes == null) continue;
        return parsed;
      } catch (error) {
        debugPrint('Gemini $model failed');
        lastError = error;
      }
    }

    return GeminiAnswer(
      text: 'Gemini 호출에 실패했어요. ${lastError ?? '잠시 뒤 다시 시도해 주세요.'}',
      usedFallback: true,
    );
  }

  GeminiAnswer _readParts(Map<String, dynamic> body) {
    final buffer = StringBuffer();
    Uint8List? image;
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return const GeminiAnswer(text: 'Gemini가 빈 응답을 보냈어요.');
    }
    final first = candidates.first;
    if (first is! Map) {
      return const GeminiAnswer(text: 'Gemini 응답 형식을 읽지 못했어요.');
    }
    final content = first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) {
      return const GeminiAnswer(text: 'Gemini 응답에 내용이 없어요.');
    }
    for (final part in parts) {
      if (part is! Map) continue;
      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(text.trim());
      }
      final inline = part['inlineData'] ?? part['inline_data'];
      if (inline is Map) {
        final data = inline['data'];
        if (data is String && data.isNotEmpty) {
          image = base64Decode(data);
        }
      }
    }
    return GeminiAnswer(text: buffer.toString(), imageBytes: image);
  }
}
