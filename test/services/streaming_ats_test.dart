import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Representation of a streaming ATS analysis chunk.
class AtsStreamChunk {
  final String requestId;
  final double? partialScore;
  final String? sectionName;
  final List<String> newSuggestions;
  final bool isComplete;
  final String? errorMessage;

  AtsStreamChunk({
    required this.requestId,
    this.partialScore,
    this.sectionName,
    this.newSuggestions = const [],
    this.isComplete = false,
    this.errorMessage,
  });
}

/// Accumulation state for progressive streaming ATS feedback.
class AtsStreamingState {
  final String activeRequestId;
  final double currentScore;
  final List<String> accumulatedSuggestions;
  final Map<String, double> sectionScores;
  final bool isLoading;
  final String? error;

  AtsStreamingState({
    required this.activeRequestId,
    this.currentScore = 0.0,
    this.accumulatedSuggestions = const [],
    this.sectionScores = const {},
    this.isLoading = false,
    this.error,
  });

  AtsStreamingState copyWith({
    String? activeRequestId,
    double? currentScore,
    List<String>? accumulatedSuggestions,
    Map<String, double>? sectionScores,
    bool? isLoading,
    String? error,
  }) {
    return AtsStreamingState(
      activeRequestId: activeRequestId ?? this.activeRequestId,
      currentScore: currentScore ?? this.currentScore,
      accumulatedSuggestions: accumulatedSuggestions ?? this.accumulatedSuggestions,
      sectionScores: sectionScores ?? this.sectionScores,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Controller managing progressive ATS streaming state and concurrency guards.
class AtsStreamingController {
  AtsStreamingState _state;

  AtsStreamingController()
      : _state = AtsStreamingState(activeRequestId: '');

  AtsStreamingState get state => _state;

  void startNewRequest(String requestId) {
    _state = AtsStreamingState(
      activeRequestId: requestId,
      isLoading: true,
    );
  }

  void processChunk(AtsStreamChunk chunk) {
    // Concurrency Guard: Ignore stale response chunks from outdated requests
    if (chunk.requestId != _state.activeRequestId) {
      return;
    }

    if (chunk.errorMessage != null) {
      _state = _state.copyWith(
        isLoading: false,
        error: chunk.errorMessage,
      );
      return;
    }

    final updatedSuggestions = List<String>.from(_state.accumulatedSuggestions)
      ..addAll(chunk.newSuggestions);

    final updatedSections = Map<String, double>.from(_state.sectionScores);
    if (chunk.sectionName != null && chunk.partialScore != null) {
      updatedSections[chunk.sectionName!] = chunk.partialScore!;
    }

    _state = _state.copyWith(
      currentScore: chunk.partialScore ?? _state.currentScore,
      accumulatedSuggestions: updatedSuggestions,
      sectionScores: updatedSections,
      isLoading: !chunk.isComplete,
    );
  }
}

void main() {
  group('Streaming ATS Response & Instant Feedback QA Tests', () {
    late AtsStreamingController controller;

    setUp(() {
      controller = AtsStreamingController();
    });

    test('1. Processes single chunk and updates partial ATS score', () {
      controller.startNewRequest('req-101');
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-101',
          partialScore: 75.0,
          sectionName: 'Work Experience',
          newSuggestions: ['Quantify engineering impact'],
        ),
      );

      expect(controller.state.currentScore, equals(75.0));
      expect(controller.state.accumulatedSuggestions, contains('Quantify engineering impact'));
      expect(controller.state.sectionScores['Work Experience'], equals(75.0));
      expect(controller.state.isLoading, isTrue);
    });

    test('2. Processes multiple streaming chunks progressively until completion', () async {
      final streamController = StreamController<AtsStreamChunk>();
      controller.startNewRequest('req-202');

      final subscription = streamController.stream.listen((chunk) {
        controller.processChunk(chunk);
      });

      streamController.add(
        AtsStreamChunk(
          requestId: 'req-202',
          sectionName: 'Summary',
          partialScore: 80.0,
          newSuggestions: ['Strong summary statement'],
        ),
      );

      streamController.add(
        AtsStreamChunk(
          requestId: 'req-202',
          sectionName: 'Skills',
          partialScore: 90.0,
          newSuggestions: ['Add Flutter & Dart tags'],
          isComplete: true,
        ),
      );

      await streamController.close();
      await subscription.cancel();

      expect(controller.state.sectionScores['Summary'], equals(80.0));
      expect(controller.state.sectionScores['Skills'], equals(90.0));
      expect(controller.state.accumulatedSuggestions.length, equals(2));
      expect(controller.state.isLoading, isFalse);
    });

    test('3. Handles empty chunk safely without corrupting current ATS state', () {
      controller.startNewRequest('req-303');
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-303',
          partialScore: 82.0,
          newSuggestions: ['Initial tip'],
        ),
      );

      // Emit empty chunk
      controller.processChunk(
        AtsStreamChunk(requestId: 'req-303'),
      );

      expect(controller.state.currentScore, equals(82.0));
      expect(controller.state.accumulatedSuggestions, equals(['Initial tip']));
    });

    test('4. Handles stream error cleanly by updating error state and ending loading', () {
      controller.startNewRequest('req-404');
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-404',
          errorMessage: 'Stream connection interrupted by network timeout',
        ),
      );

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, contains('network timeout'));
    });

    test('5. Concurrency Guard: Stale chunks from older requests are dropped and do not overwrite active state', () {
      controller.startNewRequest('req-old-1');
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-old-1',
          partialScore: 60.0,
        ),
      );

      // Start new request (req-new-2)
      controller.startNewRequest('req-new-2');
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-new-2',
          partialScore: 92.0,
        ),
      );

      // Late arriving chunk from old request arrives
      controller.processChunk(
        AtsStreamChunk(
          requestId: 'req-old-1',
          partialScore: 30.0,
          newSuggestions: ['Stale suggestion'],
        ),
      );

      expect(controller.state.activeRequestId, equals('req-new-2'));
      expect(controller.state.currentScore, equals(92.0));
      expect(controller.state.accumulatedSuggestions, isNot(contains('Stale suggestion')));
    });
  });
}
