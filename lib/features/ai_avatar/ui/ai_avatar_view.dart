import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../domain/avatar_render.dart';
import '../domain/gemini_bridge.dart';

class AiAvatarView extends StatefulWidget {
  const AiAvatarView({super.key});

  @override
  State<AiAvatarView> createState() => _AiAvatarViewState();
}

class _AiAvatarViewState extends State<AiAvatarView> {
  PickedBytes? _photo;
  AvatarStyle _style = AvatarStyle.pastel;
  Uint8List? _local;
  Uint8List? _gemini;
  var _busy = false;
  String? _note;

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    setState(() {
      _photo = file;
      _gemini = null;
      _local = renderAvatar(file.bytes, _style);
    });
  }

  Future<void> _make() async {
    final photo = _photo;
    if (photo == null || _busy) return;
    setState(() {
      _busy = true;
      _local = renderAvatar(photo.bytes, _style);
    });
    try {
      final style = kAvatarStyleLabels[_style]!;
      final answer = await askAvatar(
        request: '이 사진을 $style 아바타로 만들어 주세요',
        style: style,
        photo: photo.bytes,
        filename: photo.name,
      );
      if (!mounted) return;
      setState(() {
        _gemini = answer.hasImage ? answer.imageBytes : null;
        _note = answer.text.trim().isEmpty ? null : answer.text.trim();
      });
      await recordJob(
        context,
        tool: 'ai-avatar',
        title: style,
        detail: photo.name,
        extra: {'request': style, 'result': answer.text, 'status': 'done'},
      );
    } catch (error) {
      if (mounted) setState(() => _note = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _gemini ?? _local;
    return FeatureScaffold(
      title: 'AI 아바타',
      subtitle: '사진을 올리고 스타일을 고르면 아바타가 나와요',
      emoji: '🧑‍🎨',
      accent: const Color(0xFFF3D6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NlpRequestBar(
            tool: 'ai-avatar',
            hint: '예: 스티커 스타일로 더 동글게',
            ask: (request) => askAvatar(
              request: request,
              style: kAvatarStyleLabels[_style]!,
              photo: _photo?.bytes,
              filename: _photo?.name ?? 'avatar.png',
            ),
            onAnswer: (answer) async {
              final style = avatarStyleFromName(answer.text);
              setState(() {
                if (kAvatarStyleLabels.containsValue(answer.text.trim())) {
                  _style = style;
                }
                if (answer.hasImage) _gemini = answer.imageBytes;
                _note = answer.text.trim().isEmpty ? null : answer.text.trim();
                if (_photo != null) _local = renderAvatar(_photo!.bytes, _style);
              });
            },
          ),
          const SizedBox(height: 12),
          if (_photo == null)
            UploadDropZone(
              title: '얼굴 사진을 놓아요',
              subtitle: '스타일을 고른 뒤 아바타를 만들어요',
              buttonLabel: 'Select File',
              onPicked: _load,
              accent: const Color(0xFFF3D6FF),
            )
          else ...[
            Wrap(
              spacing: 8,
              children: [
                for (final entry in kAvatarStyleLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _style == entry.key,
                    onSelected: (_) => setState(() {
                      _style = entry.key;
                      _local = renderAvatar(_photo!.bytes, _style);
                      _gemini = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (preview != null)
              SectionCard(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(preview, height: 260, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(onPressed: _busy ? null : _make, child: Text(_busy ? '만드는 중' : '아바타 만들기')),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => downloadFile(context, bytes: preview, filename: 'avatar.png', mimeType: 'image/png'),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('다운로드'),
                        ),
                      ],
                    ),
                    if (_note != null) ...[
                      const SizedBox(height: 8),
                      Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
