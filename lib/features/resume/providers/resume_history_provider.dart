import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';

/// Immutable state representing the undo and redo history for the active resume.
class ResumeHistoryState {
  final List<Resume> undoStack;
  final List<Resume> redoStack;
  final int maxHistoryLength;

  const ResumeHistoryState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.maxHistoryLength = 50,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  ResumeHistoryState copyWith({
    List<Resume>? undoStack,
    List<Resume>? redoStack,
    int? maxHistoryLength,
  }) {
    return ResumeHistoryState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      maxHistoryLength: maxHistoryLength ?? this.maxHistoryLength,
    );
  }
}

/// StateNotifier responsible for managing bounded undo/redo history snapshots
/// and synchronizing transitions with Riverpod's [currentResumeProvider].
class ResumeHistoryNotifier extends StateNotifier<ResumeHistoryState> {
  final Ref? _ref;
  Resume? _currentSnapshot;
  bool _isPerformingUndoRedo = false;

  ResumeHistoryNotifier([this._ref]) : super(const ResumeHistoryState());

  /// Initializes or resets the history baseline with the current active resume.
  void initializeWithResume(Resume? resume) {
    if (resume == null) return;
    _currentSnapshot ??= resume;
  }

  /// Records a new snapshot before or after a state mutation.
  /// Deduplicates identical snapshots and clears the redo stack on new user edits.
  void recordSnapshot(Resume? newResume) {
    if (newResume == null || _isPerformingUndoRedo) return;

    if (_currentSnapshot == null) {
      _currentSnapshot = newResume;
      return;
    }

    // Skip recording if the resume hasn't changed meaningfully
    if (_currentSnapshot == newResume) {
      return;
    }

    final updatedUndoStack = List<Resume>.from(state.undoStack);
    updatedUndoStack.add(_currentSnapshot!);

    // Maintain maximum history bound
    if (updatedUndoStack.length > state.maxHistoryLength) {
      updatedUndoStack.removeAt(0);
    }

    _currentSnapshot = newResume;

    // A new edit invalidates the forward redo stack
    state = state.copyWith(
      undoStack: updatedUndoStack,
      redoStack: const [],
    );
  }

  /// Undoes the last mutation and restores the previous resume state.
  bool undo([dynamic optionalRef]) {
    if (!state.canUndo || _currentSnapshot == null) return false;

    _isPerformingUndoRedo = true;
    try {
      final updatedUndoStack = List<Resume>.from(state.undoStack);
      final previousState = updatedUndoStack.removeLast();

      final updatedRedoStack = List<Resume>.from(state.redoStack);
      updatedRedoStack.add(_currentSnapshot!);

      _currentSnapshot = previousState;

      // Update the single source of truth
      if (optionalRef is WidgetRef) {
        optionalRef.read(currentResumeProvider.notifier).setResume(previousState);
      } else if (optionalRef is Ref) {
        optionalRef.read(currentResumeProvider.notifier).setResume(previousState);
      } else if (_ref != null) {
        _ref.read(currentResumeProvider.notifier).setResume(previousState);
      }

      state = state.copyWith(
        undoStack: updatedUndoStack,
        redoStack: updatedRedoStack,
      );
      return true;
    } finally {
      _isPerformingUndoRedo = false;
    }
  }

  /// Redoes the last undone mutation.
  bool redo([dynamic optionalRef]) {
    if (!state.canRedo || _currentSnapshot == null) return false;

    _isPerformingUndoRedo = true;
    try {
      final updatedRedoStack = List<Resume>.from(state.redoStack);
      final nextState = updatedRedoStack.removeLast();

      final updatedUndoStack = List<Resume>.from(state.undoStack);
      updatedUndoStack.add(_currentSnapshot!);

      _currentSnapshot = nextState;

      // Update the single source of truth
      if (optionalRef is WidgetRef) {
        optionalRef.read(currentResumeProvider.notifier).setResume(nextState);
      } else if (optionalRef is Ref) {
        optionalRef.read(currentResumeProvider.notifier).setResume(nextState);
      } else if (_ref != null) {
        _ref.read(currentResumeProvider.notifier).setResume(nextState);
      }

      state = state.copyWith(
        undoStack: updatedUndoStack,
        redoStack: updatedRedoStack,
      );
      return true;
    } finally {
      _isPerformingUndoRedo = false;
    }
  }

  /// Clears undo and redo history.
  void clearHistory() {
    _currentSnapshot = null;
    state = const ResumeHistoryState();
  }
}

/// Global provider for managing resume undo/redo history within the Resume feature.
final resumeHistoryProvider =
    StateNotifierProvider<ResumeHistoryNotifier, ResumeHistoryState>((ref) {
  return ResumeHistoryNotifier(ref);
});
