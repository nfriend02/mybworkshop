import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mybworkshop/app/app.dart';
import 'package:mybworkshop/shared/config/app_config.dart';
import 'package:mybworkshop/shared/config/breakpoints.dart';
import 'package:mybworkshop/shared/widgets/scroll_paged_list.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('portfolio description stays within 200 characters', () {
    expect(AppConfig.defaultDescription.length, lessThanOrEqualTo(200));
    expect(AppConfig.defaultDescription, isNotEmpty);
    expect(AppConfig.defaultAuthor, isNotEmpty);
  });

  test('desktop breakpoint starts at 769px', () {
    expect(Breakpoints.isMobile(768), isTrue);
    expect(Breakpoints.isDesktop(768), isFalse);
    expect(Breakpoints.isDesktop(769), isTrue);
    expect(PaginationRules.pageSize, 10);
  });

  testWidgets('scroll pagination reveals the next 10 items', (tester) async {
    final items = [for (var i = 1; i <= 12; i++) 'Item $i'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: ScrollPagedList<String>(
              items: items,
              itemBuilder: (_, item, _) => SizedBox(
                height: 48,
                child: Text(item),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('10 / 12 · 10개씩'), findsOneWidget);
    expect(find.text('Item 12'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();

    expect(find.text('12 / 12 · 10개씩'), findsOneWidget);
  });

  testWidgets('home renders the workshop wordmark', (tester) async {
    await tester.pumpWidget(const MyBWorkshopApp(firebaseReady: false));
    await tester.pump();
    expect(find.text('My AI Workshop'), findsWidgets);
    expect(find.text('나의 AI 워크샵'), findsWidgets);
    expect(find.text('GIF 편집기'), findsWidgets);
    expect(find.text('Work History'), findsOneWidget);
    expect(find.text('기록 삭제'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('gif editor page shows the upload box', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyBWorkshopApp(firebaseReady: false));
    await tester.pump();
    await tester.tap(find.text('GIF 편집기').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GIF Editor'), findsOneWidget);
    expect(find.text('Select File'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('layout switches at the desktop breakpoint', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    tester.view.physicalSize = const Size(1100, 800);
    await tester.pumpWidget(const MyBWorkshopApp(firebaseReady: false));
    await tester.pump();
    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('mobile-nav')), findsNothing);

    tester.view.physicalSize = const Size(390, 800);
    await tester.pumpWidget(const MyBWorkshopApp(firebaseReady: false));
    await tester.pump();
    expect(find.byKey(const Key('mobile-nav')), findsOneWidget);
    expect(find.byKey(const Key('mobile-nav-top')), findsOneWidget);
    expect(find.byKey(const Key('mobile-nav-bottom')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsNothing);
    final home = tester.getTopLeft(find.byKey(const Key('mobile-nav-/')));
    final upload = tester.getTopLeft(find.byKey(const Key('mobile-nav-/upload')));
    expect(upload.dy, greaterThan(home.dy));
    final documents = tester.getTopLeft(find.byKey(const Key('mobile-nav-/documents')));
    final qr = tester.getTopLeft(find.byKey(const Key('mobile-nav-/qr')));
    expect((documents.dy - qr.dy).abs(), lessThan(4));
    expect(qr.dx, greaterThan(documents.dx));
    expect(tester.getSize(find.byKey(const Key('mobile-nav-bottom'))).height, 40);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
