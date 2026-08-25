import '../implementations/executive_minimal_template.dart';
import '../implementations/modern_classic_template.dart';
import '../models/resume_template.dart';

class TemplateRegistry {
  static final List<ResumeTemplate> _templates = [
    ModernClassicTemplate(),
    ExecutiveMinimalTemplate(),
  ];

  static List<ResumeTemplate> get allTemplates => List.unmodifiable(_templates);

  static ResumeTemplate getTemplateById(String id) {
    return _templates.firstWhere(
      (t) => t.id == id,
      orElse: () => _templates.first,
    );
  }
}
