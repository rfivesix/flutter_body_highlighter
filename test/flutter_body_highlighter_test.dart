import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import 'package:flutter_body_highlighter/src/svg_path_parser.dart';

void main() {
  group('BodyPartSlug Tests', () {
    test('fromString should parse various formats correctly', () {
      expect(BodyPartSlug.fromString('chest'), BodyPartSlug.chest);
      expect(BodyPartSlug.fromString('pecs'), BodyPartSlug.chest);
      expect(BodyPartSlug.fromString('upper-back'), BodyPartSlug.upperBack);
      expect(BodyPartSlug.fromString('upperback'), BodyPartSlug.upperBack);
      expect(BodyPartSlug.fromString('GLUTES'), BodyPartSlug.gluteal);
      expect(BodyPartSlug.fromString('front-deltoids'), BodyPartSlug.frontDeltoids);
      expect(BodyPartSlug.fromString('rear-delt'), BodyPartSlug.backDeltoids);
      expect(BodyPartSlug.fromString('non-existent'), isNull);
    });

    test('slug getter should return standard kebab-case strings', () {
      expect(BodyPartSlug.chest.slug, 'chest');
      expect(BodyPartSlug.upperBack.slug, 'upper-back');
      expect(BodyPartSlug.frontDeltoids.slug, 'front-deltoids');
      expect(BodyPartSlug.gluteal.slug, 'gluteal');
    });
  });

  group('SvgPathParser Tests', () {
    test('Should parse basic M, L, H, V, Z commands', () {
      const pathData = 'M 10 20 L 30 40 H 50 V 60 Z';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
      expect(path.getBounds(), Rect.fromLTWH(10, 20, 40, 40));
    });

    test('Should parse relative m, l, h, v, z commands', () {
      const pathData = 'm 10 10 l 10 10 h 10 v 10 z';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
      expect(path.getBounds(), Rect.fromLTWH(10, 10, 20, 20));
    });

    test('Should parse cubic bezier C and c commands', () {
      const pathData = 'M 0 0 C 10 10 20 10 30 0 c 10 -10 20 -10 30 0';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
      expect(path.getBounds().left, closeTo(0, 0.001));
      expect(path.getBounds().right, closeTo(60, 0.001));
    });

    test('Should parse quadratic bezier Q and q commands', () {
      const pathData = 'M 0 0 Q 15 15 30 0 q 15 -15 30 0';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
      expect(path.getBounds().left, closeTo(0, 0.001));
      expect(path.getBounds().right, closeTo(60, 0.001));
    });

    test('Should parse arc A/a commands', () {
      const pathData = 'M 80 80 A 45 45 0 0 0 125 125 a 45 45 0 0 1 -45 -45';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
    });

    test('Should handle implicit repeated arguments correctly', () {
      const pathData = 'M 10 20 30 40 L 50 60 70 80';
      final path = SvgPathParser.parse(pathData);
      expect(path, isNotNull);
      expect(path.getBounds(), Rect.fromLTWH(10, 20, 60, 60));
    });
  });

  group('BodyHighlighter Widget Tests', () {
    testWidgets('Should instantiate and render male front view successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BodyHighlighter(
              gender: BodyGender.male,
              side: BodySide.front,
              highlightedParts: const [
                BodyPartHighlightData(slug: BodyPartSlug.chest, intensity: 4),
                BodyPartHighlightData(slug: BodyPartSlug.quadriceps, intensity: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BodyHighlighter), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BodyHighlighter), matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
    });

    testWidgets('Should instantiate and render female back view successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BodyHighlighter(
              gender: BodyGender.female,
              side: BodySide.back,
              highlightedParts: const [
                BodyPartHighlightData(slug: BodyPartSlug.gluteal, color: Colors.purple),
                BodyPartHighlightData(slug: BodyPartSlug.hamstring, intensity: 5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BodyHighlighter), findsOneWidget);
    });

    testWidgets('Tapping on mapped body parts should invoke callback', (WidgetTester tester) async {
      BodyPartSlug? tappedSlug;
      BodyPartHighlightData? tappedHighlight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 720,
                child: BodyHighlighter(
                  gender: BodyGender.male,
                  side: BodySide.front,
                  highlightedParts: const [
                    BodyPartHighlightData(slug: BodyPartSlug.chest, intensity: 4),
                  ],
                  onBodyPartTap: (slug, highlight) {
                    tappedSlug = slug;
                    tappedHighlight = highlight;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(BodyHighlighter), findsOneWidget);

      // Standard Chest coordinates in 724x1448 viewBox are around center-top.
      // Under a 360x720 (clamped to 360x600 in test environment constraints) widget size,
      // the chest is vertically centered around y = 160.
      // Let's tap the chest area!
      // In the 800x600 test window, the 360-wide widget is centered, starting at x = 220.
      // The left chest is locally at x = 145, y = 155, which is globally x = 365, y = 155.
      await tester.tapAt(const Offset(365, 155));
      await tester.pump();

      // Verify callback triggered for chest
      expect(tappedSlug, isNotNull);
      expect(tappedSlug, BodyPartSlug.chest);
      expect(tappedHighlight, isNotNull);
      expect(tappedHighlight!.slug, BodyPartSlug.chest);
      expect(tappedHighlight!.intensity, 4);
    });
  });
}
