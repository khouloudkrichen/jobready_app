// ============================================================
// cv_parser_service.dart — v4 UNIVERSEL
// Compatible avec TOUT type de CV :
//   • FR / EN / AR / mixte
//   • Étudiant / Professionnel / Senior
//   • Avec ou sans sections explicites
//   • Bullet points (•, -, *, ▪) ou texte libre
//   • OCR bruité, lignes fusionnées, ordre variable
//   • Formats : "MM/YYYY – MM/YYYY", "jan 2023 – présent", "2021-2024"
// ============================================================

import '../models/candidate_profile.dart';

class CvParserService {
  // ═══════════════════════════════════════════════════════════
  // POINT D'ENTRÉE
  // ═══════════════════════════════════════════════════════════

  static Map<String, dynamic> parse(String rawText) {
    // Nettoyage universel du texte OCR
    final cleaned = _cleanOcr(rawText);
    final lines = _toLines(cleaned);
    final text = cleaned.toLowerCase();

    // Découper en sections nommées
    final sections = _splitIntoSections(lines);

    return {
      'fullName': _extractName(lines, cleaned),
      'email': _extractEmail(cleaned),
      'phone': _extractPhone(cleaned),
      'location': _extractLocation(cleaned, lines),
      'linkedin': _extractLinkedIn(cleaned),
      'github': _extractGitHub(cleaned),
      'portfolio': _extractPortfolio(cleaned),
      'experiences': _extractExperiences(sections, text),
      'education': _extractEducation(sections, text),
      'projects': _extractProjects(sections, text),
      'certifications': _extractCertifications(sections),
      'programmingLanguages': _matchList(text, _kLangs),
      'frameworks': _matchList(text, _kFrameworks),
      'databases': _matchList(text, _kDatabases),
      'tools': _matchList(text, _kTools),
      'technicalSkills': _matchList(text, _kTechSkills),
      'softSkills': _matchList(text, _kSoftSkills),
      'spokenLanguages': _extractLanguages(sections, text),
      'associations': _extractAssociations(sections, text),
    };
  }

  // ═══════════════════════════════════════════════════════════
  // NETTOYAGE OCR UNIVERSEL
  // ═══════════════════════════════════════════════════════════

  static String _cleanOcr(String raw) {
    return raw
        .replaceAll(
          RegExp(r'[|\u25CF\u25AA\u25B8\u25BA]'),
          ' ',
        ) // artefacts OCR
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ') // espaces multiples → 1
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // sauts excessifs → 2
        .replaceAll(
          RegExp(r'^\s*[\u2022\-\*]\s*', multiLine: true),
          '',
        ) // bullets
        .trim();
  }

  static List<String> _toLines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  // ═══════════════════════════════════════════════════════════
  // DÉCOUPAGE EN SECTIONS (universel)
  // Détecte automatiquement les titres de section dans FR/EN
  // ═══════════════════════════════════════════════════════════

  static const _sectionAliases = <String, List<String>>{
    'experience': [
      'expérience professionnelle',
      'expériences professionnelles',
      'expérience',
      'experience',
      'professional experience',
      'work experience',
      'emploi',
      'parcours professionnel',
      'employment',
      'career',
    ],
    'education': [
      'formation académique',
      'formation',
      'éducation',
      'education',
      'études',
      'diplômes',
      'parcours académique',
      'academic background',
      'scolarité',
      'academic',
      'qualifications',
      'diplomas',
    ],
    'skills': [
      'compétences techniques',
      'compétences',
      'skills',
      'technical skills',
      'core skills',
      'competences',
      'aptitudes',
      'expertise',
    ],
    'languages': [
      'langues maîtrisées',
      'langues',
      'languages',
      'langue',
      'linguistic skills',
      'spoken languages',
    ],
    'projects': [
      'projets académiques',
      'projets personnels',
      'projets',
      'projects',
      'projet académique',
      'réalisations',
      'personal projects',
      'academic projects',
      'portfolio',
    ],
    'certifications': [
      'certifications',
      'certification',
      'certificats',
      'certificates',
      'diplômes professionnels',
      'licences',
    ],
    'summary': [
      'profil',
      'résumé',
      'summary',
      'about me',
      'about',
      'objective',
      'professional summary',
      'à propos',
      'profile',
      'présentation',
    ],
    'interests': [
      'loisirs',
      'hobbies',
      'intérêts',
      'centres d\'intérêt',
      'interests',
      'activities',
      'vie associative',
      'associative',
    ],
  };

