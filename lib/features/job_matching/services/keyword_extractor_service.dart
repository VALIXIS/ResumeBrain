import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/resume_models.dart';
import '../models/keyword_extraction_result.dart';

/// Definition of a technical skill and its alias variations.
class SkillDefinition {
  final String canonicalName;
  final List<String> aliases;

  const SkillDefinition({
    required this.canonicalName,
    required this.aliases,
  });
}

/// Internal helper model representing a candidate alias pattern sorted by length.
class _CandidateAlias {
  final String alias;
  final String canonicalName;

  const _CandidateAlias({
    required this.alias,
    required this.canonicalName,
  });
}

/// Service responsible for extracting technical keywords from Job Description text,
/// normalizing technology names, and calculating skill overlap against resume data.
class KeywordExtractorService {
  /// Comprehensive catalog of technical skill definitions across all required categories.
  static const List<SkillDefinition> _skillDefinitions = [
    // Programming Languages
    SkillDefinition(canonicalName: 'Python', aliases: ['python', 'py']),
    SkillDefinition(canonicalName: 'JavaScript', aliases: ['javascript', 'js', 'ecmascript']),
    SkillDefinition(canonicalName: 'TypeScript', aliases: ['typescript', 'ts']),
    SkillDefinition(canonicalName: 'Java', aliases: ['java']),
    SkillDefinition(canonicalName: 'C++', aliases: ['c++', 'cpp']),
    SkillDefinition(canonicalName: 'C#', aliases: ['c#', 'c-sharp', 'csharp']),
    SkillDefinition(canonicalName: 'C', aliases: ['c']),
    SkillDefinition(canonicalName: 'Go', aliases: ['golang', 'go']),
    SkillDefinition(canonicalName: 'Rust', aliases: ['rust']),
    SkillDefinition(canonicalName: 'Ruby', aliases: ['ruby']),
    SkillDefinition(canonicalName: 'PHP', aliases: ['php']),
    SkillDefinition(canonicalName: 'Swift', aliases: ['swift']),
    SkillDefinition(canonicalName: 'Kotlin', aliases: ['kotlin']),
    SkillDefinition(canonicalName: 'Dart', aliases: ['dart']),
    SkillDefinition(canonicalName: 'Scala', aliases: ['scala']),
    SkillDefinition(canonicalName: 'R', aliases: ['r']),
    SkillDefinition(canonicalName: 'Elixir', aliases: ['elixir']),
    SkillDefinition(canonicalName: 'Haskell', aliases: ['haskell']),
    SkillDefinition(canonicalName: 'Lua', aliases: ['lua']),
    SkillDefinition(canonicalName: 'Perl', aliases: ['perl']),
    SkillDefinition(canonicalName: 'Shell', aliases: ['shell', 'bash', 'powershell', 'zsh']),
    SkillDefinition(canonicalName: 'HTML', aliases: ['html', 'html5']),
    SkillDefinition(canonicalName: 'CSS', aliases: ['css', 'css3']),
    SkillDefinition(canonicalName: 'SQL', aliases: ['sql']),
    SkillDefinition(canonicalName: 'NoSQL', aliases: ['nosql']),
    SkillDefinition(canonicalName: 'GraphQL', aliases: ['graphql']),
    SkillDefinition(canonicalName: 'Assembly', aliases: ['assembly', 'asm']),
    SkillDefinition(canonicalName: 'MATLAB', aliases: ['matlab']),
    SkillDefinition(canonicalName: 'Groovy', aliases: ['groovy']),
    SkillDefinition(canonicalName: 'Objective-C', aliases: ['objective-c', 'obj-c']),
    SkillDefinition(canonicalName: 'PL/SQL', aliases: ['pl/sql', 'plsql']),

    // Frameworks & Platforms
    SkillDefinition(canonicalName: 'React Native', aliases: ['react native', 'react-native']),
    SkillDefinition(canonicalName: 'React', aliases: ['react', 'react.js', 'reactjs']),
    SkillDefinition(canonicalName: 'Angular', aliases: ['angular', 'angularjs', 'angular.js']),
    SkillDefinition(canonicalName: 'Vue.js', aliases: ['vue.js', 'vuejs', 'vue']),
    SkillDefinition(canonicalName: 'Svelte', aliases: ['svelte', 'sveltekit']),
    SkillDefinition(canonicalName: 'Next.js', aliases: ['next.js', 'nextjs', 'next']),
    SkillDefinition(canonicalName: 'Nuxt.js', aliases: ['nuxt.js', 'nuxtjs', 'nuxt']),
    SkillDefinition(canonicalName: 'Node.js', aliases: ['node.js', 'nodejs', 'node']),
    SkillDefinition(canonicalName: 'Express.js', aliases: ['express.js', 'expressjs', 'express']),
    SkillDefinition(canonicalName: 'NestJS', aliases: ['nestjs', 'nest.js']),
    SkillDefinition(canonicalName: 'Django', aliases: ['django']),
    SkillDefinition(canonicalName: 'Flask', aliases: ['flask']),
    SkillDefinition(canonicalName: 'FastAPI', aliases: ['fastapi']),
    SkillDefinition(canonicalName: 'Spring Boot', aliases: ['spring boot', 'springboot', 'spring framework', 'spring']),
    SkillDefinition(canonicalName: 'ASP.NET', aliases: ['asp.net', 'asp.net core']),
    SkillDefinition(canonicalName: '.NET', aliases: ['.net', 'dotnet', '.net core']),
    SkillDefinition(canonicalName: 'Ruby on Rails', aliases: ['ruby on rails', 'rails']),
    SkillDefinition(canonicalName: 'Laravel', aliases: ['laravel']),
    SkillDefinition(canonicalName: 'Flutter', aliases: ['flutter']),
    SkillDefinition(canonicalName: 'Riverpod', aliases: ['riverpod']),
    SkillDefinition(canonicalName: 'SwiftUI', aliases: ['swiftui']),
    SkillDefinition(canonicalName: 'Jetpack Compose', aliases: ['jetpack compose', 'compose']),

    // Libraries
    SkillDefinition(canonicalName: 'TensorFlow', aliases: ['tensorflow', 'tf']),
    SkillDefinition(canonicalName: 'PyTorch', aliases: ['pytorch']),
    SkillDefinition(canonicalName: 'Scikit-learn', aliases: ['scikit-learn', 'scikit learn', 'sklearn']),
    SkillDefinition(canonicalName: 'Pandas', aliases: ['pandas']),
    SkillDefinition(canonicalName: 'NumPy', aliases: ['numpy']),
    SkillDefinition(canonicalName: 'OpenCV', aliases: ['opencv']),
    SkillDefinition(canonicalName: 'Keras', aliases: ['keras']),
    SkillDefinition(canonicalName: 'Tailwind CSS', aliases: ['tailwind css', 'tailwindcss', 'tailwind']),
    SkillDefinition(canonicalName: 'Bootstrap', aliases: ['bootstrap']),
    SkillDefinition(canonicalName: 'Redux', aliases: ['redux', 'redux toolkit']),
    SkillDefinition(canonicalName: 'RxJS', aliases: ['rxjs']),
    SkillDefinition(canonicalName: 'Hibernate', aliases: ['hibernate']),
    SkillDefinition(canonicalName: 'Prisma', aliases: ['prisma']),
    SkillDefinition(canonicalName: 'TypeORM', aliases: ['typeorm']),
    SkillDefinition(canonicalName: 'Entity Framework', aliases: ['entity framework', 'ef core']),

    // Databases
    SkillDefinition(canonicalName: 'PostgreSQL', aliases: ['postgresql', 'postgres']),
    SkillDefinition(canonicalName: 'MySQL', aliases: ['mysql']),
    SkillDefinition(canonicalName: 'MariaDB', aliases: ['mariadb']),
    SkillDefinition(canonicalName: 'SQLite', aliases: ['sqlite']),
    SkillDefinition(canonicalName: 'MongoDB', aliases: ['mongodb', 'mongo']),
    SkillDefinition(canonicalName: 'Redis', aliases: ['redis']),
    SkillDefinition(canonicalName: 'Cassandra', aliases: ['cassandra']),
    SkillDefinition(canonicalName: 'Elasticsearch', aliases: ['elasticsearch', 'elastic search']),
    SkillDefinition(canonicalName: 'DynamoDB', aliases: ['dynamodb', 'dynamo']),
    SkillDefinition(canonicalName: 'Firebase', aliases: ['firebase', 'firestore']),
    SkillDefinition(canonicalName: 'Supabase', aliases: ['supabase']),
    SkillDefinition(canonicalName: 'Neo4j', aliases: ['neo4j']),
    SkillDefinition(canonicalName: 'Oracle Database', aliases: ['oracle database', 'oracle db', 'oracle']),
    SkillDefinition(canonicalName: 'SQL Server', aliases: ['sql server', 'ms sql server', 'mssql']),
    SkillDefinition(canonicalName: 'ClickHouse', aliases: ['clickhouse']),
    SkillDefinition(canonicalName: 'Snowflake', aliases: ['snowflake']),
    SkillDefinition(canonicalName: 'BigQuery', aliases: ['bigquery']),
    SkillDefinition(canonicalName: 'Redshift', aliases: ['redshift']),

    // Cloud Platforms
    SkillDefinition(canonicalName: 'Amazon Web Services', aliases: ['amazon web services', 'aws']),
    SkillDefinition(canonicalName: 'Google Cloud Platform', aliases: ['google cloud platform', 'gcp', 'google cloud']),
    SkillDefinition(canonicalName: 'Microsoft Azure', aliases: ['microsoft azure', 'azure']),
    SkillDefinition(canonicalName: 'Heroku', aliases: ['heroku']),
    SkillDefinition(canonicalName: 'DigitalOcean', aliases: ['digitalocean', 'digital ocean']),
    SkillDefinition(canonicalName: 'Vercel', aliases: ['vercel']),
    SkillDefinition(canonicalName: 'Netlify', aliases: ['netlify']),
    SkillDefinition(canonicalName: 'Cloudflare', aliases: ['cloudflare']),
    SkillDefinition(canonicalName: 'OpenStack', aliases: ['openstack']),

    // DevOps Tools
    SkillDefinition(canonicalName: 'Docker', aliases: ['docker']),
    SkillDefinition(canonicalName: 'Kubernetes', aliases: ['kubernetes', 'k8s']),
    SkillDefinition(canonicalName: 'Jenkins', aliases: ['jenkins']),
    SkillDefinition(canonicalName: 'Terraform', aliases: ['terraform']),
    SkillDefinition(canonicalName: 'Ansible', aliases: ['ansible']),
    SkillDefinition(canonicalName: 'CI/CD', aliases: ['ci/cd', 'cicd', 'ci cd', 'continuous integration']),
    SkillDefinition(canonicalName: 'Git', aliases: ['git']),
    SkillDefinition(canonicalName: 'GitHub', aliases: ['github']),
    SkillDefinition(canonicalName: 'GitLab', aliases: ['gitlab']),
    SkillDefinition(canonicalName: 'Bitbucket', aliases: ['bitbucket']),
    SkillDefinition(canonicalName: 'Helm', aliases: ['helm']),
    SkillDefinition(canonicalName: 'ArgoCD', aliases: ['argocd', 'argo cd']),
    SkillDefinition(canonicalName: 'Prometheus', aliases: ['prometheus']),
    SkillDefinition(canonicalName: 'Grafana', aliases: ['grafana']),
    SkillDefinition(canonicalName: 'ELK Stack', aliases: ['elk stack', 'elk']),
    SkillDefinition(canonicalName: 'Logstash', aliases: ['logstash']),
    SkillDefinition(canonicalName: 'Kibana', aliases: ['kibana']),
    SkillDefinition(canonicalName: 'Nginx', aliases: ['nginx']),
    SkillDefinition(canonicalName: 'Apache', aliases: ['apache']),
    SkillDefinition(canonicalName: 'Traefik', aliases: ['traefik']),
    SkillDefinition(canonicalName: 'CircleCI', aliases: ['circleci']),
    SkillDefinition(canonicalName: 'GitHub Actions', aliases: ['github actions']),
    SkillDefinition(canonicalName: 'Linux', aliases: ['linux']),
    SkillDefinition(canonicalName: 'Unix', aliases: ['unix']),
    SkillDefinition(canonicalName: 'Datadog', aliases: ['datadog']),
    SkillDefinition(canonicalName: 'New Relic', aliases: ['new relic']),
    SkillDefinition(canonicalName: 'Sentry', aliases: ['sentry']),
    SkillDefinition(canonicalName: 'Splunk', aliases: ['splunk']),

    // Development Tools
    SkillDefinition(canonicalName: 'Visual Studio Code', aliases: ['visual studio code', 'vs code', 'vscode']),
    SkillDefinition(canonicalName: 'Visual Studio', aliases: ['visual studio']),
    SkillDefinition(canonicalName: 'IntelliJ IDEA', aliases: ['intellij idea', 'intellij']),
    SkillDefinition(canonicalName: 'Eclipse', aliases: ['eclipse']),
    SkillDefinition(canonicalName: 'Xcode', aliases: ['xcode']),
    SkillDefinition(canonicalName: 'Android Studio', aliases: ['android studio']),
    SkillDefinition(canonicalName: 'Postman', aliases: ['postman']),
    SkillDefinition(canonicalName: 'Swagger', aliases: ['swagger', 'openapi']),
    SkillDefinition(canonicalName: 'Vite', aliases: ['vite']),
    SkillDefinition(canonicalName: 'Webpack', aliases: ['webpack']),
    SkillDefinition(canonicalName: 'Babel', aliases: ['babel']),
    SkillDefinition(canonicalName: 'Gradle', aliases: ['gradle']),
    SkillDefinition(canonicalName: 'Maven', aliases: ['maven']),
    SkillDefinition(canonicalName: 'npm', aliases: ['npm']),
    SkillDefinition(canonicalName: 'yarn', aliases: ['yarn']),
    SkillDefinition(canonicalName: 'pnpm', aliases: ['pnpm']),
    SkillDefinition(canonicalName: 'Cargo', aliases: ['cargo']),
    SkillDefinition(canonicalName: 'Pip', aliases: ['pip']),
    SkillDefinition(canonicalName: 'Poetry', aliases: ['poetry']),
    SkillDefinition(canonicalName: 'Jira', aliases: ['jira']),
    SkillDefinition(canonicalName: 'Confluence', aliases: ['confluence']),
    SkillDefinition(canonicalName: 'Trello', aliases: ['trello']),
    SkillDefinition(canonicalName: 'Figma', aliases: ['figma']),

    // Testing Technologies
    SkillDefinition(canonicalName: 'JUnit', aliases: ['junit', 'junit5']),
    SkillDefinition(canonicalName: 'Mockito', aliases: ['mockito']),
    SkillDefinition(canonicalName: 'Jest', aliases: ['jest']),
    SkillDefinition(canonicalName: 'Mocha', aliases: ['mocha']),
    SkillDefinition(canonicalName: 'Chai', aliases: ['chai']),
    SkillDefinition(canonicalName: 'Cypress', aliases: ['cypress']),
    SkillDefinition(canonicalName: 'Selenium', aliases: ['selenium']),
    SkillDefinition(canonicalName: 'Playwright', aliases: ['playwright']),
    SkillDefinition(canonicalName: 'Espresso', aliases: ['espresso']),
    SkillDefinition(canonicalName: 'XCTest', aliases: ['xctest']),
    SkillDefinition(canonicalName: 'PyTest', aliases: ['pytest']),
    SkillDefinition(canonicalName: 'SonarQube', aliases: ['sonarqube']),
    SkillDefinition(canonicalName: 'JMeter', aliases: ['jmeter']),
    SkillDefinition(canonicalName: 'Cucumber', aliases: ['cucumber']),
    SkillDefinition(canonicalName: 'Vitest', aliases: ['vitest']),

    // AI / ML Technologies
    SkillDefinition(canonicalName: 'Machine Learning', aliases: ['machine learning', 'ml']),
    SkillDefinition(canonicalName: 'Deep Learning', aliases: ['deep learning', 'dl']),
    SkillDefinition(canonicalName: 'Artificial Intelligence', aliases: ['artificial intelligence', 'ai']),
    SkillDefinition(canonicalName: 'Natural Language Processing', aliases: ['natural language processing', 'nlp']),
    SkillDefinition(canonicalName: 'Computer Vision', aliases: ['computer vision', 'cv']),
    SkillDefinition(canonicalName: 'Neural Networks', aliases: ['neural networks', 'neural network']),
    SkillDefinition(canonicalName: 'Large Language Models', aliases: ['large language models', 'large language model', 'llm', 'llms']),
    SkillDefinition(canonicalName: 'Generative AI', aliases: ['generative ai', 'genai']),
    SkillDefinition(canonicalName: 'RAG', aliases: ['rag', 'retrieval-augmented generation', 'retrieval augmented generation']),
    SkillDefinition(canonicalName: 'LangChain', aliases: ['langchain']),
    SkillDefinition(canonicalName: 'LlamaIndex', aliases: ['llamaindex']),
    SkillDefinition(canonicalName: 'Hugging Face', aliases: ['hugging face', 'huggingface', 'transformers']),
    SkillDefinition(canonicalName: 'MLflow', aliases: ['mlflow']),
    SkillDefinition(canonicalName: 'Airflow', aliases: ['airflow', 'apache airflow']),
    SkillDefinition(canonicalName: 'Kubeflow', aliases: ['kubeflow']),
    SkillDefinition(canonicalName: 'Spark', aliases: ['spark', 'apache spark', 'pyspark']),
    SkillDefinition(canonicalName: 'Vector Databases', aliases: ['vector databases', 'vector database']),
    SkillDefinition(canonicalName: 'Pinecone', aliases: ['pinecone']),
    SkillDefinition(canonicalName: 'Chroma', aliases: ['chroma', 'chromadb']),
    SkillDefinition(canonicalName: 'Qdrant', aliases: ['qdrant']),
    SkillDefinition(canonicalName: 'Weaviate', aliases: ['weaviate']),
    SkillDefinition(canonicalName: 'FAISS', aliases: ['faiss']),
    SkillDefinition(canonicalName: 'Ollama', aliases: ['ollama']),
    SkillDefinition(canonicalName: 'OpenAI', aliases: ['openai', 'chatgpt', 'gpt-4', 'gpt-3.5']),
    SkillDefinition(canonicalName: 'Claude', aliases: ['claude', 'anthropic']),
    SkillDefinition(canonicalName: 'Gemini', aliases: ['gemini']),

    // Web Technologies
    SkillDefinition(canonicalName: 'REST API', aliases: ['rest api', 'restful api', 'restful', 'rest']),
    SkillDefinition(canonicalName: 'WebSockets', aliases: ['websockets', 'websocket', 'ws']),
    SkillDefinition(canonicalName: 'gRPC', aliases: ['grpc']),
    SkillDefinition(canonicalName: 'Microservices', aliases: ['microservices', 'microservice']),
    SkillDefinition(canonicalName: 'Serverless', aliases: ['serverless']),
    SkillDefinition(canonicalName: 'WebAssembly', aliases: ['webassembly', 'wasm']),
    SkillDefinition(canonicalName: 'PWA', aliases: ['pwa', 'progressive web apps', 'progressive web app']),
    SkillDefinition(canonicalName: 'WebRTC', aliases: ['webrtc']),
    SkillDefinition(canonicalName: 'OAuth', aliases: ['oauth', 'oauth2', 'oauth 2.0']),
    SkillDefinition(canonicalName: 'JWT', aliases: ['jwt', 'json web token']),

    // Mobile Technologies
    SkillDefinition(canonicalName: 'iOS', aliases: ['ios']),
    SkillDefinition(canonicalName: 'Android', aliases: ['android']),
    SkillDefinition(canonicalName: 'Kotlin Multiplatform', aliases: ['kotlin multiplatform', 'kmp']),
    SkillDefinition(canonicalName: 'Ionic', aliases: ['ionic']),
    SkillDefinition(canonicalName: 'Cordova', aliases: ['cordova', 'phonegap']),

    // Architecture & Engineering Terminology
    SkillDefinition(canonicalName: 'Monolith', aliases: ['monolith', 'monolithic']),
    SkillDefinition(canonicalName: 'Event-Driven Architecture', aliases: ['event-driven architecture', 'event driven architecture', 'eda']),
    SkillDefinition(canonicalName: 'Domain-Driven Design', aliases: ['domain-driven design', 'domain driven design', 'ddd']),
    SkillDefinition(canonicalName: 'Test-Driven Development', aliases: ['test-driven development', 'test driven development', 'tdd']),
    SkillDefinition(canonicalName: 'Behavior-Driven Development', aliases: ['behavior-driven development', 'behavior driven development', 'bdd']),
    SkillDefinition(canonicalName: 'Clean Architecture', aliases: ['clean architecture']),
    SkillDefinition(canonicalName: 'SOLID Principles', aliases: ['solid principles', 'solid']),
    SkillDefinition(canonicalName: 'Design Patterns', aliases: ['design patterns', 'design pattern']),
    SkillDefinition(canonicalName: 'Object-Oriented Programming', aliases: ['object-oriented programming', 'object oriented programming', 'oop']),
    SkillDefinition(canonicalName: 'Functional Programming', aliases: ['functional programming']),
    SkillDefinition(canonicalName: 'Asynchronous Programming', aliases: ['asynchronous programming']),
    SkillDefinition(canonicalName: 'Agile', aliases: ['agile']),
    SkillDefinition(canonicalName: 'Scrum', aliases: ['scrum']),
    SkillDefinition(canonicalName: 'Kanban', aliases: ['kanban']),
  ];

