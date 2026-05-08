// ============================================================
// interview_question_service.dart
// Questions d'entretien réalistes
// Niveaux : Débutant / Non débutant
// Langues entretien : Français / Anglais / Espagnol / Allemand
// Si CV arabe ou langue inconnue : questions en français
// ============================================================

import 'dart:math';

import '../models/candidate_profile.dart';

enum InterviewDifficulty { beginner, nonBeginner }

enum InterviewLanguage { french, english, spanish, german }

extension InterviewDifficultyLabel on InterviewDifficulty {
  String get label {
    switch (this) {
      case InterviewDifficulty.beginner:
        return 'Débutant';
      case InterviewDifficulty.nonBeginner:
        return 'Non débutant';
    }
  }

  String get description {
    switch (this) {
      case InterviewDifficulty.beginner:
        return 'Questions simples sur le CV, la formation, les stages et les projets.';
      case InterviewDifficulty.nonBeginner:
        return 'Questions professionnelles sur les expériences, technologies et méthodes de travail.';
    }
  }
}

extension InterviewLanguageLabel on InterviewLanguage {
  String get displayName {
    switch (this) {
      case InterviewLanguage.french:
        return 'Français';
      case InterviewLanguage.english:
        return 'Anglais';
      case InterviewLanguage.spanish:
        return 'Espagnol';
      case InterviewLanguage.german:
        return 'Allemand';
    }
  }
}

class InterviewQuestion {
  final String question;
  final String category;

  const InterviewQuestion({required this.question, required this.category});
}

class InterviewQuestionService {
  static List<InterviewQuestion> generateQuestions(
    CandidateProfile profile, {
    InterviewDifficulty difficulty = InterviewDifficulty.beginner,
  }) {
    final language = detectInterviewLanguage(profile);
    final text = _InterviewText(language);

    switch (difficulty) {
      case InterviewDifficulty.beginner:
        return _generateBeginnerQuestions(profile, text);
      case InterviewDifficulty.nonBeginner:
        return _generateNonBeginnerQuestions(profile, text);
    }
  }

  static InterviewLanguage detectInterviewLanguage(CandidateProfile profile) {
    final raw = profile.detectedCvLanguage.toString().trim().toLowerCase();

    if (raw.contains('english') || raw.contains('anglais') || raw == 'en') {
      return InterviewLanguage.english;
    }

    if (raw.contains('spanish') ||
        raw.contains('espagnol') ||
        raw.contains('español') ||
        raw == 'es') {
      return InterviewLanguage.spanish;
    }

    if (raw.contains('german') ||
        raw.contains('allemand') ||
        raw.contains('deutsch') ||
        raw.contains('alemán') ||
        raw == 'de') {
      return InterviewLanguage.german;
    }

    // CV arabe ou langue inconnue => entretien en français
    return InterviewLanguage.french;
  }

  static String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _fallback(String value, String fallback) {
    final clean = _clean(value);
    return clean.isEmpty ? fallback : clean;
  }

  static InterviewQuestion _q(String question, String category) {
    return InterviewQuestion(question: question, category: category);
  }

  static void _addUnique(
    List<InterviewQuestion> list,
    InterviewQuestion question,
  ) {
    final exists = list.any(
      (q) =>
          q.question.trim().toLowerCase() ==
          question.question.trim().toLowerCase(),
    );

    if (!exists) {
      list.add(question);
    }
  }

  static List<InterviewQuestion> _finalizeQuestions({
    required InterviewQuestion firstQuestion,
    required List<InterviewQuestion> pool,
    required List<InterviewQuestion> fallback,
  }) {
    final result = <InterviewQuestion>[];
    final randomPool = pool.toList()..shuffle(Random());
    final randomFallback = fallback.toList()..shuffle(Random());

    _addUnique(result, firstQuestion);

    for (final q in randomPool) {
      if (result.length >= 10) break;
      _addUnique(result, q);
    }

    for (final q in randomFallback) {
      if (result.length >= 10) break;
      _addUnique(result, q);
    }

    return result.take(10).toList();
  }

