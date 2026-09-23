import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../utils/pick_files.dart';

class UploadDropZone extends StatefulWidget {
  const UploadDropZone({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPicked,
    this.multiple = false,
    this.type = FileType.any,
    this.accent = AppTheme.peach,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Future<void> Function(List<PickedBytes> files) onPicked;
  final bool multiple;
  final FileType type;
  final Color accent;

  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone> {
  var _over = false;
  var _busy = false;

  Future<void> _emit(List<PickedBytes> files) async {
    if (files.isEmpty || _busy) return;
    final batch = widget.multiple ? files : files.take(1).toList();
    setState(() => _busy = true);
    try {
      await widget.onPicked(batch);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final files = await pickWorkshopFiles(type: widget.type, multiple: widget.multiple);
    await _emit(files);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => _over = true),
          onDragExited: (_) => setState(() => _over = false),
          onDragDone: (detail) async {
            setState(() => _over = false);
            final picked = <PickedBytes>[];
            for (final file in detail.files) {
              picked.add(PickedBytes(name: file.name, bytes: await file.readAsBytes()));
            }
            await _emit(picked);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            decoration: BoxDecoration(
              color: _over ? widget.accent : const Color(0xFFFFFCFE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _over ? AppTheme.coral : AppTheme.border,
                width: 1.6,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _busy ? Icons.hourglass_top_rounded : Icons.cloud_upload_rounded,
                  color: AppTheme.coral,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.folder_open_rounded),
            label: Text(widget.buttonLabel),
          ),
        ),
      ],
    );
  }
}
