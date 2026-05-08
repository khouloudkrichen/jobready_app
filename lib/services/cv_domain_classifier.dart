// ============================================================
// cv_domain_classifier.dart
// Détecte intelligemment le domaine principal et secondaires
// depuis les compétences, expériences et mots-clés du CV
// ============================================================

class DomainClassification {
  final String mainDomain;
  final List<String> secondaryDomains;
  final List<String> detectedKeywords;
  final double confidence;

  DomainClassification({
    required this.mainDomain,
    required this.secondaryDomains,
    required this.detectedKeywords,
    required this.confidence,
  });
}

class CvDomainClassifier {
  // ─────────────────────────────────────────
  // DOMAINES ET LEURS MOTS-CLÉS
  // ─────────────────────────────────────────

  static const Map<String, List<String>> _domainKeywords = {
    'Mobile Development': [
      'flutter',
      'dart',
      'android',
      'ios',
      'swift',
      'kotlin',
      'react native',
      'jetpack compose',
      'swiftui',
      'mobile',
      'app store',
      'play store',
      'xcode',
      'android studio',
      'ionic',
      'xamarin',
    ],
    'Web Development': [
      'html',
      'css',
      'javascript',
      'typescript',
      'react',
      'angular',
      'vue',
      'next.js',
      'nuxt',
      'node.js',
      'express',
      'nestjs',
      'laravel',
      'django',
      'flask',
      'spring boot',
      'web',
      'frontend',
      'backend',
      'fullstack',
      'full-stack',
      'rest api',
      'graphql',
      'bootstrap',
      'tailwind',
      'php',
    ],
    'Data Science / AI': [
      'machine learning',
      'deep learning',
      'tensorflow',
      'pytorch',
      'keras',
      'scikit-learn',
      'pandas',
      'numpy',
      'data science',
      'intelligence artificielle',
      'nlp',
      'computer vision',
      'data analysis',
      'big data',
      'spark',
      'hadoop',
      'r',
      'statistics',
      'data mining',
      'neural network',
      'regression',
      'classification',
      'clustering',
      'matplotlib',
      'seaborn',
    ],
    'DevOps / Cloud': [
      'docker',
      'kubernetes',
      'ci/cd',
      'jenkins',
      'ansible',
      'terraform',
      'aws',
      'gcp',
      'azure',
      'cloud',
      'linux',
      'nginx',
      'apache',
      'infrastructure',
      'devops',
      'gitlab',
      'github actions',
      'helm',
      'prometheus',
      'grafana',
      'microservices',
    ],
    'Cybersecurity': [
      'sécurité',
      'security',
      'pentest',
      'penetration testing',
      'ethical hacking',
      'ctf',
      'kali',
      'metasploit',
      'wireshark',
      'firewall',
      'vpn',
      'cryptography',
      'ssl',
      'tls',
      'vulnerability',
      'owasp',
      'cybersécurité',
      'forensics',
      'siem',
      'ids',
      'ips',
    ],
    'UI/UX Design': [
      'figma',
      'adobe xd',
      'sketch',
      'ui',
      'ux',
      'user interface',
      'user experience',
      'prototyping',
      'wireframe',
      'design system',
      'accessibility',
      'usability',
      'interaction design',
      'material design',
      'invision',
      'zeplin',
    ],
    'Software Engineering': [
      'solid',
      'design patterns',
      'clean code',
      'tdd',
      'unit testing',
      'agile',
      'scrum',
      'kanban',
      'oop',
      'object oriented',
      'functional programming',
      'architecture',
      'microservices',
      'system design',
      'algorithms',
      'data structures',
      'java',
      'c++',
      'c#',
      '.net',
    ],
    'Database / Data Engineering': [
      'mysql',
      'postgresql',
      'mongodb',
      'redis',
      'elasticsearch',
      'oracle',
      'sql',
      'nosql',
      'database',
      'data modeling',
      'etl',
      'data warehouse',
      'olap',
      'bi',
      'power bi',
      'tableau',
    ],
    'Business / Management': [
      'gestion de projet',
      'project management',
      'pmp',
      'scrum master',
      'product owner',
      'business analyst',
      'erp',
      'sap',
      'crm',
      'marketing',
      'finance',
      'comptabilité',
      'rh',
      'management',
      'strategy',
      'kpi',
      'reporting',
    ],
    'Embedded Systems / IoT': [
      'arduino',
      'raspberry pi',
      'stm32',
      'embedded',
      'firmware',
      'rtos',
      'iot',
      'hardware',
      'capteur',
      'sensor',
      'pcb',
      'fpga',
      'vhdl',
      'verilog',
      'robotics',
      'ros',
      'microcontroller',
    ],
  };

  // ─────────────────────────────────────────
  // CLASSIFICATION PRINCIPALE
  // ─────────────────────────────────────────

