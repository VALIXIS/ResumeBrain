import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/analysis/services/ats_engine.dart';
import 'package:resume_brain/features/analysis/widgets/ats_radar_chart.dart';
import 'package:resume_brain/features/analysis/widgets/ats_recommendation_card.dart';

void main() {
  group('AtsRadarChart & AtsRecommendationCard Widget Tests', () {
    final sampleReport = AtsScoreReport(
      overallScore: 85,
      impactVerbsScore: 90,
      formattingScore: 80,
      contactCompletenessScore: 100,
      keywordDensityScore: 70,
      recommendations: const [
        AtsRecommendation(
          id: 'rec_1',
          title: 'Replace Weak Bullet Openings',
          description: 'Replace passive phrases with strong action verbs.',
          dimension: AtsDimension.impactVerbs,
          priority: AtsPriority.high,
          isAiFixable: true,
          contextInfo: '1 passive bullet found',
        ),
      ],
    );

    testWidgets('AtsRadarChart renders 4 dimensions and overall score badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtsRadarChart(report: sampleReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ATS Dimension Radar'), findsOneWidget);
      expect(find.text('85/100'), findsOneWidget);
      expect(find.textContaining('Impact Verbs'), findsWidgets);
      expect(find.textContaining('Formatting'), findsWidgets);
      expect(find.textContaining('Contact Completeness'), findsWidgets);
      expect(find.textContaining('Keyword Density'), findsWidgets);
    });

    testWidgets('Tapping dimension chip triggers onDimensionSelected callback', (tester) async {
      AtsDimension? selectedDim;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtsRadarChart(
              report: sampleReport,
              onDimensionSelected: (dim) {
                selectedDim = dim;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chipFinder = find.widgetWithText(ChoiceChip, 'Impact Verbs: 90%');
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(selectedDim, equals(AtsDimension.impactVerbs));
    });

    testWidgets('AtsRecommendationCard expands and renders Fix with AI button', (tester) async {
      bool fixTriggered = false;

      final rec = sampleReport.recommendations.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtsRecommendationCard(
              recommendation: rec,
              initialExpanded: true,
              onFixWithAi: (_) {
                fixTriggered = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Replace Weak Bullet Openings'), findsOneWidget);
      expect(find.text('Replace passive phrases with strong action verbs.'), findsOneWidget);
      expect(find.text('CRITICAL FIX'), findsOneWidget);
      expect(find.text('Fix with AI'), findsOneWidget);

      await tester.tap(find.text('Fix with AI'));
      await tester.pumpAndSettle();

      expect(fixTriggered, isTrue);
    });
  });
}