  late final List<_CandidateAlias> _candidatesSortedByLength;
  late final Map<String, String> _aliasToCanonicalMap;

  KeywordExtractorService() {
    final list = <_CandidateAlias>[];
    final map = <String, String>{};

    for (final def in _skillDefinitions) {
      // Map canonical name to itself
      map[def.canonicalName.toLowerCase()] = def.canonicalName;

      for (final alias in def.aliases) {
        final lowerAlias = alias.toLowerCase();
        map[lowerAlias] = def.canonicalName;
        list.add(_CandidateAlias(
          alias: lowerAlias,
          canonicalName: def.canonicalName,
        ));
      }
    }

    // Sort candidates by length in descending order to give priority to multi-word phrases.
    list.sort((a, b) => b.alias.length.compareTo(a.alias.length));

    _candidatesSortedByLength = list;
    _aliasToCanonicalMap = map;
  }

  /// Normalizes a raw skill string into its canonical technical term representation.
  /// If the raw string is an alias, returns the canonical name.
  /// If not found in the dictionary, returns a cleaned, trimmed title-case version of [rawSkill].
  String normalizeSkill(String rawSkill) {
    final trimmed = rawSkill.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (_aliasToCanonicalMap.containsKey(lower)) {
      return _aliasToCanonicalMap[lower]!;
    }

    // If it's not in the dictionary, check if running extractor on it yields a known skill
    final extracted = extractKeywords(trimmed);
    if (extracted.length == 1) {
      return extracted.first;
    }

    // Strip leading/trailing punctuation and clean up spacing
    final cleaned = trimmed.replaceAll(RegExp(r'^[^\w+#.]+|[^\w+#.]+$'), '');
    return cleaned.isNotEmpty ? _toTitleCase(cleaned) : trimmed;
  }

