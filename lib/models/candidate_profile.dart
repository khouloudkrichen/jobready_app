// ============================================================
// candidate_profile.dart
// Modèle de données complet du profil candidat dynamique
// Avec detectedCvLanguage
// ============================================================

class ExperienceItem {
  final String poste;
  final String entreprise;
  final String periode;
  final String description;
  final List<String> technologies;

  ExperienceItem({
    required this.poste,
    required this.entreprise,
    this.periode = '',
    this.description = '',
    this.technologies = const [],
  });

  Map<String, dynamic> toJson() => {
    'poste': poste,
    'entreprise': entreprise,
    'periode': periode,
    'description': description,
    'technologies': technologies,
  };

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
    poste: json['poste'] ?? '',
    entreprise: json['entreprise'] ?? '',
    periode: json['periode'] ?? '',
    description: json['description'] ?? '',
    technologies: List<String>.from(json['technologies'] ?? []),
  );
}

class EducationItem {
  final String diplome;
  final String etablissement;
  final String periode;
  final String specialite;
  final String description;

  EducationItem({
    required this.diplome,
    required this.etablissement,
    this.periode = '',
    this.specialite = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'diplome': diplome,
    'etablissement': etablissement,
    'periode': periode,
    'specialite': specialite,
    'description': description,
  };

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
    diplome: json['diplome'] ?? '',
    etablissement: json['etablissement'] ?? '',
    periode: json['periode'] ?? '',
    specialite: json['specialite'] ?? '',
    description: json['description'] ?? '',
  );
}

class ProjectItem {
  final String nom;
  final String description;
  final List<String> technologies;
  final String periode;

  ProjectItem({
    required this.nom,
    this.description = '',
    this.technologies = const [],
    this.periode = '',
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'technologies': technologies,
    'periode': periode,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    nom: json['nom'] ?? '',
    description: json['description'] ?? '',
    technologies: List<String>.from(json['technologies'] ?? []),
    periode: json['periode'] ?? '',
  );
}

class CertificationItem {
  final String nom;
  final String organisme;
  final String annee;

  CertificationItem({required this.nom, this.organisme = '', this.annee = ''});

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'organisme': organisme,
    'annee': annee,
  };

  factory CertificationItem.fromJson(Map<String, dynamic> json) =>
      CertificationItem(
        nom: json['nom'] ?? '',
        organisme: json['organisme'] ?? '',
        annee: json['annee'] ?? '',
      );
}

class LanguageItem {
  final String langue;
  final String niveau;

  LanguageItem({required this.langue, this.niveau = ''});

  Map<String, dynamic> toJson() => {'langue': langue, 'niveau': niveau};

  factory LanguageItem.fromJson(Map<String, dynamic> json) =>
      LanguageItem(langue: json['langue'] ?? '', niveau: json['niveau'] ?? '');
}

class CandidateProfile {
  // Informations personnelles
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String github;
  final String portfolio;

  // Identité professionnelle
  final String profileTitle;
  final String summary;

  // Langue du CV détectée par ML Kit Language Identification
  // Exemple : Français, Anglais, Arabe...
  final String detectedCvLanguage;

  // Expériences, formation, projets, certifications
  final List<ExperienceItem> experiences;
  final List<EducationItem> education;
  final List<ProjectItem> projects;
  final List<CertificationItem> certifications;

  // Compétences classées
  final List<String> programmingLanguages;
  final List<String> frameworks;
  final List<String> databases;
  final List<String> tools;
  final List<String> technicalSkills;
  final List<String> softSkills;

  // Langues parlées par le candidat
  // Attention : différent de detectedCvLanguage
  final List<LanguageItem> spokenLanguages;

  // Vie associative / centres d'intérêt
  final List<String> associations;

  // Domaines
  final String mainDomain;
  final List<String> secondaryDomains;
  final List<String> detectedKeywords;

  // Scores de confiance
  // Tu peux les garder dans le modèle sans les afficher dans l'interface.
  final double nameConfidence;
  final double contactConfidence;
  final double skillsConfidence;
  final double experienceConfidence;
  final double educationConfidence;
  final double domainConfidence;
  final double overallProfileConfidence;

  CandidateProfile({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.github = '',
    this.portfolio = '',
    this.profileTitle = '',
    this.summary = '',
    this.detectedCvLanguage = '',
    this.experiences = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.programmingLanguages = const [],
    this.frameworks = const [],
    this.databases = const [],
    this.tools = const [],
    this.technicalSkills = const [],
    this.softSkills = const [],
    this.spokenLanguages = const [],
    this.associations = const [],
    this.mainDomain = '',
    this.secondaryDomains = const [],
    this.detectedKeywords = const [],
    this.nameConfidence = 0.0,
    this.contactConfidence = 0.0,
    this.skillsConfidence = 0.0,
    this.experienceConfidence = 0.0,
    this.educationConfidence = 0.0,
    this.domainConfidence = 0.0,
    this.overallProfileConfidence = 0.0,
  });

