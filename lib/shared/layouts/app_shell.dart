import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../config/breakpoints.dart';
import '../config/workshop_catalog.dart';
import '../widgets/workshop_logo.dart';

/// Desktop (≥769): left sidebar + main content.
/// Mobile (≤768): top navigation + main content.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: DecoratedBox(
        decoration: AppTheme.pageBackground(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = Breakpoints.isDesktop(constraints.maxWidth);
            if (desktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Sidebar(location: location),
                  Expanded(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: WorkshopLogo(compact: true),
                  ),
                  _MobileNav(key: const Key('mobile-nav'), location: location),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = [kHomeTool, ...kWorkshopTools];
    return Container(
      key: const Key('desktop-sidebar'),
      width: 248,
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: WorkshopLogo(compact: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                children: [
                  for (final tool in items)
                    _NavTile(tool: tool, location: location),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _NavTile(tool: kUploadTool, location: location),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final items = [kHomeTool, ...kWorkshopTools, kUploadTool];
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _twoRows(items, constraints.maxWidth - 24);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
          child: Column(
            children: [
              _chipLine(rows[0], 'mobile-nav-top'),
              const SizedBox(height: 6),
              _chipLine(rows[1], 'mobile-nav-bottom'),
            ],
          ),
        );
      },
    );
  }

  Widget _chipLine(List<WorkshopTool> tools, String bandKey) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        key: Key(bandKey),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < tools.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              _NavChip(
                key: Key('mobile-nav-${tools[index].path}'),
                tool: tools[index],
                location: location,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double _chipExtent(WorkshopTool tool) {
  final painter = TextPainter(
    text: TextSpan(
      text: tool.label,
      style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 12.5),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + 58;
}

/// Fills the upper row with chips that fit, and keeps every remaining menu on the lower row.
List<List<WorkshopTool>> _twoRows(List<WorkshopTool> items, double available) {
  final width = available.isFinite && available > 0 ? available : 360.0;
  var used = 0.0;
  var split = items.length;
  for (var index = 0; index < items.length; index++) {
    final next = used + _chipExtent(items[index]);
    if (next > width && index > 0) {
      split = index;
      break;
    }
    used = next;
  }
  if (split >= items.length) split = (items.length / 2).ceil();
  return [items.sublist(0, split), items.sublist(split)];
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.tool, required this.location});

  final WorkshopTool tool;
  final String location;

  @override
  Widget build(BuildContext context) {
    final selected = _selected(tool, location);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? tool.color : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(tool.path),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Text(tool.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tool.label,
                    style: GoogleFonts.notoSansKr(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({super.key, required this.tool, required this.location});

  final WorkshopTool tool;
  final String location;

  @override
  Widget build(BuildContext context) {
    final selected = _selected(tool, location);
    return Material(
      color: selected ? tool.color : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => context.go(tool.path),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tool.color : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tool.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                tool.label,
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _selected(WorkshopTool tool, String location) {
  if (tool.path == '/') return location == '/';
  return location == tool.path || location.startsWith('${tool.path}/');
}
