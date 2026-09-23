import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/api/nlp_action.dart';
import '../../../shared/utils/download_file.dart';
import '../../../shared/utils/image_sniff.dart';
import '../../../shared/utils/pick_files.dart';
import '../../../shared/utils/record_job.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/go_button.dart';
import '../../../shared/widgets/nlp_request_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/upload_drop_zone.dart';
import '../../../shared/widgets/waiting_job_tile.dart';
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
  var _started = false;
  String? _note;

  Future<void> _load(List<PickedBytes> files) async {
    final file = files.first;
    final kind = imageKindOf(file.bytes, name: file.name, mimeType: file.mimeType);
    if (kind == ImageKind.heic || kind == ImageKind.unknown) {
      setState(() => _note = kind == ImageKind.heic ? heicUploadMessage : '이미지를 찾지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요');
      return;
    }
    setState(() {
      _photo = PickedBytes(name: ensureImageName(file.name, kind), bytes: file.bytes, mimeType: file.mimeType);
      _gemini = null;
      _local = null;
      _started = false;
      _note = null;
    });
  }

  Future<void> _make() async {
    final photo = _photo;
    if (photo == null || _busy) return;
    late final Uint8List rendered;
    try {
      rendered = renderAvatar(photo.bytes, _style);
    } catch (error) {
      setState(() => _note = '사진을 읽지 못했어요. PNG, JPG, GIF, WEBP를 올려 주세요');
      return;
    }
    setState(() {
      _busy = true;
      _started = true;
      _local = rendered;
      _note = null;
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
              final action = NlpAction.tryParse(answer.text);
              final style = avatarStyleFromName(action?.style ?? answer.text);
              setState(() {
                if (action != null && action.style.isNotEmpty) _style = style;
                _note = answer.text.trim().isEmpty ? null : answer.text.trim();
              });
            },
          ),
          const SizedBox(height: 12),
          UploadDropZone(
            title: '얼굴 사진을 놓아요',
            subtitle: '스타일을 고른 뒤 GO를 누르면 아바타가 나와요',
            buttonLabel: 'Select File',
            onPicked: _load,
            accent: const Color(0xFFF3D6FF),
            sideAction: GoButton(
              busy: _busy,
              onPressed: _photo == null ? null : _make,
            ),
          ),
          if (_photo != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in kAvatarStyleLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _style == entry.key,
                    onSelected: (_) => setState(() {
                      _style = entry.key;
                      _gemini = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_started)
              WaitingJobTile(name: _photo!.name, preview: _photo!.bytes, progress: 0),
          ],
          if (_started && preview != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(preview, height: 260, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  WaitingJobTile(
                    name: '아바타 · ${kAvatarStyleLabels[_style]}',
                    preview: preview,
                    progress: _busy ? null : 1,
                    trailing: IconButton(
                      tooltip: '다운로드',
                      onPressed: () => downloadFile(context, bytes: preview, filename: 'avatar.png', mimeType: 'image/png'),
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                  if (_note != null) ...[
                    const SizedBox(height: 8),
                    Text(_note!, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
          if (_photo == null && _note != null) ...[
            const SizedBox(height: 8),
            Text(_note!, style: GoogleFonts.notoSansKr(color: const Color(0xFFE36A6A), fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
