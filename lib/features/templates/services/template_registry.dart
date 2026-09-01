import '../implementations/academic_cv_template.dart';
import '../implementations/creative_professional_template.dart';
import '../implementations/executive_minimal_template.dart';
import '../implementations/modern_classic_template.dart';
import '../implementations/tech_specialist_template.dart';
import '../models/resume_template.dart';

class TemplateRegistry {
  static final List<ResumeTemplate> _templates = [
    ModernClassicTemplate(),
    ExecutiveMinimalTemplate(),
    CreativeProfessionalTemplate(),
    TechSpecialistTemplate(),
    AcademicCvTemplate(),
  ];

  static List<ResumeTemplate> get allTemplates {
    return List.unmodifiable(_templates);
  }

  static ResumeTemplate getTemplateById(String id) {
    return _templates.firstWhere(
      (t) => t.id == id,
      orElse: () => _templates.first,
    );
  }
}
