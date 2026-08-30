/// Model representing categorized feedback for an analysis area
/// (Formatting, Content Quality, Keywords).
class CategoryFeedback {
  final String title;
  final int? score; // 0 to 100
  final String? status; // e.g. 'Strong', 'Moderate', 'Needs Work'
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  const CategoryFeedback({
    required this.title,
    this.score,
    this.status,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendations = const [],
  });

  CategoryFeedback copyWith({
    String? title,
    int? score,
    String? status,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? recommendations,
  }) {
    return CategoryFeedback(
      title: title ?? this.title,
      score: score ?? this.score,
      status: status ?? this.status,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'score': score,
        'status': status,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'recommendations': recommendations,
      };

  factory CategoryFeedback.fromMap(Map<String, dynamic> map) =>
      CategoryFeedback(
        title: map['title'] ?? '',
        score: map['score'] as int?,
        status: map['status'] as String?,
        strengths: List<String>.from(map['strengths'] ?? []),
        weaknesses: List<String>.from(map['weaknesses'] ?? []),
        recommendations: List<String>.from(map['recommendations'] ?? []),
      );
}
