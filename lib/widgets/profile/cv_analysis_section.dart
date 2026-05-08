import 'package:flutter/material.dart';

import '../../models/cv_analysis_result.dart';
import '../app_design.dart';

class CvAnalysisSection extends StatelessWidget {
  final CvAnalysisResult analysis;

  const CvAnalysisSection({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final level = _ScoreLevel.fromScore(analysis.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ScoreRing(score: analysis.score, color: level.color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score CV',
                          style: TextStyle(
                            color: AppDesign.textColor(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _LevelBadge(level: level),
                        const SizedBox(height: 10),
                        Text(
                          'Ce score estime la qualité des informations présentes dans votre CV.',
                          style: TextStyle(
                            color: AppDesign.mutedText(context),
                            height: 1.35,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: analysis.score / 100,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE8EDF5),
                  valueColor: AlwaysStoppedAnimation<Color>(level.color),
                ),
              ),
            ],
          ),
        ),
        _ChecklistCard(analysis: analysis),
        _AdviceCard(
          title: 'Points forts',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF10B981),
          items: analysis.strengths,
          empty: 'Aucun point fort détecté pour le moment.',
        ),
        _AdviceCard(
          title: 'À améliorer',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
          items: analysis.improvements,
          empty: 'Aucun élément majeur à corriger détecté.',
        ),
        _AdviceCard(
          title: 'Recommandations',
          icon: Icons.auto_awesome_rounded,
          color: AppDesign.violet,
          items: _recommendations,
          empty: 'Votre CV contient déjà les informations essentielles.',
          highlighted: true,
        ),
      ],
    );
  }

  List<String> get _recommendations {
    final items = <String>[
      ...analysis.advice,
      if (analysis.experiencesCount > 0)
        'Ajoutez des résultats mesurables dans vos expériences.',
      if (analysis.projectsCount > 0)
        'Décrivez vos projets avec technologies, rôle et résultat.',
      if (!analysis.hasLinkedIn || !analysis.hasGitHub)
        'Ajoutez LinkedIn ou GitHub pour renforcer votre profil.',
    ];
    return items.toSet().toList();
  }
}

class _ChecklistCard extends StatelessWidget {
  final CvAnalysisResult analysis;

  const _ChecklistCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _Criterion(
        'Email détecté',
        'Contact professionnel disponible',
        'Ajoutez une adresse email professionnelle',
        analysis.hasEmail,
      ),
      _Criterion(
        'Téléphone détecté',
        'Le recruteur peut vous joindre rapidement',
        'Ajoutez un numéro de téléphone',
        analysis.hasPhone,
      ),
      _Criterion(
        'LinkedIn détecté',
        'Profil professionnel renforcé',
        'Ajoutez votre lien LinkedIn',
        analysis.hasLinkedIn,
      ),
      _Criterion(
        'GitHub détecté',
        'Projets techniques vérifiables',
        'Ajoutez GitHub si vous avez des projets techniques',
        analysis.hasGitHub,
      ),
      _Criterion(
        'Compétences détectées',
        '${analysis.skillsCount} compétence(s) trouvée(s)',
        'Ajoutez au moins trois compétences clés',
        analysis.skillsCount >= 3,
      ),
      _Criterion(
        'Expériences détectées',
        '${analysis.experiencesCount} expérience(s) trouvée(s)',
        'Ajoutez stages, missions ou expériences',
        analysis.experiencesCount > 0,
      ),
      _Criterion(
        'Projets détectés',
        '${analysis.projectsCount} projet(s) trouvé(s)',
        'Ajoutez un projet académique ou personnel',
        analysis.projectsCount > 0,
      ),
      _Criterion(
        'Résumé professionnel détecté',
        'Le profil est plus lisible en haut du CV',
        'Ajoutez un court résumé professionnel',
        analysis.hasSummary,
      ),
    ];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Critères analysés',
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => _CriterionRow(row: row)),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final _Criterion row;

  const _CriterionRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final color = row.ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              row.ok ? Icons.check_rounded : Icons.priority_high_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    color: AppDesign.textColor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.ok ? row.okDetail : row.missingDetail,
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String empty;
  final bool highlighted;

  const _AdviceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.empty,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final values = items.isEmpty ? [empty] : items;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      border: Border.all(
        color: highlighted ? color.withOpacity(0.55) : const Color(0xFFE7ECF5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: highlighted ? color : AppDesign.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppDesign.textColor(context),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 8,
            backgroundColor: const Color(0xFFE8EDF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final _ScoreLevel level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: level.color.withOpacity(0.28)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: level.color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Criterion {
  final String title;
  final String okDetail;
  final String missingDetail;
  final bool ok;

  const _Criterion(this.title, this.okDetail, this.missingDetail, this.ok);
}

class _ScoreLevel {
  final String label;
  final Color color;

  const _ScoreLevel(this.label, this.color);

  factory _ScoreLevel.fromScore(int score) {
    if (score <= 39) return const _ScoreLevel('À améliorer', Color(0xFFEF4444));
    if (score <= 69) return const _ScoreLevel('Correct', Color(0xFFF59E0B));
    if (score <= 84) return const _ScoreLevel('Bon', AppDesign.violet);
    return const _ScoreLevel('Excellent', Color(0xFF10B981));
  }
}
