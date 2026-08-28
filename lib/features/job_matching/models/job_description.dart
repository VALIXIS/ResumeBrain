import 'package:uuid/uuid.dart';

class JobDescription {
  final String id;
  final String title;
  final String descriptionText;
  final String? url;

  JobDescription({
    String? id,
    this.title = '',
    required this.descriptionText,
    this.url,
  }) : id = id ?? const Uuid().v4();

  JobDescription copyWith({
    String? id,
    String? title,
    String? descriptionText,
    String? url,
  }) {
    return JobDescription(
      id: id ?? this.id,
      title: title ?? this.title,
      descriptionText: descriptionText ?? this.descriptionText,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'descriptionText': descriptionText,
        'url': url,
      };

  factory JobDescription.fromMap(Map<String, dynamic> map) => JobDescription(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        descriptionText: map['descriptionText'] ?? '',
        url: map['url'],
      );
}