  /// Extracts unique canonical technical skills from a Job Description text.
  List<String> extractKeywords(String jobDescriptionText) {
    if (jobDescriptionText.trim().isEmpty) {
      return [];
    }

    final lowerText = jobDescriptionText.toLowerCase();
    final matchedIndices = <int>{};
    final foundCanonicalSkills = <String>{};

    for (final candidate in _candidatesSortedByLength) {
      final alias = candidate.alias;
      final aliasLen = alias.length;
      int startIndex = 0;

      while (startIndex <= lowerText.length - aliasLen) {
        final matchPos = lowerText.indexOf(alias, startIndex);
        if (matchPos == -1) break;

        final endPos = matchPos + aliasLen;

        // Check character index overlaps
        bool hasIndexOverlap = false;
        for (int i = matchPos; i < endPos; i++) {
          if (matchedIndices.contains(i)) {
            hasIndexOverlap = true;
            break;
          }
        }

        if (!hasIndexOverlap && _isValidBoundary(jobDescriptionText, matchPos, endPos, alias)) {
          foundCanonicalSkills.add(candidate.canonicalName);
          for (int i = matchPos; i < endPos; i++) {
            matchedIndices.add(i);
          }
        }

        startIndex = matchPos + 1;
      }
    }

    final sortedList = foundCanonicalSkills.toList()..sort();
    return sortedList;
  }