  static String? _firstEducationTitle(CandidateProfile profile) {
    if (!profile.hasEducation) return null;

    for (final edu in profile.education) {
      final title = _clean(edu.diplome);
      if (title.isNotEmpty) return title;
    }

    return null;
  }

  static String? _firstExperienceTitle(CandidateProfile profile) {
    if (!profile.hasExperiences) return null;

    for (final exp in profile.experiences) {
      final title = _clean(exp.poste);
      if (title.isNotEmpty) return title;
    }

    return null;
  }

  static String? _firstExperienceCompany(CandidateProfile profile) {
    if (!profile.hasExperiences) return null;

    for (final exp in profile.experiences) {
      final company = _clean(exp.entreprise);
      if (company.isNotEmpty) return company;
    }

    return null;
  }

  static String? _secondExperienceTitle(CandidateProfile profile) {
    if (!profile.hasExperiences || profile.experiences.length < 2) return null;

    final title = _clean(profile.experiences[1].poste);
    return title.isEmpty ? null : title;
  }

  static String? _firstProjectName(CandidateProfile profile) {
    if (!profile.hasProjects) return null;

    for (final project in profile.projects) {
      final name = _clean(project.nom);
      if (name.isNotEmpty) return name;
    }

    return null;
  }

  static List<String> _mainSkills(CandidateProfile profile, {int limit = 4}) {
    final skills = profile.allTechnicalSkills
        .map(_clean)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    skills.shuffle(Random());
    return skills.take(limit).toList();
  }

  static List<InterviewQuestion> _generateBeginnerQuestions(
    CandidateProfile profile,
    _InterviewText t,
  ) {
    final educationTitle = _firstEducationTitle(profile);
    final expTitle = _firstExperienceTitle(profile);
    final expCompany = _firstExperienceCompany(profile);
    final projectName = _firstProjectName(profile);
    final skills = _mainSkills(profile, limit: 4);

    final pool = <InterviewQuestion>[];

    if (educationTitle != null) {
      pool.addAll([
        _q(t.talkAboutEducation(educationTitle), t.education),
        _q(t.whyThisDomain, t.motivation),
        _q(t.skillsFromEducation, t.education),
      ]);
    } else {
      pool.addAll([
        _q(t.talkAboutAcademicPath, t.education),
        _q(t.whyThisDomain, t.motivation),
      ]);
    }

    if (expTitle != null) {
      pool.addAll([
        _q(t.explainExperience(expTitle, expCompany), t.experience),
        _q(t.mainMissions, t.experience),
        _q(t.whatLearnedFromExperience, t.experience),
      ]);
    } else {
      pool.add(_q(t.noExperienceQuestion, t.experience));
    }

    if (projectName != null) {
      pool.addAll([
        _q(t.presentProject(projectName), t.project),
        _q(t.roleInProject(projectName), t.project),
        _q(t.projectTechnologies(projectName), t.project),
        _q(t.projectDifficulty(projectName), t.project),
      ]);
    } else {
      pool.add(_q(t.presentAnyProject, t.project));
    }

    if (skills.isNotEmpty) {
      pool.add(_q(t.explainSkill(skills.first), t.skill));

      if (skills.length > 1) {
        pool.add(_q(t.compareSkills(skills[0], skills[1]), t.skill));
      }
    } else {
      pool.add(_q(t.bestTechnicalSkills, t.skill));
    }

    final fallback = <InterviewQuestion>[
      _q(t.summarizePath, t.general),
      _q(t.mostImportantProjectOrInternship, t.path),
      _q(t.teamworkQuestion, t.softSkills),
      _q(t.blockedProblem, t.organization),
      _q(t.strengths, t.softSkills),
      _q(t.targetPosition, t.motivation),
      _q(t.whyChooseYou, t.conclusion),
      _q(t.progressGoals, t.conclusion),
    ];

    return _finalizeQuestions(
      firstQuestion: _q(t.introduce, t.general),
      pool: pool,
      fallback: fallback,
    );
  }

