import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/resume/widgets/reorderable_section_card.dart';

void main() {
  group('ReorderableSectionCard.reorderList Unit Tests', () {
    final originalItems = ['Alpha', 'Beta', 'Gamma', 'Delta'];

    test('Moving item downward recalculates index correctly (oldIndex < newIndex)', () {
      // Flutter ReorderableListView gives newIndex = 3 when dragging index 0 past index 2
      final reordered = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 0,
        newIndex: 3,
        enableHaptics: false,
      );

      // 'Alpha' should now be at index 2 (between Gamma and Delta)
      expect(reordered, equals(['Beta', 'Gamma', 'Alpha', 'Delta']));
    });

    test('Moving item upward places item directly at newIndex (oldIndex > newIndex)', () {
      // Dragging Delta (index 3) to the top (index 0)
      final reordered = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 3,
        newIndex: 0,
        enableHaptics: false,
      );

      expect(reordered, equals(['Delta', 'Alpha', 'Beta', 'Gamma']));
    });

    test('Identical indices or adjacent downward move that resolves to same index is a no-op', () {
      final sameIndex = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 1,
        newIndex: 1,
        enableHaptics: false,
      );
      expect(sameIndex, equals(originalItems));

      // In Flutter, dragging index 1 right below index 1 passes newIndex 2 -> 2 - 1 = 1 (same)
      final adjacent = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 1,
        newIndex: 2,
        enableHaptics: false,
      );
      expect(adjacent, equals(originalItems));
    });

    test('Clamps boundary cases safely without RangeError', () {
      // Beyond end of list
      final pastEnd = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 1,
        newIndex: 99,
        enableHaptics: false,
      );
      expect(pastEnd.last, equals('Beta'));

      // Negative newIndex
      final negative = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 2,
        newIndex: -10,
        enableHaptics: false,
      );
      expect(negative.first, equals('Gamma'));

      // Invalid oldIndex returns unmodified list
      final invalidOld = ReorderableSectionCard.reorderList<String>(
        list: originalItems,
        oldIndex: 99,
        newIndex: 0,
        enableHaptics: false,
      );
      expect(invalidOld, equals(originalItems));
    });
  });

  group('CustomSection Persistence Across App Launches Tests', () {
    test('CustomSection retains explicit order field in toMap and fromMap serialization', () {
      final sec1 = CustomSection(id: 's1', title: 'Patents', items: ['US Patent 12345'], order: 2);
      final sec2 = CustomSection(id: 's2', title: 'Speaking Engagements', items: ['Keynote at FlutterCon'], order: 0);
      final sec3 = CustomSection(id: 's3', title: 'Open Source', items: ['Maintained Riverpod tooling'], order: 1);

      expect(sec1.toMap()['order'], equals(2));
      expect(sec2.toMap()['order'], equals(0));
      expect(sec3.toMap()['order'], equals(1));

      final restored1 = CustomSection.fromMap(sec1.toMap());
      expect(restored1.order, equals(2));
      expect(restored1.title, equals('Patents'));

      final restored2 = CustomSection.fromMap(sec2.toMap());
      expect(restored2.order, equals(0));

      final restored3 = CustomSection.fromMap(sec3.toMap());
      expect(restored3.order, equals(1));
    });

    test('Resume.fromMap automatically restores user-ordered custom sections across app restarts', () {
      // Simulating a resume saved after user reordered:
      // Index 0: Open Source (order: 0)
      // Index 1: Patents (order: 1)
      // Index 2: Speaking Engagements (order: 2)
      final resumeMap = {
        'schemaVersion': 1,
        'id': 'persisted-resume-1',
        'title': 'Senior Engineer Resume',
        // In raw JSON / Hive, sections might be serialized or deserialized in arbitrary map iteration order
        'customSections': [
          {'id': 's-patents', 'title': 'Patents', 'items': ['Patent A'], 'order': 1},
          {'id': 's-speaking', 'title': 'Speaking', 'items': ['Talk B'], 'order': 2},
          {'id': 's-opensource', 'title': 'Open Source', 'items': ['Library C'], 'order': 0},
        ],
      };

      // App launch simulation: Resume.fromMap parses and restores state from storage
      final loadedResume = Resume.fromMap(resumeMap);

      expect(loadedResume.customSections.length, equals(3));
      // Verify exact user-ordered positions are strictly preserved:
      expect(loadedResume.customSections[0].title, equals('Open Source'));
      expect(loadedResume.customSections[0].order, equals(0));

      expect(loadedResume.customSections[1].title, equals('Patents'));
      expect(loadedResume.customSections[1].order, equals(1));

      expect(loadedResume.customSections[2].title, equals('Speaking'));
      expect(loadedResume.customSections[2].order, equals(2));
    });

    test('Reordering custom sections and persisting updates preserves new order on subsequent reload', () {
      final originalSections = [
        CustomSection(id: '1', title: 'Section A', order: 0),
        CustomSection(id: '2', title: 'Section B', order: 1),
        CustomSection(id: '3', title: 'Section C', order: 2),
      ];

      // User drags Section C (index 2) to top (newIndex 0)
      final reordered = ReorderableSectionCard.reorderList<CustomSection>(
        list: originalSections,
        oldIndex: 2,
        newIndex: 0,
        enableHaptics: false,
      );

      // Re-index order numbers sequentially
      final savedSections = reordered
          .asMap()
          .entries
          .map((e) => e.value.copyWith(order: e.key))
          .toList();

      final initialResume = Resume(id: 'r1', title: 'Test', customSections: savedSections);
      final rawStorage = initialResume.toMap();

      // Simulate killing and reopening the app:
      final restartedResume = Resume.fromMap(rawStorage);

      expect(restartedResume.customSections[0].title, equals('Section C'));
      expect(restartedResume.customSections[1].title, equals('Section A'));
      expect(restartedResume.customSections[2].title, equals('Section B'));
    });
  });
}