  bool get hasContact => email.isNotEmpty || phone.isNotEmpty;

  bool get hasSocialLinks =>
      linkedin.isNotEmpty || github.isNotEmpty || portfolio.isNotEmpty;

  bool get hasExperiences => experiences.isNotEmpty;

  bool get hasEducation => education.isNotEmpty;

  bool get hasProjects => projects.isNotEmpty;

  bool get hasCertifications => certifications.isNotEmpty;

  bool get hasSkills =>
      programmingLanguages.isNotEmpty ||
      frameworks.isNotEmpty ||
      databases.isNotEmpty ||
      tools.isNotEmpty ||
      technicalSkills.isNotEmpty;

  bool get hasSoftSkills => softSkills.isNotEmpty;

  bool get hasLanguages => spokenLanguages.isNotEmpty;

  bool get hasAssociations => associations.isNotEmpty;

  bool get hasDetectedCvLanguage => detectedCvLanguage.isNotEmpty;

  // Initiales pour l'avatar
  String get initials {
    if (fullName.trim().isEmpty) return '?';

    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return fullName.trim()[0].toUpperCase();
  }

  // Toutes les compétences techniques réunies
  List<String> get allTechnicalSkills => [
    ...programmingLanguages,
    ...frameworks,
    ...databases,
    ...tools,
    ...technicalSkills,
  ].toSet().toList();

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedin': linkedin,
    'github': github,
    'portfolio': portfolio,
    'profileTitle': profileTitle,
    'summary': summary,
    'detectedCvLanguage': detectedCvLanguage,
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'education': education.map((e) => e.toJson()).toList(),
    'projects': projects.map((e) => e.toJson()).toList(),
    'certifications': certifications.map((e) => e.toJson()).toList(),
    'programmingLanguages': programmingLanguages,
    'frameworks': frameworks,
    'databases': databases,
    'tools': tools,
    'technicalSkills': technicalSkills,
    'softSkills': softSkills,
    'spokenLanguages': spokenLanguages.map((e) => e.toJson()).toList(),
    'associations': associations,
    'mainDomain': mainDomain,
    'secondaryDomains': secondaryDomains,
    'detectedKeywords': detectedKeywords,
    'nameConfidence': nameConfidence,
    'contactConfidence': contactConfidence,
    'skillsConfidence': skillsConfidence,
    'experienceConfidence': experienceConfidence,
    'educationConfidence': educationConfidence,
    'domainConfidence': domainConfidence,
    'overallProfileConfidence': overallProfileConfidence,
  };

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      linkedin: json['linkedin'] ?? '',
      github: json['github'] ?? '',
      portfolio: json['portfolio'] ?? '',
      profileTitle: json['profileTitle'] ?? '',
      summary: json['summary'] ?? '',
      detectedCvLanguage: json['detectedCvLanguage'] ?? '',

      experiences: (json['experiences'] as List? ?? [])
          .map((e) => ExperienceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      education: (json['education'] as List? ?? [])
          .map((e) => EducationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      projects: (json['projects'] as List? ?? [])
          .map((e) => ProjectItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      certifications: (json['certifications'] as List? ?? [])
          .map((e) => CertificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      programmingLanguages: List<String>.from(
        json['programmingLanguages'] ?? [],
      ),
      frameworks: List<String>.from(json['frameworks'] ?? []),
      databases: List<String>.from(json['databases'] ?? []),
      tools: List<String>.from(json['tools'] ?? []),
      technicalSkills: List<String>.from(json['technicalSkills'] ?? []),
      softSkills: List<String>.from(json['softSkills'] ?? []),

      spokenLanguages: (json['spokenLanguages'] as List? ?? [])
          .map((e) => LanguageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      associations: List<String>.from(json['associations'] ?? []),

      mainDomain: json['mainDomain'] ?? '',
      secondaryDomains: List<String>.from(json['secondaryDomains'] ?? []),
      detectedKeywords: List<String>.from(json['detectedKeywords'] ?? []),

      nameConfidence: _toDouble(json['nameConfidence']),
      contactConfidence: _toDouble(json['contactConfidence']),
      skillsConfidence: _toDouble(json['skillsConfidence']),
      experienceConfidence: _toDouble(json['experienceConfidence']),
      educationConfidence: _toDouble(json['educationConfidence']),
      domainConfidence: _toDouble(json['domainConfidence']),
      overallProfileConfidence: _toDouble(json['overallProfileConfidence']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