  static List<InterviewQuestion> _generateNonBeginnerQuestions(
    CandidateProfile profile,
    _InterviewText t,
  ) {
    final expTitle = _firstExperienceTitle(profile) ?? t.mainExperience;
    final expCompany = _firstExperienceCompany(profile) ?? '';
    final secondExpTitle = _secondExperienceTitle(profile);
    final projectName = _firstProjectName(profile);
    final skills = _mainSkills(profile, limit: 5);

    final pool = <InterviewQuestion>[
      _q(t.detailExperience(expTitle, expCompany), t.experience),
      _q(t.importantMissionInExperience, t.experience),
      _q(t.concreteProblemSolved, t.problemSolving),
      _q(t.qualityCheck, t.quality),
      _q(t.organizeWork, t.organization),
    ];

    if (secondExpTitle != null) {
      pool.add(
        _q(t.compareExperiences(expTitle, secondExpTitle), t.comparison),
      );
    } else {
      pool.add(_q(t.enterpriseLearning, t.experience));
    }

    if (projectName != null) {
      pool.addAll([
        _q(t.explainProjectToRecruiter(projectName), t.project),
        _q(t.projectTechChoice(projectName), t.technology),
        _q(t.projectImprovement(projectName), t.improvement),
      ]);
    } else {
      pool.add(_q(t.presentImportantProject, t.project));
    }

    if (skills.isNotEmpty) {
      pool.addAll([
        _q(t.realUseOfSkill(skills.first), t.technology),
        _q(t.skillDifficulty(skills.first), t.technology),
      ]);

      if (skills.length > 1) {
        pool.add(_q(t.chooseBetweenSkills(skills[0], skills[1]), t.technology));
      }
    } else {
      pool.add(_q(t.mostUsedTechnologies, t.technology));
    }

    final fallback = <InterviewQuestion>[
      _q(t.debugMethod, t.problemSolving),
      _q(t.explainTechnicalToNonTechnical, t.communication),
      _q(t.teamProjectWork, t.teamwork),
      _q(t.beforeDelivery, t.quality),
      _q(t.handleMultipleTasks, t.organization),
      _q(t.technicalSkillToImprove, t.progression),
      _q(t.whyProfileMatches, t.conclusion),
      _q(t.whatMakesYouDifferent, t.conclusion),
    ];

    return _finalizeQuestions(
      firstQuestion: _q(t.introduce, t.general),
      pool: pool,
      fallback: fallback,
    );
  }
}

class _InterviewText {
  final InterviewLanguage language;

  const _InterviewText(this.language);

  String _m(String fr, String en, String es, String de) {
    switch (language) {
      case InterviewLanguage.french:
        return fr;
      case InterviewLanguage.english:
        return en;
      case InterviewLanguage.spanish:
        return es;
      case InterviewLanguage.german:
        return de;
    }
  }

  String get general => _m('Général', 'General', 'General', 'Allgemein');
  String get education =>
      _m('Formation', 'Education', 'Formación', 'Ausbildung');
  String get experience =>
      _m('Expérience', 'Experience', 'Experiencia', 'Erfahrung');
  String get project => _m('Projet', 'Project', 'Proyecto', 'Projekt');
  String get skill => _m('Compétence', 'Skill', 'Competencia', 'Kompetenz');
  String get motivation =>
      _m('Motivation', 'Motivation', 'Motivación', 'Motivation');
  String get softSkills =>
      _m('Soft skills', 'Soft skills', 'Habilidades blandas', 'Soft Skills');
  String get organization =>
      _m('Organisation', 'Organization', 'Organización', 'Organisation');
  String get conclusion =>
      _m('Conclusion', 'Conclusion', 'Conclusión', 'Abschluss');
  String get path => _m('Parcours', 'Background', 'Trayectoria', 'Werdegang');
  String get problemSolving => _m(
    'Résolution problème',
    'Problem solving',
    'Resolución de problemas',
    'Problemlösung',
  );
  String get quality => _m('Qualité', 'Quality', 'Calidad', 'Qualität');
  String get comparison =>
      _m('Comparaison', 'Comparison', 'Comparación', 'Vergleich');
  String get technology =>
      _m('Technologie', 'Technology', 'Tecnología', 'Technologie');
  String get improvement =>
      _m('Amélioration', 'Improvement', 'Mejora', 'Verbesserung');
  String get communication =>
      _m('Communication', 'Communication', 'Comunicación', 'Kommunikation');
  String get teamwork =>
      _m('Travail équipe', 'Teamwork', 'Trabajo en equipo', 'Teamarbeit');
  String get progression =>
      _m('Progression', 'Progression', 'Progresión', 'Weiterentwicklung');

