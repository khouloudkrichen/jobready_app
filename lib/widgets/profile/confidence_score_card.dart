import 'package:flutter/material.dart';

class ConfidenceScoreCard extends StatelessWidget {
  final double overallScore;
  final double nameConfidence;
  final double contactConfidence;
  final double skillsConfidence;
  final double experienceConfidence;
  final double educationConfidence;
  final double domainConfidence;

  const ConfidenceScoreCard({
    super.key,
    required this.overallScore,
    required this.nameConfidence,
    required this.contactConfidence,
    required this.skillsConfidence,
    required this.experienceConfidence,
    required this.educationConfidence,
    required this.domainConfidence,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (overallScore * 100).round();
    final color = percent >= 75
        ? const Color(0xFF10B981)
        : percent >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score du profil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    Text(
                      _getQualityLabel(percent),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            ('Identité', nameConfidence),
            ('Contact', contactConfidence),
            ('Compétences', skillsConfidence),
            ('Expérience', experienceConfidence),
            ('Formation', educationConfidence),
            ('Domaine', domainConfidence),
          ].map(
            (item) => _ScoreBar(label: item.$1, value: item.$2, color: color),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(int percent) {
    if (percent >= 80) return 'Profil excellent · Prêt pour postuler';
    if (percent >= 60) return 'Bon profil · Quelques améliorations possibles';
    if (percent >= 40) return 'Profil partiel · CV à compléter';
    return "Profil incomplet · Ajouter plus d'informations";
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
