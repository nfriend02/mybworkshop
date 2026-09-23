import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../pages/ai_avatar/ai_avatar_page.dart';
import '../pages/audio_tools/audio_tools_page.dart';
import '../pages/data_visualizer/data_visualizer_page.dart';
import '../pages/document_compressor/document_compressor_page.dart';
import '../pages/gif_editor/gif_editor_page.dart';
import '../pages/gif_generator/gif_generator_page.dart';
import '../pages/home/home_page.dart';
import '../pages/image_resizer/image_resizer_page.dart';
import '../pages/markdown_presentation/markdown_presentation_page.dart';
import '../pages/meme_generator/meme_generator_page.dart';
import '../pages/qr_generator/qr_generator_page.dart';
import '../pages/text_summarizer/text_summarizer_page.dart';
import '../pages/upload/upload_page.dart';
import '../services/firestore_service.dart';
import '../shared/layouts/app_shell.dart';
import 'theme/app_theme.dart';

class MyBWorkshopApp extends StatefulWidget {
  const MyBWorkshopApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<MyBWorkshopApp> createState() => _MyBWorkshopAppState();
}

class _MyBWorkshopAppState extends State<MyBWorkshopApp> {
  late final FirestoreService? _firestore;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firebaseReady ? FirestoreService() : null;
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            location: state.uri.path,
            child: child,
          ),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomePage()),
            GoRoute(
              path: '/gif-editor',
              builder: (_, _) => const GifEditorPage(),
            ),
            GoRoute(
              path: '/image-resizer',
              builder: (_, _) => const ImageResizerPage(),
            ),
            GoRoute(
              path: '/gif-generator',
              builder: (_, _) => const GifGeneratorPage(),
            ),
            GoRoute(
              path: '/documents',
              builder: (_, _) => const DocumentCompressorPage(),
            ),
            GoRoute(path: '/qr', builder: (_, _) => const QrGeneratorPage()),
            GoRoute(path: '/audio', builder: (_, _) => const AudioToolsPage()),
            GoRoute(
              path: '/summarize',
              builder: (_, _) => const TextSummarizerPage(),
            ),
            GoRoute(path: '/meme', builder: (_, _) => const MemeGeneratorPage()),
            GoRoute(
              path: '/visualize',
              builder: (_, _) => const DataVisualizerPage(),
            ),
            GoRoute(path: '/avatar', builder: (_, _) => const AiAvatarPage()),
            GoRoute(
              path: '/slides',
              builder: (_, _) => const MarkdownPresentationPage(),
            ),
            GoRoute(path: '/upload', builder: (_, _) => const UploadPage()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<bool>.value(value: widget.firebaseReady),
        Provider<FirestoreService?>.value(value: _firestore),
      ],
      child: MaterialApp.router(
        title: 'My AI Workshop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