  /// Compares Job Description text against explicit resume skills or a full [Resume] object.
  KeywordExtractionResult extractAndCompare({
    required String jobDescriptionText,
    Resume? resume,
    List<String>? userSkills,
  }) {
    final jdSkills = extractKeywords(jobDescriptionText);
    if (jdSkills.isEmpty) {
      return KeywordExtractionResult.empty();
    }

    final resumeSkillsSet = <String>{};

    // Add provided explicit user skills
    if (userSkills != null) {
      for (final s in userSkills) {
        final normalized = normalizeSkill(s);
        if (normalized.isNotEmpty) {
          resumeSkillsSet.add(normalized);
        }
      }
    }

    // Extract skills from resume fields if available
    if (resume != null) {
      // 1. Explicit skill section
      for (final s in resume.skills) {
        final normalized = normalizeSkill(s.name);
        if (normalized.isNotEmpty) {
          resumeSkillsSet.add(normalized);
        }
      }

      // 2. Extract technical terms from resume prose
      final resumeProseBuffer = StringBuffer();
      if (resume.personalInfo.jobTitle.isNotEmpty) {
        resumeProseBuffer.writeln(resume.personalInfo.jobTitle);
      }
      if (resume.summary.summaryText.isNotEmpty) {
        resumeProseBuffer.writeln(resume.summary.summaryText);
      }
      for (final exp in resume.experiences) {
        resumeProseBuffer.writeln('${exp.position} ${exp.description}');
      }
      for (final proj in resume.projects) {
        resumeProseBuffer.writeln('${proj.name} ${proj.role} ${proj.technologies} ${proj.description}');
      }
      for (final edu in resume.educationList) {
        resumeProseBuffer.writeln('${edu.degree} ${edu.fieldOfStudy}');
      }
      for (final cert in resume.certifications) {
        resumeProseBuffer.writeln(cert.name);
      }
      for (final cs in resume.customSections) {
        resumeProseBuffer.writeln(cs.items.join(' '));
      }

      final extractedFromResume = extractKeywords(resumeProseBuffer.toString());
      resumeSkillsSet.addAll(extractedFromResume);
    }

    final jdSet = jdSkills.toSet();
    final matchedSet = jdSet.intersection(resumeSkillsSet);
    final missingSet = jdSet.difference(resumeSkillsSet);

    final matchedList = matchedSet.toList()..sort();
    final missingList = missingSet.toList()..sort();

    final double rawPercentage = (matchedList.length / jdSkills.length) * 100.0;
    final double overlapPercentage = double.parse(rawPercentage.toStringAsFixed(2));

    return KeywordExtractionResult(
      extractedJdSkills: jdSkills,
      matchedSkills: matchedList,
      missingSkills: missingList,
      overlapPercentage: overlapPercentage,
    );
  }

  /// Verifies boundary rules around a candidate match to avoid substring false positives.
  bool _isValidBoundary(String text, int start, int end, String alias) {
    final firstChar = alias[0];
    final isFirstAlphaNum = RegExp(r'^[a-zA-Z0-9]').hasMatch(firstChar);

    if (isFirstAlphaNum && start > 0) {
      final prevChar = text[start - 1];
      if (RegExp(r'^[a-zA-Z0-9]').hasMatch(prevChar)) {
        return false;
      }
    }

    final lastChar = alias[alias.length - 1];
    final isLastAlphaNum = RegExp(r'^[a-zA-Z0-9]').hasMatch(lastChar);

    if (isLastAlphaNum && end < text.length) {
      final nextChar = text[end];
      if (RegExp(r'^[a-zA-Z0-9]').hasMatch(nextChar)) {
        return false;
      }
    } else if (!isLastAlphaNum && end < text.length) {
      final nextChar = text[end];
      if (nextChar == lastChar) {
        return false;
      }
    }

    return true;
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Riverpod provider exposing [KeywordExtractorService].
final keywordExtractorServiceProvider = Provider<KeywordExtractorService>((ref) {
  return KeywordExtractorService();
});
