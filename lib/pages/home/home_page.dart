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

const _starterFeed = <String>[
  '사진 세 장을 이어 깜빡이는 GIF를 만들어 보세요',
  '프로필 사진을 320px로 가볍게 줄여 보세요',
  '팀 이름 한 줄로 응원 GIF를 생성해 보세요',
  '발표 자료를 ZIP으로 묶어 용량을 확인해 보세요',
  '워크샵 주소로 QR 코드를 만들어 벽에 붙여 보세요',
  '440Hz 톤으로 박자를 맞추고 WAV로 저장해 보세요',
  '긴 회의록을 세 문장으로 요약해 보세요',
  '오늘의 기분을 밈 자막으로 남겨 보세요',
  '일주일 숫자를 막대 차트로 그려 보세요',
  '닉네임으로 나만의 파스텔 아바타를 뽑아 보세요',
  '마크다운 제목을 발표 슬라이드로 넘겨 보세요',
  '업로드 체크리스트로 전시 정보를 확인해 보세요',
];

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
        Text(
          '워크샵 피드',
          style: GoogleFonts.notoSansKr(
            fontWeight: FontWeight.w900,
            fontSize: 16,
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
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final firestore = context.read<FirestoreService?>();
    if (firestore == null) return;
    try {
      final rows = await firestore.listPage(
        collection: 'jobs',
        status: null,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _jobs = rows.map(WorkshopJob.fromMap).toList();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs;
    if (jobs != null && jobs.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Text(_error!, style: GoogleFonts.notoSansKr(color: AppTheme.coral)),
          Expanded(
            child: ScrollPagedList<WorkshopJob>(
              items: jobs,
              itemBuilder: (context, job, index) {
                return _FeedTile(
                  index: index,
                  title: job.title,
                  subtitle: job.tool,
                );
              },
            ),
          ),
        ],
      );
    }

    return ScrollPagedList<String>(
      items: _starterFeed,
      emptyMessage: '아직 피드가 없어요',
      itemBuilder: (context, tip, index) {
        return _FeedTile(index: index, title: tip, subtitle: '스타터 ${index + 1}');
      },
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