  String get introduce => _m(
    'Présentez-vous brièvement.',
    'Briefly introduce yourself.',
    'Preséntese brevemente.',
    'Stellen Sie sich kurz vor.',
  );

  String talkAboutEducation(String title) => _m(
    'Pouvez-vous parler de votre formation "$title" ?',
    'Can you talk about your education "$title"?',
    '¿Puede hablar de su formación "$title"?',
    'Können Sie über Ihre Ausbildung "$title" sprechen?',
  );

  String get talkAboutAcademicPath => _m(
    'Pouvez-vous parler de votre parcours académique ?',
    'Can you talk about your academic background?',
    '¿Puede hablar de su trayectoria académica?',
    'Können Sie über Ihren akademischen Werdegang sprechen?',
  );

  String get whyThisDomain => _m(
    'Pourquoi avez-vous choisi ce domaine ?',
    'Why did you choose this field?',
    '¿Por qué eligió este campo?',
    'Warum haben Sie diesen Bereich gewählt?',
  );

  String get skillsFromEducation => _m(
    'Quelles compétences avez-vous développées pendant votre formation ?',
    'What skills did you develop during your education?',
    '¿Qué competencias desarrolló durante su formación?',
    'Welche Kompetenzen haben Sie während Ihrer Ausbildung entwickelt?',
  );

  String _companyPart(String? company) {
    if (company == null || company.trim().isEmpty) return '';

    return _m(
      ' chez $company',
      ' at $company',
      ' en $company',
      ' bei $company',
    );
  }

  String explainExperience(String title, String? company) {
    final part = _companyPart(company);

    return _m(
      'Pouvez-vous expliquer votre expérience "$title"$part ?',
      'Can you explain your experience "$title"$part?',
      '¿Puede explicar su experiencia "$title"$part?',
      'Können Sie Ihre Erfahrung "$title"$part erklären?',
    );
  }

  String detailExperience(String title, String company) {
    final part = _companyPart(company);

    return _m(
      'Pouvez-vous détailler votre expérience "$title"$part ?',
      'Can you describe your experience "$title"$part in detail?',
      '¿Puede detallar su experiencia "$title"$part?',
      'Können Sie Ihre Erfahrung "$title"$part genauer beschreiben?',
    );
  }

  String get mainMissions => _m(
    'Quelles étaient vos principales missions dans cette expérience ?',
    'What were your main tasks in this experience?',
    '¿Cuáles eran sus principales tareas en esta experiencia?',
    'Was waren Ihre Hauptaufgaben in dieser Erfahrung?',
  );

  String get whatLearnedFromExperience => _m(
    'Qu’avez-vous appris grâce à cette expérience ?',
    'What did you learn from this experience?',
    '¿Qué aprendió de esta experiencia?',
    'Was haben Sie aus dieser Erfahrung gelernt?',
  );

  String get noExperienceQuestion => _m(
    'Avez-vous déjà fait un stage ou une expérience pratique ? Expliquez.',
    'Have you already completed an internship or practical experience? Please explain.',
    '¿Ha realizado ya unas prácticas o una experiencia práctica? Explique.',
    'Haben Sie bereits ein Praktikum oder praktische Erfahrung gemacht? Erklären Sie bitte.',
  );

  String presentProject(String name) => _m(
    'Pouvez-vous présenter votre projet "$name" ?',
    'Can you present your project "$name"?',
    '¿Puede presentar su proyecto "$name"?',
    'Können Sie Ihr Projekt "$name" vorstellen?',
  );

  String roleInProject(String name) => _m(
    'Quel était votre rôle dans le projet "$name" ?',
    'What was your role in the project "$name"?',
    '¿Cuál fue su papel en el proyecto "$name"?',
    'Welche Rolle hatten Sie im Projekt "$name"?',
  );

