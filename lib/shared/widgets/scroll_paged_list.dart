import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../config/breakpoints.dart';

/// Reveals [items] in batches of 10 as the list is scrolled to the end.
class ScrollPagedList<T> extends StatefulWidget {
  const ScrollPagedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = PaginationRules.pageSize,
    this.emptyMessage = '아직 항목이 없어요',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final String emptyMessage;

  @override
  State<ScrollPagedList<T>> createState() => _ScrollPagedListState<T>();
}

class _ScrollPagedListState<T> extends State<ScrollPagedList<T>> {
  final _controller = ScrollController();
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    _visible = _initialVisible;
    _controller.addListener(_onScroll);
  }

  int get _initialVisible {
    if (widget.items.isEmpty) return 0;
    return widget.pageSize.clamp(1, widget.items.length);
  }

  @override
  void didUpdateWidget(covariant ScrollPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length < _visible) {
      _visible = widget.items.length;
    } else if (oldWidget.items.isEmpty && widget.items.isNotEmpty) {
      _visible = _initialVisible;
    }
  }

  void _onScroll() {
    if (!_controller.hasClients || _visible >= widget.items.length) return;
    final position = _controller.position;
    if (position.extentAfter > 96) return;
    final next = (_visible + widget.pageSize).clamp(0, widget.items.length);
    if (next == _visible) return;
    setState(() => _visible = next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: GoogleFonts.notoSansKr(color: AppTheme.muted),
        ),
      );
    }

    final shown = widget.items.take(_visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            controller: _controller,
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return widget.itemBuilder(context, shown[index], index);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_visible / ${widget.items.length} · ${widget.pageSize}개씩',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}
