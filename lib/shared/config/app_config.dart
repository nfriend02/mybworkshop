import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide config from `.env` / Netlify environment variables.
class AppConfig {
  static const String defaultTitle = 'My AI Workshop';
  static const String defaultDescription =
      'GIF 편집, 리사이즈, GIF 생성, 문서 압축, QR, 오디오, 요약, 밈, 차트, AI 아바타, 마크다운 발표를 담은 밝고 즐거운 파스텔 AI 워크샵.';
  static const String defaultAuthor = 'MyBranch Team';
  static const String defaultIconUrl = '/icons/Icon-512.png';
  static const String defaultGithubUrl =
      'https://github.com/nfriend02/mybworkshop';
  static const String defaultNetlifyUrl = 'https://mybaiworkshop.netlify.app';

  static String get apiPrefix => '/api';

  static String get title => _env('APP_TITLE', defaultTitle);

  static String get description {
    final value = _env('APP_DESCRIPTION', defaultDescription);
    if (value.length <= 200) return value;
    return '${value.substring(0, 197)}...';
  }

  static String get author => _env('APP_AUTHOR', defaultAuthor);

  static String get iconUrl => _env('APP_ICON_URL', defaultIconUrl);

  static String get githubBranchUrl =>
      _env('GITHUB_BRANCH_URL', defaultGithubUrl);

  static String get netlifySiteUrl =>
      _env('NETLIFY_SITE_URL', defaultNetlifyUrl);

  static String? get openWeatherApiKey => _secret('OPENWEATHER_API_KEY');

  static String? get exchangeRateApiKey => _secret('EXCHANGE_RATE_API_KEY');

  static String? get geminiApiKey => _secret('GEMINI_API_KEY');

  /// `.env.example` uses `YOUR_GOOGLE_MAPS_API_KEY`. `GOOGLE_MAPS_API_KEY` also works.
  static String? get googleMapsApiKey =>
      _secret('YOUR_GOOGLE_MAPS_API_KEY') ?? _secret('GOOGLE_MAPS_API_KEY');

  static String get geminiModel => _env('GEMINI_MODEL', 'gemini-3.6-flash');

  static bool get hasGeminiKey => geminiApiKey != null;

  static bool get hasOpenWeatherKey => openWeatherApiKey != null;

  static bool get hasExchangeRateKey => exchangeRateApiKey != null;

  static bool get hasGoogleMapsKey => googleMapsApiKey != null;

  /// Portfolio upload checklist (description is always ≤ 200 chars).
  static Map<String, String> uploadChecklistMeta() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'iconUrl': iconUrl,
      'githubBranchUrl': githubBranchUrl,
      'netlifySiteUrl': netlifySiteUrl,
    };
  }

  static String _env(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final value = _clean(dotenv.env[key]);
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static String? _secret(String key) {
    if (!dotenv.isInitialized) return null;
    final value = _clean(dotenv.env[key]);
    if (value == null || value.isEmpty || value.startsWith('your_')) {
      return null;
    }
    return value;
  }

  static String? _clean(String? raw) {
    if (raw == null) return null;
    return raw.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), '');
  }
}