  String projectTechnologies(String name) => _m(
    'Quelles technologies avez-vous utilisées dans le projet "$name" ?',
    'Which technologies did you use in the project "$name"?',
    '¿Qué tecnologías utilizó en el proyecto "$name"?',
    'Welche Technologien haben Sie im Projekt "$name" verwendet?',
  );

  String projectDifficulty(String name) => _m(
    'Quelle difficulté avez-vous rencontrée dans le projet "$name" et comment l’avez-vous résolue ?',
    'What difficulty did you face in the project "$name", and how did you solve it?',
    '¿Qué dificultad encontró en el proyecto "$name" y cómo la resolvió?',
    'Welche Schwierigkeit gab es im Projekt "$name" und wie haben Sie sie gelöst?',
  );

  String get presentAnyProject => _m(
    'Pouvez-vous présenter un projet académique ou personnel que vous avez réalisé ?',
    'Can you present an academic or personal project you completed?',
    '¿Puede presentar un proyecto académico o personal que haya realizado?',
    'Können Sie ein akademisches oder persönliches Projekt vorstellen?',
  );

  String explainSkill(String skill) => _m(
    'Vous avez mentionné $skill dans votre CV. Pouvez-vous expliquer comment vous l’avez utilisé ?',
    'You mentioned $skill in your CV. Can you explain how you used it?',
    'Ha mencionado $skill en su CV. ¿Puede explicar cómo lo utilizó?',
    'Sie haben $skill in Ihrem Lebenslauf erwähnt. Können Sie erklären, wie Sie es verwendet haben?',
  );

  String compareSkills(String skill1, String skill2) => _m(
    'Entre $skill1 et $skill2, lequel maîtrisez-vous le mieux et pourquoi ?',
    'Between $skill1 and $skill2, which one do you know better and why?',
    'Entre $skill1 y $skill2, ¿cuál domina mejor y por qué?',
    'Zwischen $skill1 und $skill2, was beherrschen Sie besser und warum?',
  );

  String get bestTechnicalSkills => _m(
    'Quelles compétences techniques maîtrisez-vous le mieux ?',
    'What technical skills do you master best?',
    '¿Qué competencias técnicas domina mejor?',
    'Welche technischen Kompetenzen beherrschen Sie am besten?',
  );

  String get summarizePath => _m(
    'Pouvez-vous résumer votre parcours en quelques phrases ?',
    'Can you summarize your background in a few sentences?',
    '¿Puede resumir su trayectoria en pocas frases?',
    'Können Sie Ihren Werdegang in wenigen Sätzen zusammenfassen?',
  );

  String get mostImportantProjectOrInternship => _m(
    'Quel projet ou stage vous a le plus marqué ? Pourquoi ?',
    'Which project or internship was the most important for you, and why?',
    '¿Qué proyecto o práctica fue más importante para usted y por qué?',
    'Welches Projekt oder Praktikum war für Sie am wichtigsten und warum?',
  );

  String get teamworkQuestion => _m(
    'Comment travaillez-vous en équipe ?',
    'How do you work in a team?',
    '¿Cómo trabaja en equipo?',
    'Wie arbeiten Sie im Team?',
  );

  String get blockedProblem => _m(
    'Comment travaillez-vous lorsque vous êtes bloqué sur un problème ?',
    'How do you work when you are blocked on a problem?',
    '¿Cómo trabaja cuando se bloquea ante un problema?',
    'Wie arbeiten Sie, wenn Sie bei einem Problem blockiert sind?',
  );

  String get strengths => _m(
    'Quels sont vos principaux points forts ?',
    'What are your main strengths?',
    '¿Cuáles son sus principales puntos fuertes?',
    'Was sind Ihre wichtigsten Stärken?',
  );

  String get targetPosition => _m(
    'Quel type de poste ou de stage recherchez-vous ?',
    'What type of position or internship are you looking for?',
    '¿Qué tipo de puesto o práctica está buscando?',
    'Welche Art von Stelle oder Praktikum suchen Sie?',
  );

  String get whyChooseYou => _m(
    'Pourquoi devrions-nous vous choisir pour ce poste ?',
    'Why should we choose you for this position?',
    '¿Por qué deberíamos elegirle para este puesto?',
    'Warum sollten wir Sie für diese Stelle auswählen?',
  );

