import 'package:uuid/uuid.dart';

class PersonalInformation {
  final String fullName;
  final String jobTitle;
  final String email;
  final String phone;
  final String location;
  final String website;

  PersonalInformation({
    this.fullName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
  });

  PersonalInformation copyWith({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? website,
  }) {
    return PersonalInformation(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'jobTitle': jobTitle,
        'email': email,
        'phone': phone,
        'location': location,
        'website': website,
      };

  factory PersonalInformation.fromMap(Map<String, dynamic> map) => PersonalInformation(
        fullName: map['fullName'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        location: map['location'] ?? '',
        website: map['website'] ?? '',
      );
}

class ProfessionalSummary {
  final String summaryText;

  ProfessionalSummary({this.summaryText = ''});

  ProfessionalSummary copyWith({String? summaryText}) {
    return ProfessionalSummary(summaryText: summaryText ?? this.summaryText);
  }

  Map<String, dynamic> toMap() => {'summaryText': summaryText};

  factory ProfessionalSummary.fromMap(Map<String, dynamic> map) =>
      ProfessionalSummary(summaryText: map['summaryText'] ?? '');
}

class Experience {
  final String id;
  final String company;
  final String position;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final String description;

  Experience({
    String? id,
    this.company = '',
    this.position = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrent = false,
    this.description = '',
  }) : id = id ?? const Uuid().v4();

  Experience copyWith({
    String? company,
    String? position,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    String? description,
  }) {
    return Experience(
      id: id,
      company: company ?? this.company,
      position: position ?? this.position,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company': company,
        'position': position,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'description': description,
      };

  factory Experience.fromMap(Map<String, dynamic> map) => Experience(
        id: map['id'],
        company: map['company'] ?? '',
        position: map['position'] ?? '',
        location: map['location'] ?? '',
        startDate: map['startDate'] ?? '',
        endDate: map['endDate'] ?? '',
        isCurrent: map['isCurrent'] ?? false,
        description: map['description'] ?? '',
      );
}

class Education {
  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String location;
  final String startDate;
  final String endDate;
  final String gpa;

  Education({
    String? id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
  }) : id = id ?? const Uuid().v4();

  Education copyWith({
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? location,
    String? startDate,
    String? endDate,
    String? gpa,
  }) {
    return Education(
      id: id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gpa: gpa ?? this.gpa,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'gpa': gpa,
      };

  factory Education.fromMap(Map<String, dynamic> map) => Education(
        id: map['id'],
        institution: map['institution'] ?? '',
        degree: map['degree'] ?? '',
        fieldOfStudy: map['fieldOfStudy'] ?? '',
        location: map['location'] ?? '',
        startDate: map['startDate'] ?? '',
        endDate: map['endDate'] ?? '',
        gpa: map['gpa'] ?? '',
      );
}

class Project {
  final String id;
  final String name;
  final String role;
  final String description;
  final String technologies;
  final String link;

  Project({
    String? id,
    this.name = '',
    this.role = '',
    this.description = '',
    this.technologies = '',
    this.link = '',
  }) : id = id ?? const Uuid().v4();

  Project copyWith({
    String? name,
    String? role,
    String? description,
    String? technologies,
    String? link,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      technologies: technologies ?? this.technologies,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'description': description,
        'technologies': technologies,
        'link': link,
      };

  factory Project.fromMap(Map<String, dynamic> map) => Project(
        id: map['id'],
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        description: map['description'] ?? '',
        technologies: map['technologies'] ?? '',
        link: map['link'] ?? '',
      );
}

class Skill {
  final String id;
  final String name;
  final String level; // e.g. Beginner, Intermediate, Expert

  Skill({
    String? id,
    this.name = '',
    this.level = 'Intermediate',
  }) : id = id ?? const Uuid().v4();

  Skill copyWith({String? name, String? level}) {
    return Skill(
      id: id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'level': level,
      };

  factory Skill.fromMap(Map<String, dynamic> map) => Skill(
        id: map['id'],
        name: map['name'] ?? '',
        level: map['level'] ?? 'Intermediate',
      );
}

class Certification {
  final String id;
  final String name;
  final String issuingOrganization;
  final String issueDate;
  final String expiryDate;
  final String credentialId;
  final String credentialUrl;

  Certification({
    String? id,
    this.name = '',
    this.issuingOrganization = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.credentialId = '',
    this.credentialUrl = '',
  }) : id = id ?? const Uuid().v4();

  Certification copyWith({
    String? name,
    String? issuingOrganization,
    String? issueDate,
    String? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return Certification(
      id: id,
      name: name ?? this.name,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      credentialId: credentialId ?? this.credentialId,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'issuingOrganization': issuingOrganization,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
        'credentialId': credentialId,
        'credentialUrl': credentialUrl,
      };

  factory Certification.fromMap(Map<String, dynamic> map) => Certification(
        id: map['id'],
        name: map['name'] ?? '',
        issuingOrganization: map['issuingOrganization'] ?? '',
        issueDate: map['issueDate'] ?? '',
        expiryDate: map['expiryDate'] ?? '',
        credentialId: map['credentialId'] ?? '',
        credentialUrl: map['credentialUrl'] ?? '',
      );
}

class Language {
  final String id;
  final String name;
  final String proficiency; // e.g. Native, Fluent, Conversational, Beginner

  Language({
    String? id,
    this.name = '',
    this.proficiency = 'Fluent',
  }) : id = id ?? const Uuid().v4();

  Language copyWith({String? name, String? proficiency}) {
    return Language(
      id: id,
      name: name ?? this.name,
      proficiency: proficiency ?? this.proficiency,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'proficiency': proficiency,
      };

  factory Language.fromMap(Map<String, dynamic> map) => Language(
        id: map['id'],
        name: map['name'] ?? '',
        proficiency: map['proficiency'] ?? 'Fluent',
      );
}

/// Model representing a user-defined custom section in the resume.
class CustomSection {
  final String id;
  final String title;
  final List<String> items;

  CustomSection({
    String? id,
    this.title = '',
    List<String>? items,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  CustomSection copyWith({
    String? title,
    List<String>? items,
  }) {
    return CustomSection(
      id: id,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'items': items,
      };

  factory CustomSection.fromMap(Map<String, dynamic> map) => CustomSection(
        id: map['id'],
        title: map['title'] ?? '',
        items: map['items'] != null ? List<String>.from(map['items']) : [],
      );
}

class SocialLink {
  final String id;
  final String platform; // LinkedIn, GitHub, Portfolio, Twitter
  final String url;

  SocialLink({
    String? id,
    this.platform = 'LinkedIn',
    this.url = '',
  }) : id = id ?? const Uuid().v4();

  SocialLink copyWith({String? platform, String? url}) {
    return SocialLink(
      id: id,
      platform: platform ?? this.platform,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'platform': platform,
        'url': url,
      };

  factory SocialLink.fromMap(Map<String, dynamic> map) => SocialLink(
        id: map['id'],
        platform: map['platform'] ?? 'LinkedIn',
        url: map['url'] ?? '',
      );
}

class Resume {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String templateId;

  final PersonalInformation personalInfo;
  final ProfessionalSummary summary;
  final List<Experience> experiences;
  final List<Education> educationList;
  final List<Project> projects;
  final List<Skill> skills;
  final List<Certification> certifications;
  final List<Language> languages;
  final List<CustomSection> customSections;
  final List<SocialLink> socialLinks;

  Resume({
    String? id,
    this.title = 'Untitled Resume',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.templateId = 'modern_classic',
    PersonalInformation? personalInfo,
    ProfessionalSummary? summary,
    List<Experience>? experiences,
    List<Education>? educationList,
    List<Project>? projects,
    List<Skill>? skills,
    List<Certification>? certifications,
    List<Language>? languages,
    List<CustomSection>? customSections,
    List<SocialLink>? socialLinks,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        personalInfo = personalInfo ?? PersonalInformation(),
        summary = summary ?? ProfessionalSummary(),
        experiences = experiences ?? [],
        educationList = educationList ?? [],
        projects = projects ?? [],
        skills = skills ?? [],
        certifications = certifications ?? [],
        languages = languages ?? [],
        customSections = customSections ?? [],
        socialLinks = socialLinks ?? [];

  Resume copyWith({
    String? title,
    DateTime? updatedAt,
    String? templateId,
    PersonalInformation? personalInfo,
    ProfessionalSummary? summary,
    List<Experience>? experiences,
    List<Education>? educationList,
    List<Project>? projects,
    List<Skill>? skills,
    List<Certification>? certifications,
    List<Language>? languages,
    List<CustomSection>? customSections,
    List<SocialLink>? socialLinks,
  }) {
    return Resume(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      templateId: templateId ?? this.templateId,
      personalInfo: personalInfo ?? this.personalInfo,
      summary: summary ?? this.summary,
      experiences: experiences ?? this.experiences,
      educationList: educationList ?? this.educationList,
      projects: projects ?? this.projects,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      languages: languages ?? this.languages,
      customSections: customSections ?? this.customSections,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'templateId': templateId,
        'personalInfo': personalInfo.toMap(),
        'summary': summary.toMap(),
        'experiences': experiences.map((e) => e.toMap()).toList(),
        'educationList': educationList.map((e) => e.toMap()).toList(),
        'projects': projects.map((e) => e.toMap()).toList(),
        'skills': skills.map((e) => e.toMap()).toList(),
        'certifications': certifications.map((e) => e.toMap()).toList(),
        'languages': languages.map((e) => e.toMap()).toList(),
        'customSections': customSections.map((e) => e.toMap()).toList(),
        'socialLinks': socialLinks.map((e) => e.toMap()).toList(),
      };

  factory Resume.fromMap(Map<String, dynamic> map) => Resume(
        id: map['id'],
        title: map['title'] ?? 'Untitled Resume',
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        templateId: map['templateId'] ?? 'modern_classic',
        personalInfo: map['personalInfo'] != null
            ? PersonalInformation.fromMap(Map<String, dynamic>.from(map['personalInfo']))
            : PersonalInformation(),
        summary: map['summary'] != null
            ? ProfessionalSummary.fromMap(Map<String, dynamic>.from(map['summary']))
            : ProfessionalSummary(),
        experiences: map['experiences'] != null
            ? (map['experiences'] as List).map((e) => Experience.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        educationList: map['educationList'] != null
            ? (map['educationList'] as List).map((e) => Education.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        projects: map['projects'] != null
            ? (map['projects'] as List).map((e) => Project.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        skills: map['skills'] != null
            ? (map['skills'] as List).map((e) => Skill.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        certifications: map['certifications'] != null
            ? (map['certifications'] as List).map((e) => Certification.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        languages: map['languages'] != null
            ? (map['languages'] as List).map((e) => Language.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        customSections: map['customSections'] != null
            ? (map['customSections'] as List).map((e) => CustomSection.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
        socialLinks: map['socialLinks'] != null
            ? (map['socialLinks'] as List).map((e) => SocialLink.fromMap(Map<String, dynamic>.from(e))).toList()
            : [],
      );
}
