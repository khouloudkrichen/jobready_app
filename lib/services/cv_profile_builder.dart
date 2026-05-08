// ============================================================
// cv_profile_builder.dart — v9 propre
// Objectif :
// 1. Groq extrait le profil depuis le CV
// 2. La langue détectée est transmise au prompt
// 3. Fallback regex sécurisé : il n'invente plus de domaine/titre/résumé
// 4. Associations filtrées pour éviter "vice de votre entreprise", nom, poste...
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/candidate_profile.dart';
import 'cv_parser_service.dart';

class CvProfileBuilder {
  // ⚠️ Remplace par ta vraie clé Groq.
  // Ne mets jamais ta clé sur GitHub.
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';

  // ============================================================
  // POINT D'ENTRÉE
  // ============================================================

  static Future<CandidateProfile> buildAsync(
    String rawOcrText, {
    String detectedCvLanguage = '',
  }) async {
    if (rawOcrText.trim().isEmpty) {
      return CandidateProfile(detectedCvLanguage: detectedCvLanguage);
    }

    try {
      final profile = await _buildWithGroq(
        rawOcrText,
        detectedCvLanguage: detectedCvLanguage,
      );

      if (profile != null && profile.fullName.isNotEmpty) {
        print("✅ Groq OK — nom: ${profile.fullName}");
        print("🌍 Langue profil: ${profile.detectedCvLanguage}");
        return profile;
      }

      print("⚠️ Groq vide → fallback sécurisé");
    } catch (e) {
      print("⚠️ Groq erreur → fallback sécurisé: $e");
    }

    return build(rawOcrText, detectedCvLanguage: detectedCvLanguage);
  }

  // ============================================================
  // GROQ : EXTRACTION PRINCIPALE
  // ============================================================