  String get progressGoals => _m(
    'Quels sont vos objectifs pour progresser ?',
    'What are your goals for improving yourself?',
    '¿Cuáles son sus objetivos para mejorar?',
    'Welche Ziele haben Sie, um sich weiterzuentwickeln?',
  );

  String get mainExperience => _m(
    'votre expérience principale',
    'your main experience',
    'su experiencia principal',
    'Ihre wichtigste Erfahrung',
  );

  String get importantMissionInExperience => _m(
    'Dans cette expérience, quelle mission était la plus importante pour vous ?',
    'In this experience, what was your most important task?',
    'En esta experiencia, ¿cuál fue su misión más importante?',
    'Was war in dieser Erfahrung Ihre wichtigste Aufgabe?',
  );

  String get concreteProblemSolved => _m(
    'Donnez un exemple concret d’un problème que vous avez rencontré et comment vous l’avez résolu.',
    'Give a concrete example of a problem you faced and how you solved it.',
    'Dé un ejemplo concreto de un problema que encontró y cómo lo resolvió.',
    'Nennen Sie ein konkretes Problem, das Sie hatten, und wie Sie es gelöst haben.',
  );

  String compareExperiences(String exp1, String exp2) => _m(
    'Quelle différence voyez-vous entre votre expérience "$exp1" et "$exp2" ?',
    'What difference do you see between your experience "$exp1" and "$exp2"?',
    '¿Qué diferencia ve entre su experiencia "$exp1" y "$exp2"?',
    'Welchen Unterschied sehen Sie zwischen "$exp1" und "$exp2"?',
  );

  String get enterpriseLearning => _m(
    'Qu’est-ce que cette expérience vous a appris sur le travail en entreprise ?',
    'What did this experience teach you about working in a company?',
    '¿Qué le enseñó esta experiencia sobre el trabajo en empresa?',
    'Was hat Ihnen diese Erfahrung über die Arbeit im Unternehmen beigebracht?',
  );

  String explainProjectToRecruiter(String name) => _m(
    'Expliquez le projet "$name" comme si vous le présentiez à un recruteur.',
    'Explain the project "$name" as if you were presenting it to a recruiter.',
    'Explique el proyecto "$name" como si lo presentara a un reclutador.',
    'Erklären Sie das Projekt "$name", als würden Sie es einem Recruiter vorstellen.',
  );

  String projectTechChoice(String name) => _m(
    'Quelles technologies avez-vous utilisées dans "$name" et pourquoi ?',
    'Which technologies did you use in "$name", and why?',
    '¿Qué tecnologías utilizó en "$name" y por qué?',
    'Welche Technologien haben Sie in "$name" verwendet und warum?',
  );

  String projectImprovement(String name) => _m(
    'Si vous deviez améliorer le projet "$name", que changeriez-vous ?',
    'If you had to improve the project "$name", what would you change?',
    'Si tuviera que mejorar el proyecto "$name", ¿qué cambiaría?',
    'Wenn Sie das Projekt "$name" verbessern müssten, was würden Sie ändern?',
  );

  String get presentImportantProject => _m(
    'Pouvez-vous présenter un projet important et expliquer votre rôle dedans ?',
    'Can you present an important project and explain your role in it?',
    '¿Puede presentar un proyecto importante y explicar su papel en él?',
    'Können Sie ein wichtiges Projekt vorstellen und Ihre Rolle erklären?',
  );

  String realUseOfSkill(String skill) => _m(
    'Comment avez-vous utilisé $skill dans un projet ou une expérience réelle ?',
    'How did you use $skill in a real project or experience?',
    '¿Cómo utilizó $skill en un proyecto o experiencia real?',
    'Wie haben Sie $skill in einem echten Projekt oder einer Erfahrung verwendet?',
  );

  String skillDifficulty(String skill) => _m(
    'Quelle difficulté peut-on rencontrer avec $skill ?',
    'What difficulty can you face when working with $skill?',
    '¿Qué dificultad puede encontrar al trabajar con $skill?',
    'Welche Schwierigkeit kann bei der Arbeit mit $skill auftreten?',
  );

