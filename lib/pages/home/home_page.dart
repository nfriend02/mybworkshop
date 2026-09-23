import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../entities/workshop_job.dart';
import '../../services/firestore_service.dart';
import '../../shared/config/app_config.dart';
import '../../shared/config/workshop_catalog.dart';
import '../../shared/widgets/fun_feature_button.dart';
import '../../shared/widgets/scroll_paged_list.dart';
import '../../shared/widgets/workshop_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseReady = context.watch<bool>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              const SizedBox(height: 8),
              const WorkshopLogo(compact: false),
              const SizedBox(height: 8),
              Text(
                AppConfig.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (!firebaseReady) ...[
                const SizedBox(height: 12),
                const _DemoBanner(),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 980
                      ? 4
                      : width >= 680
                          ? 3
                          : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kWorkshopTools.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 138,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final tool = kWorkshopTools[index];
                      return FunFeatureButton(
                        index: index,
                        label: tool.label,
                        emoji: tool.emoji,
                        color: tool.color,
                        blurb: tool.blurb,
                        onTap: () => context.go(tool.path),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(flex: 2, child: _WorkshopFeed()),
      ],
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.butter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Firebase에 연결되지 않아 데모 모드로 열려 있어요. 도구는 그대로 쓸 수 있습니다.',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WorkshopFeed extends StatefulWidget {
  const _WorkshopFeed();

  @override
  State<_WorkshopFeed> createState() => _WorkshopFeedState();
}

class _WorkshopFeedState extends State<_WorkshopFeed> {
  List<WorkshopJob>? _jobs;
  final _selected = <String>{};
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      if (mounted) setState(() => _jobs = []);
      return;
    }
    try {
      final rows = await firestore.listPage(
        collection: 'jobs',
        status: null,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _jobs = rows.map(WorkshopJob.fromMap).toList();
        _selected.removeWhere((id) => !_jobs!.any((job) => job.id == id));
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _deleteChecked() async {
    final ids = _selected.toList();
    if (ids.isEmpty || _busy) return;
    final firestore = context.read<FirestoreService?>();
    if (firestore == null) return;
    setState(() => _busy = true);
    try {
      for (final id in ids) {
        await firestore.deleteData('jobs', id);
      }
      if (!mounted) return;
      setState(() {
        _jobs = _jobs?.where((job) => !_selected.contains(job.id)).toList();
        _selected.clear();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length}개 기록을 삭제했어요')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs;
    final canDelete = _selected.isNotEmpty && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Work History',
              style: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: canDelete ? _deleteChecked : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.coral,
                foregroundColor: Colors.white,
              ),
              child: Text(_busy ? '삭제 중' : '기록 삭제'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral)),
        Expanded(
          child: jobs == null
              ? const Center(child: CircularProgressIndicator())
              : ScrollPagedList<WorkshopJob>(
                  items: jobs,
                  emptyMessage: '아직 기록이 없어요',
                  itemBuilder: (context, job, index) {
                    return _FeedTile(
                      index: index,
                      title: job.title,
                      subtitle: _summary(job),
                      checked: _selected.contains(job.id),
                      onChecked: (checked) {
                        setState(() {
                          if (checked) {
                            _selected.add(job.id);
                          } else {
                            _selected.remove(job.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _summary(WorkshopJob job) {
  final detail = job.detail.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (detail.isNotEmpty) return detail;
  final tool = toolForPath('/${job.tool}');
  if (tool.path != '/') return tool.label;
  return job.tool;
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChecked,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChecked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: AppTheme.card(tint: AppTheme.lavender),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.lavender,
            child: Text(
              '${index + 1}',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: checked,
            onChanged: (value) => onChecked(value ?? false),
          ),
        ],
      ),
    );
  }
}
