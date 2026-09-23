import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import 'section_card.dart';

/// Source preview shown under the upload box until GO finishes.
class WaitingJobTile extends StatelessWidget {
  const WaitingJobTile({
    super.key,
    required this.name,
    this.preview,
    this.progress = 0,
    this.detail,
    this.trailing,
  });

  final String name;
  final Uint8List? preview;
  final double? progress;
  final String? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: preview == null
                ? const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.insert_drive_file_rounded),
                  )
                : Image.memory(preview!, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: GoogleFonts.notoSansKr(color: AppTheme.coral, fontSize: 12)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
