import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Calls Netlify functions under the `/api` prefix.
class ApiClient {
  Future<String?> summarize(String text, {int sentences = 3}) async {
    try {
      final uri = Uri.base.replace(
        path: '${AppConfig.apiPrefix}/summarize',
        query: '',
      );
      final response = await http
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'text': text, 'sentences': sentences}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['summary'] is String) {
        return body['summary'] as String;
      }
    } catch (e) {
      debugPrint('api summarize skipped: $e');
    }
    return null;
  }

  Future<bool> health() async {
    try {
      final uri = Uri.base.replace(path: '${AppConfig.apiPrefix}/health', query: '');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
