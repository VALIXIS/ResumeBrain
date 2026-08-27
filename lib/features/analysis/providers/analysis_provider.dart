import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analysis_engine.dart';

/// Provider exposing the [AnalysisEngine] instance.
final analysisEngineProvider = Provider<AnalysisEngine>((ref) {
  return MockAnalysisEngine();
});