  static Future<CandidateProfile?> _buildWithGroq(
    String ocrText, {
    String detectedCvLanguage = '',
  }) async {
    final prompt =
        '''
Tu es un expert RH en analyse de CV.

Analyse le texte OCR ci-dessous et retourne UNIQUEMENT un JSON valide.
Aucun markdown. Aucun commentaire. Aucun texte hors JSON.

LANGUE DETECTEE DU CV :
$detectedCvLanguage

REGLE LANGUE :
- Le profil doit être rédigé dans la même langue dominante que le CV.
- Si le CV est en français, écris le profil en français.
- Si le CV est en anglais, écris le profil en anglais.
- Si le CV est en arabe, écris le profil en arabe.
- Ne traduis jamais : nom, email, téléphone, entreprises, écoles, technologies, liens.
- Ne rajoute aucune information absente du CV.

TEXTE OCR :
---
$ocrText
---

RETOURNE EXACTEMENT CE JSON :
{
  "fullName": "",
  "email": "",
  "phone": "",
  "location": "",
  "linkedin": "",
  "github": "",
  "portfolio": "",
  "profileTitle": "",
  "summary": "",
  "detectedCvLanguage": "",
  "mainDomain": "",
  "secondaryDomains": [],
  "programmingLanguages": [],
  "frameworks": [],
  "databases": [],
  "tools": [],
  "technicalSkills": [],
  "softSkills": [],
  "spokenLanguages": [{"langue": "", "niveau": ""}],
  "experiences": [{"poste": "", "entreprise": "", "periode": "", "description": "", "technologies": []}],
  "education": [{"diplome": "", "etablissement": "", "periode": "", "specialite": "", "description": ""}],
  "projects": [{"nom": "", "description": "", "technologies": [], "periode": ""}],
  "certifications": [{"nom": "", "organisme": "", "annee": ""}],
  "associations": []
}

REGLES STRICTES :
1. fullName : nom complet du candidat uniquement. Ne prends jamais un slogan ou une phrase.
2. profileTitle : titre réel du CV. Exemple : HR Manager, Commercial, Développeur, Designer Graphique.
   - Ne mets jamais une qualité personnelle comme titre.
   - Ne mets jamais "Travailleuse", "Dynamique", "Rigoureux", "Results-oriented".
3. summary : résumé court basé uniquement sur le CV. Pas d'évaluation. Pas de conseil. Pas de score.
4. mainDomain : domaine uniquement s'il est évident dans le CV.
   - Ne mets pas Data Science, UI/UX, Cybersecurity ou Software Engineering si ce n'est pas écrit ou clairement lié.
   - Si ce n'est pas clair, mets "".
5. secondaryDomains : uniquement les domaines réellement visibles dans le CV. Sinon [].
6. experiences : uniquement emplois, stages, alternances, missions professionnelles.
   - Ne mets jamais les bullet points seuls comme expériences.
   - Ne mets jamais les loisirs, langues, références ou centres d'intérêt dans experiences.
   - Une expérience doit avoir au minimum un poste ou une entreprise.
7. education : formations académiques uniquement.
   - Ne mets pas les numéros de téléphone dans période ou spécialité.
8. projects : projets académiques/personnels/professionnels clairement présents.
9. certifications : certifications seulement si elles existent clairement.
10. programmingLanguages : langages seulement : Java, Python, Dart, C, C++, JavaScript, R, etc.
    - Ne mets pas "R" sauf si la lettre R apparaît vraiment comme compétence/langage dans le CV.
11. frameworks : Flutter, Angular, React, Spring Boot, Node.js, Laravel, etc.
12. databases : MySQL, MongoDB, Oracle, Firebase, PostgreSQL, etc.
13. tools : Git, Docker, Figma, VS Code, Trello, StarUML, etc.
14. technicalSkills : mots-clés courts seulement. Pas de phrases longues.
15. softSkills : compétences humaines courtes : communication, leadership, autonomie, rigueur...
16. spokenLanguages : langues parlées par le candidat seulement.
    - Ne mets pas la langue du CV ici sauf si elle est dans la section Langues/Languages.
17. associations : uniquement centres d'intérêt, loisirs, clubs, bénévolat, engagements.
    - Ne mets jamais le nom du candidat.
    - Ne mets jamais le poste.
    - Ne mets jamais une phrase issue du résumé ou des expériences.
    - Exemples valides : Horse riding, Going to the theatre, Bénévolat, Randonnée, Triathlon.
18. Aucune donnée inventée. Si absent : "" ou [].
''';

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: jsonEncode({
            'model': _groqModel,
            'temperature': 0.02,
            'max_tokens': 4096,
            'messages': [
              {
                'role': 'system',
                'content':
                    'Tu es un expert RH. Tu réponds uniquement avec un JSON valide, sans markdown, sans explication.',
              },
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 35));

    print("🤖 Groq status: ${response.statusCode}");

    if (response.statusCode != 200) {
      print("🤖 Groq erreur body: ${response.body}");
      return null;
    }

    final data = jsonDecode(response.body);
    final answer = (data['choices']?[0]?['message']?['content'] ?? '')
        .toString()
        .trim();

    final jsonText = _extractJsonObject(answer);

    print("🤖 Groq JSON reçu: $jsonText");

    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;

    return _fromJson(
      parsed,
      originalText: ocrText,
      detectedCvLanguage: detectedCvLanguage,
    );
  }

  // ============================================================
  // JSON → CandidateProfile
  // ============================================================

  static CandidateProfile _fromJson(
    Map<String, dynamic> j, {
    required String originalText,
    String detectedCvLanguage = '',
  }) {
    String str(String key) {
      final value = j[key];
      if (value == null) return '';
      return value.toString().trim();
    }

    List<T> list<T>(String key, T Function(Map<String, dynamic>) fn) {
      final raw = j[key];
      if (raw == null || raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(fn)
          .toList();
    }

    List<String> strList(String key) {
      final raw = j[key];
      if (raw == null || raw is! List) return [];
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .where((e) => e.length <= 60)
          .toSet()
          .toList();
    }

    List<String> skills(String key, {bool programming = false}) {
      final raw = j[key];
      if (raw == null || raw is! List) return [];

      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .where((e) => e.length <= 30)
          .where((e) => !_looksLikeNoise(e))
          .where((e) {
            if (programming && e.length == 1) {
              return _singleLetterSkillExistsInCv(e, originalText);
            }
            return true;
          })
          .toSet()
          .toList();
    }

    final fullName = str('fullName');
    final languageFromAi = str('detectedCvLanguage');
    final finalDetectedLanguage = languageFromAi.isNotEmpty
        ? languageFromAi
        : detectedCvLanguage;

    final experiences = list(
      'experiences',
      (m) => ExperienceItem(
        poste: (m['poste'] ?? '').toString().trim(),
        entreprise: (m['entreprise'] ?? '').toString().trim(),
        periode: _cleanPeriod((m['periode'] ?? '').toString()),
        description: (m['description'] ?? '').toString().trim(),
        technologies: _cleanStringList(m['technologies']),
      ),
    ).where(_isValidExperience).toList();

    final education = list(
      'education',
      (m) => EducationItem(
        diplome: (m['diplome'] ?? '').toString().trim(),
        etablissement: (m['etablissement'] ?? '').toString().trim(),
        periode: _cleanPeriod((m['periode'] ?? '').toString()),
        specialite: _cleanEducationField((m['specialite'] ?? '').toString()),
        description: _cleanEducationField((m['description'] ?? '').toString()),
      ),
    ).where((e) => e.diplome.isNotEmpty || e.etablissement.isNotEmpty).toList();

    final projects = list(
      'projects',
      (m) => ProjectItem(
        nom: (m['nom'] ?? '').toString().trim(),
        description: (m['description'] ?? '').toString().trim(),
        technologies: _cleanStringList(m['technologies']),
        periode: _cleanPeriod((m['periode'] ?? '').toString()),
      ),
    ).where((p) => p.nom.isNotEmpty && !_looksLikeNoise(p.nom)).toList();

    final certifications = list(
      'certifications',
      (m) => CertificationItem(
        nom: (m['nom'] ?? '').toString().trim(),
        organisme: (m['organisme'] ?? '').toString().trim(),
        annee: _cleanPeriod((m['annee'] ?? '').toString()),
      ),
    ).where((c) => c.nom.isNotEmpty && !_looksLikeNoise(c.nom)).toList();

    final spokenLanguages = list(
      'spokenLanguages',
      (m) => LanguageItem(
        langue: (m['langue'] ?? '').toString().trim(),
        niveau: (m['niveau'] ?? '').toString().trim(),
      ),
    ).where((l) => l.langue.isNotEmpty && !_looksLikeNoise(l.langue)).toList();

    final associations = _cleanAssociations(j['associations'], fullName);

    final progLangs = skills('programmingLanguages', programming: true);
    final frameworks = skills('frameworks');
    final databases = skills('databases');
    final tools = skills('tools');
    final techSkills = skills('technicalSkills');
    final softSkills = skills('softSkills');

    final mainDomain = str('mainDomain');
    final totalSkills =
        progLangs.length +
        frameworks.length +
        databases.length +
        tools.length +
        techSkills.length;

    return CandidateProfile(
      fullName: fullName,
      email: str('email'),
      phone: str('phone'),
      location: str('location'),
      linkedin: str('linkedin'),
      github: str('github'),
      portfolio: str('portfolio'),
      profileTitle: _cleanTitle(str('profileTitle')),
      summary: str('summary'),
      detectedCvLanguage: finalDetectedLanguage,
      mainDomain: mainDomain,
      secondaryDomains: strList('secondaryDomains'),
      detectedKeywords: [],
      experiences: experiences,
      education: education,
      projects: projects,
      certifications: certifications,
      programmingLanguages: progLangs,
      frameworks: frameworks,
      databases: databases,
      tools: tools,
      technicalSkills: techSkills,
      softSkills: softSkills,
      spokenLanguages: spokenLanguages,
      associations: associations,

      // Gardés dans le modèle mais non affichés
      nameConfidence: fullName.split(RegExp(r'\s+')).length >= 2
          ? 0.95
          : (fullName.isNotEmpty ? 0.5 : 0.0),
      contactConfidence: str('email').isNotEmpty ? 0.9 : 0.4,
      skillsConfidence: (totalSkills / 10).clamp(0.0, 1.0).toDouble(),
      experienceConfidence: (experiences.length / 3).clamp(0.0, 1.0).toDouble(),
      educationConfidence: (education.length / 2).clamp(0.0, 1.0).toDouble(),
      domainConfidence: mainDomain.isNotEmpty ? 0.8 : 0.0,
      overallProfileConfidence: 0.0,
    );
  }

  // ============================================================
  // FALLBACK REGEX SÉCURISÉ
  // Important : il n'invente plus de titre/domaine/résumé
  // ============================================================

  static CandidateProfile build(
    String rawOcrText, {
    String detectedCvLanguage = '',
  }) {
    if (rawOcrText.trim().isEmpty) {
      return CandidateProfile(detectedCvLanguage: detectedCvLanguage);
    }

    final p = CvParserService.parse(rawOcrText);

    final fullName = (p['fullName'] as String? ?? '').trim();
    final email = (p['email'] as String? ?? '').trim();
    final phone = (p['phone'] as String? ?? '').trim();
    final location = (p['location'] as String? ?? '').trim();
    final linkedin = (p['linkedin'] as String? ?? '').trim();
    final github = (p['github'] as String? ?? '').trim();
    final portfolio = (p['portfolio'] as String? ?? '').trim();

    final experiences = List<ExperienceItem>.from(
      p['experiences'] ?? [],
    ).where(_isValidExperience).toList();

    final education = List<EducationItem>.from(p['education'] ?? [])
        .map(
          (e) => EducationItem(
            diplome: e.diplome,
            etablissement: e.etablissement,
            periode: _cleanPeriod(e.periode),
            specialite: _cleanEducationField(e.specialite),
            description: _cleanEducationField(e.description),
          ),
        )
        .where((e) => e.diplome.isNotEmpty || e.etablissement.isNotEmpty)
        .toList();

    final projects = List<ProjectItem>.from(
      p['projects'] ?? [],
    ).where((e) => e.nom.isNotEmpty && !_looksLikeNoise(e.nom)).toList();

    final certifications = List<CertificationItem>.from(
      p['certifications'] ?? [],
    ).where((e) => e.nom.isNotEmpty && !_looksLikeNoise(e.nom)).toList();

    final progLangs = _cleanFallbackSkills(
      List<String>.from(p['programmingLanguages'] ?? []),
      rawOcrText,
      programming: true,
    );

    final frameworks = _cleanFallbackSkills(
      List<String>.from(p['frameworks'] ?? []),
      rawOcrText,
    );

    final databases = _cleanFallbackSkills(
      List<String>.from(p['databases'] ?? []),
      rawOcrText,
    );

    final tools = _cleanFallbackSkills(
      List<String>.from(p['tools'] ?? []),
      rawOcrText,
    );

    final techSkills = _cleanFallbackSkills(
      List<String>.from(p['technicalSkills'] ?? []),
      rawOcrText,
    );

    final softSkills = _cleanFallbackSkills(
      List<String>.from(p['softSkills'] ?? []),
      rawOcrText,
    );

    final languages = List<LanguageItem>.from(
      p['spokenLanguages'] ?? [],
    ).where((l) => l.langue.isNotEmpty && !_looksLikeNoise(l.langue)).toList();

    final associations = _cleanAssociations(p['associations'], fullName);

    final totalSkills =
        progLangs.length +
        frameworks.length +
        databases.length +
        tools.length +
        techSkills.length;

    final nameConf = fullName.split(RegExp(r'\s+')).length >= 2
        ? 0.95
        : (fullName.isNotEmpty ? 0.5 : 0.0);

    final contactConf = _clamp(
      (email.isNotEmpty ? 0.45 : 0.0) +
          (phone.isNotEmpty ? 0.35 : 0.0) +
          (linkedin.isNotEmpty ? 0.20 : 0.0),
    );

    return CandidateProfile(
      fullName: fullName,
      email: email,
      phone: phone,
      location: location,
      linkedin: linkedin,
      github: github,
      portfolio: portfolio,

      // Fallback sécurisé : ne pas inventer
      profileTitle: '',
      summary: '',
      detectedCvLanguage: detectedCvLanguage,
      mainDomain: '',
      secondaryDomains: const [],
      detectedKeywords: const [],

      experiences: experiences,
      education: education,
      projects: projects,
      certifications: certifications,
      programmingLanguages: progLangs,
      frameworks: frameworks,
      databases: databases,
      tools: tools,
      technicalSkills: techSkills,
      softSkills: softSkills,
      spokenLanguages: languages,
      associations: associations,

      nameConfidence: nameConf,
      contactConfidence: contactConf,
      skillsConfidence: _clamp(totalSkills / 12.0),
      experienceConfidence: _clamp(experiences.length / 3.0),
      educationConfidence: _clamp(education.length / 2.0),
      domainConfidence: 0.0,
      overallProfileConfidence: 0.0,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _extractJsonObject(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start >= 0 && end > start) {
      return cleaned.substring(start, end + 1);
    }

    return cleaned;
  }

  static List<String> _cleanStringList(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .where((e) => e.length <= 40)
        .where((e) => !_looksLikeNoise(e))
        .toSet()
        .toList();
  }

  static List<String> _cleanFallbackSkills(
    List<String> values,
    String originalText, {
    bool programming = false,
  }) {
    return values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => e.length <= 30)
        .where((e) => !_looksLikeNoise(e))
        .where((e) {
          if (programming && e.length == 1) {
            return _singleLetterSkillExistsInCv(e, originalText);
          }
          return true;
        })
        .toSet()
        .toList();
  }

  static List<String> _cleanAssociations(dynamic raw, String fullName) {
    if (raw == null || raw is! List) return [];

    final lowerName = fullName.toLowerCase();

    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .where((e) => e.length <= 70)
        .where((e) => !_looksLikeNoise(e))
        .where((e) {
          if (lowerName.isEmpty) return true;
          return !e.toLowerCase().contains(lowerName);
        })
        .toSet()
        .toList();
  }

  static bool _isValidExperience(ExperienceItem e) {
    final poste = e.poste.trim();
    final entreprise = e.entreprise.trim();
    final periode = e.periode.trim();
    final description = e.description.trim();

    if (poste.isEmpty && entreprise.isEmpty) return false;

    final combined = '$poste $entreprise $description'.toLowerCase();

    final bad = [
      'langues',
      'languages',
      'hobbies',
      'loisirs',
      'centres d',
      'references',
      'références',
      'formation',
      'education',
      'skills',
      'compétences',
      'intitulé du poste',
      'objectif',
      'objective',
    ];

    if (bad.any((b) => combined.contains(b))) return false;

    // Rejeter les bullet points seuls transformés en expériences
    if (entreprise.isEmpty && periode.isEmpty && poste.length > 45) {
      return false;
    }

    return true;
  }

  static String _cleanTitle(String title) {
    final t = title.trim();
    if (t.isEmpty) return '';

    final lower = t.toLowerCase();

    final bad = [
      'results-oriented',
      'motivated',
      'dynamic',
      'dynamique',
      'rigoureux',
      'rigoureuse',
      'travailleuse',
      'travailleur',
      'passionné',
      'passionnee',
      'passionnée',
      'objectif',
      'objective',
    ];

    if (bad.any((b) => lower.contains(b)) && t.split(' ').length > 3) {
      return '';
    }

    if (t.length > 55) return '';

    return t;
  }

  static String _cleanPeriod(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';

    final digits = v.replaceAll(RegExp(r'\D'), '');

    // Numéro de téléphone détecté par erreur
    if (digits.length >= 8 && !RegExp(r'20\d{2}|19\d{2}').hasMatch(v)) {
      return '';
    }

    return v;
  }

  static String _cleanEducationField(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';

    final digits = v.replaceAll(RegExp(r'\D'), '');

    if (digits.length >= 8) return '';
    if (_looksLikeNoise(v)) return '';

    return v;
  }

  static bool _singleLetterSkillExistsInCv(String value, String originalText) {
    final escaped = RegExp.escape(value);
    final rx = RegExp(
      r'(^|[\s,;:/\-\n])' + escaped + r'($|[\s,;:/\-\n])',
      caseSensitive: false,
    );
    return rx.hasMatch(originalText);
  }

  static bool _looksLikeNoise(String value) {
    final s = value.toLowerCase().trim();

    if (s.isEmpty) return true;
    if (s.contains('@')) return true;

    // Numéro, téléphone, dates longues
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) return true;

    final badWords = [
      'votre entreprise',
      'service sollicité',
      'service sollicite',
      'vice de votre entreprise',
      'vice sollicité',
      'vice sollicite',
      'profil',
      'contact',
      'objective',
      'references',
      'références',
      'experience',
      'expérience',
      'formation',
      'education',
      'work experience',
      'intitulé du poste',
      'intitule du poste',
      'poste / stage',
      'stage',
      'email',
      'phone',
      'téléphone',
      'telephone',
      'adresse',
      'location',
      'hr manager',
      'commercial',
      'assistant commercial',
      'manager',
      'designer ui/ux',
      'data scientist',
    ];

    if (badWords.any((w) => s.contains(w))) return true;

    // Phrase trop longue = souvent description, pas compétence/loisir
    if (s.split(RegExp(r'\s+')).length > 7) return true;

    return false;
  }

  static double _clamp(double v) => v.clamp(0.0, 1.0).toDouble();
}
