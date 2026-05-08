class CvAnalysisResult {
  final int score;
  final bool hasEmail;
  final bool hasPhone;
  final bool hasLinkedIn;
  final bool hasGitHub;
  final bool hasSummary;
  final int skillsCount;
  final int experiencesCount;
  final int projectsCount;
  final String detectedLanguage;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> advice;

  const CvAnalysisResult({
    required this.score,
    required this.hasEmail,
    required this.hasPhone,
    required this.hasLinkedIn,
    required this.hasGitHub,
    required this.hasSummary,
    required this.skillsCount,
    required this.experiencesCount,
    required this.projectsCount,
    required this.detectedLanguage,
    required this.strengths,
    required this.improvements,
    required this.advice,
  });
}