  String chooseBetweenSkills(String skill1, String skill2) => _m(
    'Si vous deviez choisir entre $skill1 et $skill2 pour un projet, comment décideriez-vous ?',
    'If you had to choose between $skill1 and $skill2 for a project, how would you decide?',
    'Si tuviera que elegir entre $skill1 y $skill2 para un proyecto, ¿cómo decidiría?',
    'Wenn Sie zwischen $skill1 und $skill2 für ein Projekt wählen müssten, wie würden Sie entscheiden?',
  );

  String get mostUsedTechnologies => _m(
    'Quelles technologies utilisez-vous le plus souvent et dans quel contexte ?',
    'Which technologies do you use most often, and in what context?',
    '¿Qué tecnologías utiliza con más frecuencia y en qué contexto?',
    'Welche Technologien verwenden Sie am häufigsten und in welchem Kontext?',
  );

  String get qualityCheck => _m(
    'Comment vérifiez-vous que votre travail est correct avant de le livrer ?',
    'How do you check that your work is correct before delivering it?',
    '¿Cómo verifica que su trabajo es correcto antes de entregarlo?',
    'Wie überprüfen Sie Ihre Arbeit, bevor Sie sie abgeben?',
  );

  String get organizeWork => _m(
    'Comment organisez-vous votre travail lorsque vous avez plusieurs tâches à faire ?',
    'How do you organize your work when you have several tasks to do?',
    '¿Cómo organiza su trabajo cuando tiene varias tareas?',
    'Wie organisieren Sie Ihre Arbeit, wenn Sie mehrere Aufgaben haben?',
  );

  String get debugMethod => _m(
    'Comment gérez-vous les erreurs ou bugs dans une application ?',
    'How do you handle errors or bugs in an application?',
    '¿Cómo gestiona errores o bugs en una aplicación?',
    'Wie gehen Sie mit Fehlern oder Bugs in einer Anwendung um?',
  );

  String get explainTechnicalToNonTechnical => _m(
    'Comment expliquez-vous un sujet technique à une personne non technique ?',
    'How would you explain a technical subject to a non-technical person?',
    '¿Cómo explicaría un tema técnico a una persona no técnica?',
    'Wie erklären Sie ein technisches Thema einer nicht-technischen Person?',
  );

  String get teamProjectWork => _m(
    'Comment travaillez-vous avec une équipe sur un projet technique ?',
    'How do you work with a team on a technical project?',
    '¿Cómo trabaja con un equipo en un proyecto técnico?',
    'Wie arbeiten Sie in einem technischen Projekt mit einem Team?',
  );

  String get beforeDelivery => _m(
    'Que faites-vous avant de livrer un projet ou une tâche ?',
    'What do you do before delivering a project or a task?',
    '¿Qué hace antes de entregar un proyecto o una tarea?',
    'Was tun Sie, bevor Sie ein Projekt oder eine Aufgabe abgeben?',
  );

  String get handleMultipleTasks => _m(
    'Comment gérez-vous plusieurs tâches avec des délais ?',
    'How do you manage several tasks with deadlines?',
    '¿Cómo gestiona varias tareas con plazos?',
    'Wie verwalten Sie mehrere Aufgaben mit Fristen?',
  );

  String get technicalSkillToImprove => _m(
    'Quelle compétence technique voulez-vous améliorer et pourquoi ?',
    'Which technical skill would you like to improve, and why?',
    '¿Qué competencia técnica le gustaría mejorar y por qué?',
    'Welche technische Kompetenz möchten Sie verbessern und warum?',
  );

  String get whyProfileMatches => _m(
    'Pourquoi votre profil correspond-il à ce poste ?',
    'Why does your profile match this position?',
    '¿Por qué su perfil corresponde a este puesto?',
    'Warum passt Ihr Profil zu dieser Stelle?',
  );

  String get whatMakesYouDifferent => _m(
    'Qu’est-ce qui vous différencie des autres candidats ?',
    'What makes you different from other candidates?',
    '¿Qué le diferencia de otros candidatos?',
    'Was unterscheidet Sie von anderen Kandidaten?',
  );
}
