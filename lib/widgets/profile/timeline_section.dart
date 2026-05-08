// ============================================================
// timeline_section.dart — v2 (overflow corrigé)
// ============================================================

import 'package:flutter/material.dart';
import '../../models/candidate_profile.dart';

class ExperienceTimeline extends StatelessWidget {
  final List<ExperienceItem> experiences;
  const ExperienceTimeline({super.key, required this.experiences});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: experiences.asMap().entries.map((entry) {
        return _TimelineItem(
          isLast: entry.key == experiences.length - 1,
          dotColor: Theme.of(context).colorScheme.primary,
          title: entry.value.poste,
          subtitle: entry.value.entreprise,
          period: entry.value.periode,
          description: entry.value.description,
          tags: entry.value.technologies,
          tagColor: const Color(0xFF3B82F6),
        );
      }).toList(),
    );
  }
}

class EducationTimeline extends StatelessWidget {
  final List<EducationItem> education;
  const EducationTimeline({super.key, required this.education});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: education.asMap().entries.map((entry) {
        final edu = entry.value;
        final subtitle = edu.etablissement;
        final desc = edu.specialite.isNotEmpty
            ? edu.specialite
            : edu.description;
        return _TimelineItem(
          isLast: entry.key == education.length - 1,
          dotColor: const Color(0xFF10B981),
          title: edu.diplome,
          subtitle: subtitle,
          period: edu.periode,
          description: desc,
          tags: const [],
          tagColor: const Color(0xFF10B981),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════
// TIMELINE ITEM — overflow corrigé avec Flexible/Expanded
// ══════════════════════════════════════════════════════════

class _TimelineItem extends StatelessWidget {
  final bool isLast;
  final Color dotColor;
  final String title;
  final String subtitle;
  final String period;
  final String description;
  final List<String> tags;
  final Color tagColor;

  const _TimelineItem({
    required this.isLast,
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.period,
    required this.description,
    required this.tags,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne + dot ──────────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dotColor.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Contenu ──────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre ────────────────────────
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  // ── Période ──────────────────────
                  if (period.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 11,
                          color: dotColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // ── Entreprise / École ────────────
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(width: 4),
                        // ← Flexible empêche l'overflow
                        Flexible(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.55),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Description ───────────────────
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.72),
                        height: 1.45,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // ── Tags technologies ─────────────
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tagColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