  static Map<String, List<String>> _splitIntoSections(List<String> lines) {
    final sections = <String, List<String>>{};
    String currentKey = 'header';
    sections[currentKey] = [];

    for (final line in lines) {
      final detected = _detectSectionKey(line);
      if (detected != null) {
        currentKey = detected;
        sections.putIfAbsent(currentKey, () => []);
      } else {
        sections[currentKey]!.add(line);
      }
    }
    return sections;
  }

  static String? _detectSectionKey(String line) {
    final lower = line.toLowerCase().trim();
    // Trop long pour être un titre de section
    if (lower.length > 60) return null;
    // Doit ressembler à un titre (peu de mots, ou tout en majuscules)
    final wordCount = lower.split(RegExp(r'\s+')).length;
    if (wordCount > 6) return null;

    for (final entry in _sectionAliases.entries) {
      for (final alias in entry.value) {
        if (lower == alias ||
            lower.startsWith(alias) ||
            // Titre en MAJUSCULES ex: "EXPÉRIENCE PROFESSIONNELLE"
            lower.replaceAll(' ', '') == alias.replaceAll(' ', '')) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // NOM — universel : Prénom NOM / PRÉNOM NOM / prénom nom
  // ═══════════════════════════════════════════════════════════

  static String _extractName(List<String> lines, String raw) {
    // 1. Étiquette explicite
    final labelRx = RegExp(
      r'(?:^|\n)\s*(?:nom\s*[:\-]|name\s*[:\-])\s*([^\n]{2,40})',
      caseSensitive: false,
      multiLine: true,
    );
    final lm = labelRx.firstMatch(raw);
    if (lm != null) return _tc(lm.group(1)!.trim());

    // 2. Chercher dans les premières lignes du header
    for (int i = 0; i < lines.length.clamp(0, 10); i++) {
      final line = lines[i].trim();
      if (line.length < 3 || line.length > 55) continue;
      if (line.contains('@') ||
          line.contains('http') ||
          line.contains(':') ||
          line.contains('/'))
        continue;
      if (RegExp(r'\d').hasMatch(line)) continue;
      if (_detectSectionKey(line) != null) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2 || parts.length > 4) continue;

      // Chaque mot : lettres uniquement (accents, tiret, apostrophe OK)
      final wordRx = RegExp(
        r"^[A-Za-z\u00C0-\u024F][A-Za-z\u00C0-\u024F'\\-]+$",
      );
      if (parts.every((p) => p.isNotEmpty && wordRx.hasMatch(p))) {
        return _tc(line);
      }
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════════
  // EMAIL / TÉLÉPHONE
  // ═══════════════════════════════════════════════════════════

  static String _extractEmail(String text) {
    final rx = RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}');
    return rx.firstMatch(text)?.group(0) ?? '';
  }

  static String _extractPhone(String text) {
    // Supporte : +216 22 338 373 / 06.12.34.56.78 / (555) 123-4567
    final rx = RegExp(
      r'(?:\+\d{1,3}[\s.\-]?)?'
      r'(?:\(?\d{2,4}\)?[\s.\-]?){2,5}\d{2,4}',
    );
    // Prendre le premier match qui ressemble à un vrai numéro (≥ 8 chiffres)
    for (final m in rx.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8) return m.group(0)!.trim();
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════════
  // LOCALISATION — robuste, ne confond pas avec les langues
  // ═══════════════════════════════════════════════════════════

  static String _extractLocation(String raw, List<String> lines) {
    // 1. "Adresse: ..." ou "Location: ..."
    final addrRx = RegExp(
      r'(?:adresse|address|localisation|location|ville|city)\s*[:\-]\s*([^\n\t]{3,60})',
      caseSensitive: false,
    );
    final am = addrRx.firstMatch(raw);
    if (am != null) {
      // Prendre seulement la première partie (avant un tab ou double espace)
      final val = am.group(1)!.split(RegExp(r'\t|   '))[0].trim();
      if (!_isLangWord(val)) return val;
    }

    // 2. Villes et pays connus (liste exhaustive)
    const places = [
      'Sfax',
      'Tunis',
      'Sousse',
      'Monastir',
      'Bizerte',
      'Nabeul',
      'Gabès',
      'Gafsa',
      'Tunisie',
      'Tunisia',
      'Paris',
      'Lyon',
      'Marseille',
      'Bordeaux',
      'Toulouse',
      'Casablanca',
      'Rabat',
      'Maroc',
      'Alger',
      'Algérie',
      'Dakar',
      'Sénégal',
      'Montréal',
      'Canada',
      'Genève',
      'Lausanne',
      'Bruxelles',
      'Belgique',
      'Dubai',
      'UAE',
      'Riyadh',
    ];
    for (final p in places) {
      if (raw.contains(p)) {
        // Trouver la ligne contenant ce lieu (hors section langues)
        for (final line in lines) {
          if (line.contains(p) && line.length < 60 && !_isLangWord(line)) {
            return line.trim();
          }
        }
        return p;
      }
    }
    return '';
  }

  static bool _isLangWord(String s) {
    final l = s.toLowerCase();
    return [
      'français',
      'anglais',
      'arabe',
      'english',
      'arabic',
      'french',
      'natif',
      'courant',
      'fluent',
      'bilingue',
      'intermediate',
    ].any((w) => l.contains(w));
  }

  // ═══════════════════════════════════════════════════════════
  // RÉSEAUX SOCIAUX
  // ═══════════════════════════════════════════════════════════

  static String _extractLinkedIn(String text) {
    final urlRx = RegExp(
      r'linkedin\.com/in/([a-zA-Z0-9\-_%]+)',
      caseSensitive: false,
    );
    final um = urlRx.firstMatch(text);
    if (um != null) return 'https://linkedin.com/in/${um.group(1)}';

    final labelRx = RegExp(
      r'linkedin\s*[:\-]\s*([^\n]{3,50})',
      caseSensitive: false,
    );
    final lm = labelRx.firstMatch(text);
    if (lm != null) {
      final val = lm.group(1)!.trim();
      if (val.startsWith('http')) return val;
      final slug = val
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\- ]'), '')
          .trim()
          .replaceAll(' ', '-');
      return 'https://linkedin.com/in/$slug';
    }
    return '';
  }

  static String _extractGitHub(String text) {
    final urlRx = RegExp(
      r'github\.com/([a-zA-Z0-9\-_]+)',
      caseSensitive: false,
    );
    final um = urlRx.firstMatch(text);
    if (um != null) return 'https://github.com/${um.group(1)}';

    final labelRx = RegExp(
      r'github\s*[:\-]\s*([a-zA-Z0-9\-_\.]{3,40})',
      caseSensitive: false,
    );
    final lm = labelRx.firstMatch(text);
    if (lm != null) return 'https://github.com/${lm.group(1)!.trim()}';
    return '';
  }

  static String _extractPortfolio(String text) {
    final rx = RegExp(
      r'(?:portfolio|site web|website|personal site|site\s*perso)\s*[:\-]\s*(https?://[^\s]+)',
      caseSensitive: false,
    );
    final m = rx.firstMatch(text);
    if (m != null) return m.group(1)!;

    // URL non LinkedIn/GitHub
    final urlRx = RegExp(
      r'https?://(?!(?:www\.)?(?:linkedin|github))[^\s<>"]{5,}',
    );
    return urlRx.firstMatch(text)?.group(0) ?? '';
  }

  // ═══════════════════════════════════════════════════════════
  // EXPÉRIENCES — découpe par dates (robuste)
  // ═══════════════════════════════════════════════════════════

  static List<ExperienceItem> _extractExperiences(
    Map<String, List<String>> sections,
    String fullText,
  ) {
    final sectionLines = sections['experience'] ?? [];
    if (sectionLines.isEmpty) return _experienceFallback(fullText);

    final result = <ExperienceItem>[];
    String poste = '';
    String company = '';
    String period = '';
    final desc = <String>[];

    void flush() {
      if (poste.isEmpty && company.isEmpty) return;
      result.add(
        ExperienceItem(
          poste: poste.isNotEmpty ? poste : company,
          entreprise: poste.isNotEmpty ? company : '',
          periode: period,
          description: desc.join(' ').trim(),
          technologies: _techsIn(desc.join(' ')),
        ),
      );
      poste = '';
      company = '';
      period = '';
      desc.clear();
    }

    for (int i = 0; i < sectionLines.length; i++) {
      final line = sectionLines[i];
      final lower = line.toLowerCase();

      // Ligne de date seule → marque une nouvelle entrée
      if (_isPeriodLine(line)) {
        // Si la date est sur la même ligne que le titre (ex: "Stage X  07/2025 – 08/2025")
        // on la dissocie
        final titlePart = _removePeriod(line).trim();
        if (titlePart.isNotEmpty) {
          flush();
          poste = titlePart;
          period = _extractPeriod(line);
        } else {
          period = _extractPeriod(line);
        }
        continue;
      }

      // Titre de poste / stage
      if (_isJobTitle(line) && company.isEmpty) {
        if (poste.isNotEmpty) flush();
        poste = line;
        continue;
      }

      // Entreprise (après le titre, avant la description)
      if (poste.isNotEmpty &&
          company.isEmpty &&
          !_isPeriodLine(line) &&
          _isCompanyLine(line)) {
        company = line;
        continue;
      }

      // Nouveau titre alors qu'on a déjà un bloc → flush
      if (_isJobTitle(line) && poste.isNotEmpty && company.isNotEmpty) {
        flush();
        poste = line;
        continue;
      }

      // Description
      if (poste.isNotEmpty) desc.add(line);
    }
    flush();

    return result.isNotEmpty ? result : _experienceFallback(fullText);
  }

  static List<ExperienceItem> _experienceFallback(String text) {
    final result = <ExperienceItem>[];
    // Pattern : titre sur une ligne, suivi d'une date
    final rx = RegExp(
      r'(stage[^\n]{0,80}|developpeur[^\n]{0,80}|ingenieur[^\n]{0,80}'
      r'|developer[^\n]{0,80}|engineer[^\n]{0,80}|analyst[^\n]{0,80})\n'
      r'([^\n]{3,60})\n'
      r'([^\n]*\d{4}[^\n]*)',
      caseSensitive: false,
    );
    for (final m in rx.allMatches(text)) {
      result.add(
        ExperienceItem(
          poste: _tc(m.group(1)!.trim()),
          entreprise: m.group(2)!.trim(),
          periode: m.group(3)!.trim(),
        ),
      );
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // FORMATION — détecte Bac, Licence, Master, Ingénieur, etc.
  // ═══════════════════════════════════════════════════════════

  static List<EducationItem> _extractEducation(
    Map<String, List<String>> sections,
    String fullText,
  ) {
    final sectionLines = sections['education'] ?? [];
    if (sectionLines.isEmpty) return _educationFallback(fullText);

    final result = <EducationItem>[];
    String diplome = '';
    String school = '';
    String period = '';
    String spec = '';
    final desc = <String>[];

    void flush() {
      if (diplome.isEmpty) return;
      result.add(
        EducationItem(
          diplome: diplome,
          etablissement: school,
          periode: period,
          specialite: spec,
          description: desc.join(' ').trim(),
        ),
      );
      diplome = '';
      school = '';
      period = '';
      spec = '';
      desc.clear();
    }

    for (final line in sectionLines) {
      // Nouvelle entrée diplôme
      if (_isDiplomaLine(line)) {
        flush();
        diplome = line;
        continue;
      }

      if (diplome.isNotEmpty) {
        if (_isPeriodLine(line)) {
          period = _extractPeriod(line);
          continue;
        }
        if (school.isEmpty && _isSchoolLine(line)) {
          school = line;
          continue;
        }
        if (spec.isEmpty && line.length < 70) {
          spec = line;
          continue;
        }
        desc.add(line);
      }
    }
    flush();

    return result.isNotEmpty ? result : _educationFallback(fullText);
  }

  static List<EducationItem> _educationFallback(String text) {
    final result = <EducationItem>[];
    final rx = RegExp(
      r'(licence|master|baccalaureat|bac|bachelor|ingenieur|cycle)[^\n]{0,80}\n'
      r'([^\n]{5,80})',
      caseSensitive: false,
    );
    for (final m in rx.allMatches(text)) {
      result.add(
        EducationItem(
          diplome: _tc(m.group(1)!.trim()),
          etablissement: m.group(2)!.trim(),
        ),
      );
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // PROJETS — ne confond PAS "Technologies: …" avec le titre
  // ═══════════════════════════════════════════════════════════

  static List<ProjectItem> _extractProjects(
    Map<String, List<String>> sections,
    String fullText,
  ) {
    final sectionLines = sections['projects'] ?? [];
    if (sectionLines.isEmpty) return [];

    final result = <ProjectItem>[];
    String nom = '';
    String period = '';
    final desc = <String>[];
    final techs = <String>[];

    void flush() {
      if (nom.isEmpty) return;
      result.add(
        ProjectItem(
          nom: nom,
          description: desc.join(' ').trim(),
          technologies: techs.isNotEmpty
              ? List.from(techs)
              : _techsIn(desc.join(' ')),
          periode: period,
        ),
      );
      nom = '';
      period = '';
      desc.clear();
      techs.clear();
    }

    for (final line in sectionLines) {
      final lower = line.toLowerCase();

      // Ligne technologies → extraire les techs, NE PAS utiliser comme titre
      if (_isTechLine(lower)) {
        techs.addAll(_techsIn(line));
        continue;
      }

      if (_isPeriodLine(line)) {
        period = _extractPeriod(line);
        continue;
      }

      // Nouveau titre de projet
      if (_isProjectTitle(line)) {
        flush();
        nom = line;
        continue;
      }

      if (nom.isNotEmpty) desc.add(line);
    }
    flush();
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // CERTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  static List<CertificationItem> _extractCertifications(
    Map<String, List<String>> sections,
  ) {
    final sectionLines = sections['certifications'] ?? [];
    final result = <CertificationItem>[];

    for (final line in sectionLines) {
      if (line.length < 4) continue;
      final yearM = RegExp(r'\b(20\d{2}|19\d{2})\b').firstMatch(line);
      final annee = yearM?.group(1) ?? '';
      final nom = line.replaceAll(RegExp(r'\b(?:20|19)\d{2}\b'), '').trim();

      String organisme = '';
      for (final org in _kCertOrgs) {
        if (line.toLowerCase().contains(org.toLowerCase())) {
          organisme = org;
          break;
        }
      }
      result.add(
        CertificationItem(nom: nom, organisme: organisme, annee: annee),
      );
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // LANGUES — depuis section dédiée OU recherche globale
  // ═══════════════════════════════════════════════════════════

  static List<LanguageItem> _extractLanguages(
    Map<String, List<String>> sections,
    String fullText,
  ) {
    final result = <LanguageItem>[];

    // Chercher dans la section langues ET dans tout le texte
    final sectionLines = sections['languages'] ?? [];
    // Toujours chercher aussi dans le texte complet (cas "Anglais" en dehors section)
    final allLines = fullText.toLowerCase().split('\n');
    final searchLines = sectionLines.isNotEmpty
        ? [...sectionLines.map((l) => l.toLowerCase()), ...allLines]
        : allLines;

    const langMap = <String, String>{
      'francais': 'Français',
      'français': 'Français',
      'french': 'Français',
      'anglais': 'Anglais',
      'english': 'Anglais',
      'arabe': 'Arabe',
      'arabic': 'Arabe',
      'espagnol': 'Espagnol',
      'spanish': 'Espagnol',
      'allemand': 'Allemand',
      'german': 'Allemand',
      'italien': 'Italien',
      'italian': 'Italien',
      'portugais': 'Portugais',
      'portuguese': 'Portugais',
      'chinois': 'Chinois',
      'chinese': 'Chinois',
      'russe': 'Russe',
      'russian': 'Russe',
      'turc': 'Turc',
      'turkish': 'Turc',
    };

    const levels = [
      'natif',
      'native',
      'courant',
      'fluent',
      'bilingue',
      'bilingual',
      'intermediaire',
      'intermediate',
      'debutant',
      'beginner',
      'avance',
      'advanced',
      'b1',
      'b2',
      'c1',
      'c2',
      'a1',
      'a2',
    ];

    for (final entry in langMap.entries) {
      final keyword = entry.key;
      final displayName = entry.value;

      // Eviter les doublons (ex: français / francais → même langue)
      if (result.any((l) => l.langue == displayName)) continue;

      String niveau = '';
      bool found = false;

      for (final line in searchLines) {
        // Chercher le mot-clé avec word boundary approximatif
        if (!RegExp(
          '(?<![a-z])${RegExp.escape(keyword)}(?![a-z])',
        ).hasMatch(line))
          continue;
        found = true;
        // Chercher le niveau sur la même ligne
        for (final lvl in levels) {
          if (line.contains(lvl)) {
            niveau = _tc(lvl);
            break;
          }
        }
        break;
      }

      if (found) {
        result.add(LanguageItem(langue: displayName, niveau: niveau));
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS : DÉTECTION DE LIGNES
  // ═══════════════════════════════════════════════════════════

  // Regex universelle pour les dates
  // Détecte : 07/2025  |  2021  |  jan 2023  |  janv 2024
  static final _periodRx = RegExp(
    r'\d{1,2}/\d{4}'
    r'|\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
    r'|janv|fevr|mars|avr|juin|juil|aout|sept)\w{0,5}\.?\s*\d{4}'
    r'|\b\d{4}\b',
    caseSensitive: false,
  );

  static bool _isPeriodLine(String line) {
    final matches = _periodRx.allMatches(line).length;
    // Ligne de date : contient au moins 1 année ET est assez courte
    // OU contient "aujourd'hui / present / actuel / en cours"
    final hasToday = RegExp(
      r"aujourd'hui|present|actuel|en cours|current|ongoing",
      caseSensitive: false,
    ).hasMatch(line);
    return (matches >= 1 && line.length < 60) || hasToday;
  }

  static String _extractPeriod(String line) {
    // Ex: "07/2025 – 08/2025", "2021-2024", "jan 2023 – présent"
    final rx = RegExp(
      r'(\d{1,2}/\d{4}|\d{4}|(?:jan|feb|mar|avr|mai|jun|jul|aug|sep|oct|nov|dec)\w*\.?\s*\d{4})'
      r'\s*(?:-|au|to)\s*'
      r'(\d{1,2}/\d{4}|\d{4}|present|actuel|current|en cours)',
      caseSensitive: false,
    );
    final m = rx.firstMatch(line);
    if (m != null) return m.group(0)!.trim();
    // Fallback : retourner la ligne entière si courte
    if (line.length < 40) return line.trim();
    return '';
  }

  static String _removePeriod(String line) {
    return line.replaceAll(_periodRx, '').replaceAll(RegExp(r'[-]'), '').trim();
  }

  static bool _isJobTitle(String line) {
    const kw = [
      // Informatique
      'stage',
      'internship',
      'developpeur',
      'developer',
      'ingenieur',
      'engineer',
      'consultant', 'analyste', 'analyst', 'chef de projet', 'project manager',
      'designer', 'architecte', 'architect', 'devops', 'data scientist',
      'technicien', 'assistant', 'coordinateur', 'coordinator', 'manager',
      'responsable', 'directeur', 'director', 'lead', 'senior', 'junior',
      'full stack', 'fullstack', 'frontend', 'backend', 'mobile',
      // Autres domaines (design, commerce, etc.)
      'serveuse', 'serveur', 'stagiaire', 'commercial', 'vendeuse', 'vendeur',
      'assistante', 'comptable', 'secretaire', 'infirmier', 'educateur',
      'animateur', 'formateur', 'chef', 'directrice', 'directeur',
      'charge de', 'chargee de', 'conseiller', 'conseillere',
    ];
    final lower = line
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        .replaceAll('î', 'i');
    return kw.any((k) => lower.contains(k)) && line.length < 120;
  }

  static bool _isCompanyLine(String line) {
    if (line.isEmpty || line.length > 80) return false;
    if (_isPeriodLine(line)) return false;
    if (_isJobTitle(line)) return false;
    // Commence par une majuscule, pas de @ ou /
    return line[0] == line[0].toUpperCase() &&
        !line.contains('@') &&
        !line.contains('http');
  }

  static bool _isDiplomaLine(String line) {
    const kw = [
      'licence',
      'bachelor',
      'master',
      'ingénieur',
      'doctorat',
      'phd',
      'bts',
      'dut',
      'baccalauréat',
      'bac',
      'diplôme',
      'degree',
      'mba',
      'deug',
      'iut',
      'cycle ingénierie',
      'cycle',
      'deuxième année',
      'première année',
      'troisième année',
      'associate',
      'honours',
      'hnd',
      'hnc',
    ];
    final lower = line.toLowerCase();
    return kw.any((k) => lower.contains(k));
  }

  static bool _isSchoolLine(String line) {
    const kw = [
      'université',
      'university',
      'école',
      'school',
      'institut',
      'institute',
      'iit',
      'iset',
      'esprit',
      'sup',
      'faculty',
      'faculté',
      'college',
      'lycée',
      'académie',
      'center',
      'centre',
      'polytechnique',
      'technologique',
    ];
    final lower = line.toLowerCase();
    return kw.any((k) => lower.contains(k));
  }

  static bool _isProjectTitle(String line) {
    final lower = line.toLowerCase();
    // Exclure les lignes technologies
    if (_isTechLine(lower)) return false;
    // Exclure les lignes trop longues
    if (line.length > 90) return false;
    // Exclure les lignes de date
    if (_isPeriodLine(line)) return false;
    // Commence par une majuscule
    return line.isNotEmpty && line[0] == line[0].toUpperCase();
  }

  static bool _isTechLine(String lower) {
    return lower.startsWith('technolog') ||
        lower.startsWith('stack') ||
        lower.startsWith('tech:') ||
        lower.startsWith('built with') ||
        lower.startsWith('outils') ||
        lower.startsWith('tools:');
  }

  static bool _isSectionHeader(String line) {
    return _detectSectionKey(line) != null;
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS : KEYWORDS
  // ═══════════════════════════════════════════════════════════

  static List<String> _techsIn(String text) {
    return _matchList(text.toLowerCase(), [
      ..._kLangs,
      ..._kFrameworks,
      ..._kDatabases,
      ..._kTools,
    ]);
  }

  static List<String> _matchList(String text, List<String> keywords) {
    final result = <String>[];
    for (final kw in keywords) {
      final rx = RegExp(
        '(?<![a-zA-Z])${RegExp.escape(kw)}(?![a-zA-Z])',
        caseSensitive: false,
      );
      if (rx.hasMatch(text)) result.add(kw);
    }
    return result.toSet().toList();
  }

  // titleCase : gère MAJUSCULES et minuscules
  static String _tc(String s) => s
      .split(' ')
      .map(
        (w) =>
            w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');

  // ═══════════════════════════════════════════════════════════
  // LISTES DE MOTS-CLÉS
  // ═══════════════════════════════════════════════════════════

  static const _kLangs = [
    'Python',
    'Java',
    'JavaScript',
    'TypeScript',
    'C',
    'C++',
    'C#',
    'PHP',
    'Ruby',
    'Swift',
    'Kotlin',
    'Go',
    'Rust',
    'Dart',
    'Bash',
    'Shell',
    'SQL',
    'HTML',
    'CSS',
    'Sass',
    'Scala',
    'R',
    'MATLAB',
    'Perl',
    'Lua',
    'Haskell',
    'Elixir',
    'Groovy',
    'Objective-C',
    'Assembly',
    'Fortran',
    'COBOL',
    'VBA',
  ];

  static const _kFrameworks = [
    'Flutter',
    'React',
    'React Native',
    'Angular',
    'Vue',
    'Vue.js',
    'Next.js',
    'Nuxt',
    'Express',
    'NestJS',
    'Django',
    'Flask',
    'FastAPI',
    'Spring',
    'Spring Boot',
    'Laravel',
    'Symfony',
    'Rails',
    'ASP.NET',
    '.NET',
    'Node.js',
    'jQuery',
    'Bootstrap',
    'TailwindCSS',
    'Redux',
    'TensorFlow',
    'PyTorch',
    'Keras',
    'Scikit-learn',
    'Pandas',
    'NumPy',
    'Matplotlib',
    'Seaborn',
    'Plotly',
    'OpenCV',
    'Jetpack Compose',
    'SwiftUI',
    'Ionic',
    'Xamarin',
    'Cordova',
    'WordPress',
    'Drupal',
    'Magento',
    'Shopify',
    'Odoo',
    'SAP',
  ];

  static const _kDatabases = [
    'MySQL',
    'PostgreSQL',
    'SQLite',
    'MongoDB',
    'Firebase',
    'Firestore',
    'Redis',
    'Elasticsearch',
    'Oracle',
    'SQL Server',
    'MariaDB',
    'Cassandra',
    'DynamoDB',
    'Supabase',
    'PlanetScale',
    'Neo4j',
    'InfluxDB',
    'CouchDB',
    'XML',
  ];

  static const _kTools = [
    'Git', 'GitHub', 'GitLab', 'Bitbucket', 'Docker', 'Kubernetes', 'Jenkins',
    'CI/CD', 'Figma', 'Adobe XD', 'Sketch', 'Postman', 'Swagger', 'Linux',
    'Windows', 'macOS', 'VS Code', 'Eclipse', 'IntelliJ', 'Android Studio',
    'Xcode', 'PyCharm', 'NetBeans', 'Jira', 'Trello', 'Notion', 'Slack',
    'AWS', 'GCP', 'Azure', 'Heroku', 'Vercel', 'Netlify', 'Nginx', 'Apache',
    'Jupyter Notebook', 'Jupyter', 'Anaconda', 'Power BI', 'Tableau',
    'Hadoop', 'Spark', 'Kafka', 'RabbitMQ', 'GraphQL',
    // Design & Architecture
    'Sketchup', 'Autocad', 'Archicad', 'AutoCAD', 'SketchUp', 'ArchiCAD',
    'Suite Adobe', 'Photoshop', 'Illustrator', 'InDesign', 'Premiere Pro',
    'After Effects', 'Lightroom', 'Blender', 'Cinema 4D', '3ds Max',
    'Rhinoceros', 'Revit', 'SolidWorks', 'CATIA',
  ];

  static const _kTechSkills = [
    'REST API',
    'Microservices',
    'Agile',
    'Scrum',
    'Kanban',
    'DevOps',
    'Machine Learning',
    'Deep Learning',
    'NLP',
    'Computer Vision',
    'Data Analysis',
    'UI/UX',
    'Responsive Design',
    'OOP',
    'TDD',
    'SOLID',
    'Design Patterns',
    'Clean Code',
    'Test unitaire',
    'Méthodes Agile',
    'UML',
    'Merise',
  ];

  static const _kSoftSkills = [
    'travail en équipe',
    'teamwork',
    'communication',
    'leadership',
    'autonomie',
    'autonomy',
    'créativité',
    'creativity',
    'adaptabilité',
    'adaptability',
    'résolution de problèmes',
    'problem solving',
    'gestion du temps',
    'time management',
    'esprit critique',
    'critical thinking',
    'organisation',
    'rigueur',
    'curiosité',
    'initiative',
    'polyvalence',
    'empathie',
  ];

  // ═══════════════════════════════════════════════════════════
  // VIE ASSOCIATIVE
  // ═══════════════════════════════════════════════════════════

  static List<String> _extractAssociations(
    Map<String, List<String>> sections,
    String fullText,
  ) {
    final result = <String>[];

    // Chercher dans sections associatives
    final keys = ['interests', 'associations'];
    for (final key in keys) {
      final lines = sections[key] ?? [];
      for (final line in lines) {
        if (line.trim().length > 3) result.add(line.trim());
      }
    }

    // Fallback : chercher dans le texte brut
    if (result.isEmpty) {
      final rx = RegExp(
        r'(?:membre|president|vice|benevole|benevole|club|association|'
        r'ambassadeur|ambassadrice|bde|animateur|educateur)[^\n]{0,120}',
        caseSensitive: false,
      );
      for (final m in rx.allMatches(fullText)) {
        final val = m.group(0)!.trim();
        if (val.length > 5 && !result.contains(val)) result.add(val);
      }
    }
    return result;
  }

  static const _kCertOrgs = [
    'Google',
    'Microsoft',
    'AWS',
    'Cisco',
    'Oracle',
    'Meta',
    'IBM',
    'Coursera',
    'Udemy',
    'LinkedIn Learning',
    'CompTIA',
    'PMI',
    'Scrum Alliance',
    'OpenClassrooms',
    'FreeCodeCamp',
  ];
}
