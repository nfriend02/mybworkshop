import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/utils/byte_label.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/scroll_paged_list.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/document_compress.dart';
import '../domain/gemini_bridge.dart';

class _Doc {
  _Doc({required this.name, required this.source});

  final String name;
  final PickedBytes source;
  double progress = 0;
  CompressedFile? output;
  String? blocked;
}

class DocumentCompressorView extends StatefulWidget {
  const DocumentCompressorView({super.key});

  @override
  State<DocumentCompressorView> createState() => _DocumentCompressorViewState();
}

class _DocumentCompressorViewState extends State<DocumentCompressorView> {
  final List<_Doc> _docs = [];

  Future<void> _load(List<PickedBytes> files) async {
    final docs = [for (final file in files) _Doc(name: file.name, source: file)];
    setState(() {
      _docs
        ..clear()
        ..addAll(docs);
    });
    for (final doc in docs) {
      setState(() => doc.progress = 0.4);
      await Future<void>.delayed(Duration.zero);
      try {
        doc.output = compressDocument(name: doc.source.name, bytes: doc.source.bytes);
        doc.progress = 1;
      } on HwpBlocked catch (error) {
        doc.blocked = error.message;
        doc.progress = 1;
      } catch (error) {
        doc.blocked = '$error';
        doc.progress = 1;
      }
      if (mounted) setState(() {});
    }
    final saved = docs.where((doc) => doc.output != null).length;
    if (!mounted || saved == 0) return;
    await recordJob(
      context,
      tool: 'document-compressor',
      title: '문서 압축',
      detail: '$saved개 _comp 저장',
      extra: {'status': 'done'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: '문서 압축',
      subtitle: '올리면 _comp 이름으로 바로 줄여요',
      emoji: '📦',
      accent: AppTheme.sky,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'document-compressor',
            hint: '예: 이 PDF를 더 가볍게 만들려면?',
            ask: askDocumentCompressor,
          ),
          const SizedBox(height: 12),
          UploadDropZone(
            title: '문서를 놓아요',
            subtitle: 'HWP는 받지 않아요. PDF나 Word로 바꾼 뒤 올려 주세요',
            buttonLabel: 'Select Files',
            multiple: true,
            onPicked: _load,
            accent: AppTheme.sky,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ScrollPagedList<_Doc>(
              items: _docs,
              emptyMessage: '아직 압축한 파일이 없어요',
              itemBuilder: (context, doc, index) => SectionCard(
                padding: const EdgeInsets.all(12),
                color: doc.blocked == null ? AppTheme.surface : AppTheme.butter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: doc.progress == 0 ? null : doc.progress),
                    const SizedBox(height: 6),
                    if (doc.blocked != null)
                      Text(doc.blocked!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, color: AppTheme.ink))
                    else if (doc.output != null) ...[
                      Text(
                        '${doc.output!.name} · ${byteLabel(doc.output!.bytes.length)} · ${doc.output!.note}',
                        style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => downloadFile(
                          context,
                          bytes: doc.output!.bytes,
                          filename: doc.output!.name,
                          mimeType: mimeForName(doc.output!.name),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('다운로드'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
