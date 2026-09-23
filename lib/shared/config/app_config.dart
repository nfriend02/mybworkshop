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
  static const String defaultNetlifyUrl = 'https://mybworkshop.netlify.app';

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
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }
}
