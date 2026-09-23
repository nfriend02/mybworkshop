import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../shared/config/app_config.dart';
import '../../shared/utils/pick_files.dart';
import '../../shared/widgets/feature_scaffold.dart';
import '../../shared/widgets/scroll_paged_list.dart';

class _UploadRow {
  const _UploadRow({
    required this.name,
    required this.size,
    required this.note,
  });

  final String name;
  final int size;
  final String note;
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _rows = <_UploadRow>[];
  bool _busy = false;
  String? _status;

  Future<void> _pick() async {
    final picked = await pickWorkshopFiles();
    if (!mounted || picked.isEmpty) return;
    final file = picked.first;
    final bytes = file.bytes;

    setState(() {
      _busy = true;
      _status = '기록 중…';
    });

    final meta = AppConfig.uploadChecklistMeta();
    var note = '로컬 준비 완료';
    final firestore = context.read<FirestoreService?>();
    if (firestore != null) {
      try {
        await firestore.addData('uploads', {
          'fileName': file.name,
          'size': bytes.length,
          'meta': meta,
        });
        note = 'Firestore 기록 완료';
      } catch (e) {
        note = '기록 실패: $e';
      }
    } else {
      note = '데모 모드 · 메타데이터만 화면에 남아요';
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = note;
      _rows.insert(
        0,
        _UploadRow(name: file.name, size: bytes.length, note: note),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = AppConfig.uploadChecklistMeta();
    final firebaseReady = context.watch<bool>();
    final checks = <(String, String, bool)>[
      ('Github branch URL', meta['githubBranchUrl'] ?? '', (meta['githubBranchUrl'] ?? '').startsWith('http')),
      ('아이콘 이미지', meta['iconUrl'] ?? '', (meta['iconUrl'] ?? '').isNotEmpty),
      ('설명 200자 이내', '${(meta['description'] ?? '').length}/200', (meta['description'] ?? '').length <= 200),
      ('제작자 이름/팀명', meta['author'] ?? '', (meta['author'] ?? '').isNotEmpty),
      ('Firebase 연결', firebaseReady ? '연결됨' : '데모', firebaseReady),
    ];

    return FeatureScaffold(
      title: '업로드',
      subtitle: '전시 체크리스트와 파일 메타데이터',
      emoji: '☁️',
      accent: AppTheme.sky,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card(tint: AppTheme.sky),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta['title'] ?? AppConfig.defaultTitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(meta['description'] ?? '', style: GoogleFonts.notoSansKr()),
                const SizedBox(height: 12),
                for (final check in checks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          check.$3 ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: check.$3 ? const Color(0xFF2E9B6A) : AppTheme.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${check.$1} · ${check.$2}',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_busy ? '기록 중…' : '파일 선택 후 기록'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: GoogleFonts.notoSansKr(color: AppTheme.muted)),
          ],
          const SizedBox(height: 12),
          Text(
            '업로드 목록',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ScrollPagedList<_UploadRow>(
              items: _rows,
              emptyMessage: '아직 업로드한 파일이 없어요',
              itemBuilder: (context, row, index) {
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.sky,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(row.name, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
                  subtitle: Text('${row.size} bytes · ${row.note}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