  static DomainClassification classify({
    required String rawText,
    required List<String> skills,
    required List<String> frameworks,
    required List<String> tools,
    required List<String> programmingLanguages,
    List<String> experienceDescriptions = const [],
  }) {
    final combined = [
      rawText.toLowerCase(),
      ...skills.map((s) => s.toLowerCase()),
      ...frameworks.map((s) => s.toLowerCase()),
      ...tools.map((s) => s.toLowerCase()),
      ...programmingLanguages.map((s) => s.toLowerCase()),
      ...experienceDescriptions.map((s) => s.toLowerCase()),
    ].join(' ');

    // Calculer score pour chaque domaine
    final Map<String, int> scores = {};
    final List<String> allKeywords = [];

    for (final entry in _domainKeywords.entries) {
      int score = 0;
      for (final kw in entry.value) {
        if (combined.contains(kw)) {
          score++;
          if (!allKeywords.contains(kw)) allKeywords.add(kw);
        }
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) {
      return DomainClassification(
        mainDomain: 'Informatique Générale',
        secondaryDomains: [],
        detectedKeywords: allKeywords,
        confidence: 0.3,
      );
    }

    // Trier par score décroissant
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mainDomain = sorted.first.key;
    final maxScore = sorted.first.value;

    // Domaines secondaires : score >= 50% du max ET au moins 1 mot-clé
    final secondaryDomains = sorted
        .skip(1)
        .where((e) => e.value >= (maxScore * 0.4).round() && e.value >= 1)
        .take(3)
        .map((e) => e.key)
        .toList();

    // Confiance basée sur le score max
    final totalKeywordsInDomain = _domainKeywords[mainDomain]!.length;
    final confidence = (maxScore / totalKeywordsInDomain)
        .clamp(0.0, 1.0)
        .toDouble();

    // Détecter tous les mots-clés trouvés
    final detectedKeywords = _domainKeywords.values
        .expand((kws) => kws)
        .where((kw) => combined.contains(kw))
        .toSet()
        .take(20)
        .toList();

    return DomainClassification(
      mainDomain: mainDomain,
      secondaryDomains: secondaryDomains,
      detectedKeywords: detectedKeywords,
      confidence: confidence,
    );
  }

  // ─────────────────────────────────────────
  // TITRE PROFESSIONNEL AUTOMATIQUE
  // ─────────────────────────────────────────

  static String inferTitle({
    required String rawText,
    required String mainDomain,
    required List<String> programmingLanguages,
    required List<String> frameworks,
    required List<ExperienceHint> experiences,
    required List<EducationHint> education,
  }) {
    final lower = rawText.toLowerCase();

    // 1. Chercher titre explicite dans le texte (ligne courte après le nom)
    final lines = rawText.split('\n').map((l) => l.trim()).toList();
    for (int i = 1; i < lines.length.clamp(0, 6); i++) {
      final line = lines[i];
      if (_looksLikeProfessionalTitle(line)) return line;
    }

    // 2. Titre basé sur le domaine + technologies principales
    switch (mainDomain) {
      case 'Mobile Development':
        if (lower.contains('flutter')) return 'Développeur Flutter';
        if (lower.contains('android')) return 'Développeur Android';
        if (lower.contains('ios')) return 'Développeur iOS';
        return 'Développeur Mobile';

      case 'Web Development':
        if (lower.contains('fullstack') || lower.contains('full-stack')) {
          return 'Développeur Full Stack';
        }
        if (lower.contains('frontend') || lower.contains('front-end')) {
          return 'Développeur Frontend';
        }
        if (lower.contains('backend') || lower.contains('back-end')) {
          return 'Développeur Backend';
        }
        if (lower.contains('react')) return 'Développeur React';
        if (lower.contains('angular')) return 'Développeur Angular';
        return 'Développeur Web';

      case 'Data Science / AI':
        if (lower.contains('machine learning'))
          return 'Ingénieur Machine Learning';
        if (lower.contains('data engineer')) return 'Data Engineer';
        return 'Data Scientist';

      case 'DevOps / Cloud':
        if (lower.contains('cloud')) return 'Ingénieur Cloud';
        return 'Ingénieur DevOps';

      case 'Cybersecurity':
        return 'Analyste Cybersécurité';

      case 'UI/UX Design':
        return 'Designer UI/UX';

      case 'Embedded Systems / IoT':
        return 'Ingénieur Systèmes Embarqués';

      default:
        // Étudiant ?
        if (education.any((e) => e.isOngoing)) {
          return 'Étudiant en Informatique';
        }
        if (experiences.isEmpty) {
          return 'Étudiant en Informatique';
        }
        return 'Développeur Logiciel';
    }
  }

  static bool _looksLikeProfessionalTitle(String line) {
    if (line.length > 60 || line.length < 5) return false;
    const titleKeywords = [
      'développeur',
      'developer',
      'ingénieur',
      'engineer',
      'designer',
      'consultant',
      'analyste',
      'analyst',
      'étudiant',
      'student',
      'data',
      'devops',
      'architecte',
      'architect',
      'fullstack',
      'full stack',
    ];
    final lower = line.toLowerCase();
    return titleKeywords.any((kw) => lower.contains(kw));
  }
}

// DTOs légers pour la classification
class ExperienceHint {
  final String poste;
  final bool isOngoing;
  ExperienceHint({required this.poste, this.isOngoing = false});
}

class EducationHint {
  final String diplome;
  final bool isOngoing;
  EducationHint({required this.diplome, this.isOngoing = false});
}
