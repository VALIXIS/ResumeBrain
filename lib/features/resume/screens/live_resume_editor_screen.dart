import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../presentation/resume_editor_screen.dart';

export '../presentation/resume_editor_screen.dart';

/// LiveResumeEditorScreen provides a seamless compatibility layer and entry point
/// for editing resumes with persistent TextEditingController keys, keep-alive tabs,
/// and debounced auto-save.
class LiveResumeEditorScreen extends ConsumerWidget {
  final String? resumeId;
  const LiveResumeEditorScreen({super.key, this.resumeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resumeId != null) {
      final repo = ref.read(resumeRepositoryProvider);
      final current = ref.read(currentResumeProvider);
      if (current == null || current.id != resumeId) {
        Future.microtask(() async {
          final resume = await repo.getResumeById(resumeId!);
          if (resume != null) {
            ref.read(currentResumeProvider.notifier).setResume(resume);
          }
        });
      }
    }
    return const ResumeEditorScreen();
  }
}
