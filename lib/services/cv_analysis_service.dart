import '../models/candidate_profile.dart';
import '../models/cv_analysis_result.dart';

class CvAnalysisService {
  static CvAnalysisResult analyze(CandidateProfile profile) {
    final hasEmail = profile.email.trim().isNotEmpty;
    final hasPhone = profile.phone.trim().isNotEmpty;
    final hasLinkedIn = profile.linkedin.trim().isNotEmpty;
    final hasGitHub = profile.github.trim().isNotEmpty;
    final skillsCount =
        profile.allTechnicalSkills.length + profile.softSkills.length;
    final experiencesCount = profile.experiences.length;
    final projectsCount = profile.projects.length;
    final hasSummary = profile.summary.trim().isNotEmpty;

    var score = 0;
    if (hasEmail) score += 10;
    if (hasPhone) score += 10;
    if (hasLinkedIn) score += 10;
    if (hasGitHub) score += 10;
    if (skillsCount >= 3) score += 15;
    if (experiencesCount >= 1) score += 15;
    if (projectsCount >= 1) score += 15;
    if (hasSummary) score += 15;

    final strengths = <String>[
      if (hasEmail) 'Email détecté',
      if (hasPhone) 'Téléphone détecté',
      if (skillsCount > 0) 'Compétences détectées',
      if (experiencesCount > 0) 'Expériences détectées',
      if (projectsCount > 0) 'Projets détectés',
      if (profile.detectedCvLanguage.trim().isNotEmpty)
        'Langue du CV détectée',
    ];

    final improvements = <String>[
      if (!hasEmail) 'Email absent',
      if (!hasPhone) 'Téléphone absent',
      if (!hasLinkedIn) 'LinkedIn absent',
      if (!hasGitHub) 'GitHub absent',
      if (skillsCount < 3) 'Peu de compétences détectées',
      if (experiencesCount == 0) 'Aucune expérience détectée',
      if (projectsCount == 0) 'Aucun projet détecté',
      if (!hasSummary) 'Résumé professionnel absent',
    ];

    final advice = <String>[
      if (!hasEmail) 'Ajoutez une adresse email professionnelle.',
      if (!hasPhone) 'Ajoutez un numéro de téléphone.',
      if (!hasLinkedIn) 'Ajoutez un lien LinkedIn.',
      if (!hasGitHub)
        'Ajoutez un lien GitHub si vous avez des projets techniques.',
      if (skillsCount < 3) 'Ajoutez plus de compétences techniques.',
      if (experiencesCount == 0)
        'Ajoutez vos stages, expériences ou projets pratiques.',
      if (projectsCount == 0)
        'Ajoutez au moins un projet académique ou personnel.',
      if (!hasSummary) 'Ajoutez un court résumé professionnel en haut du CV.',
    ];

    return CvAnalysisResult(
      score: score.clamp(0, 100),
      hasEmail: hasEmail,
      hasPhone: hasPhone,
      hasLinkedIn: hasLinkedIn,
      hasGitHub: hasGitHub,
      hasSummary: hasSummary,
      skillsCount: skillsCount,
      experiencesCount: experiencesCount,
      projectsCount: projectsCount,
      detectedLanguage: profile.detectedCvLanguage,
      strengths: strengths,
      improvements: improvements,
      advice: advice,
    );
  }
}
