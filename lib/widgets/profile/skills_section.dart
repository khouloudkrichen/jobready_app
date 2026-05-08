// ============================================================
// widgets/profile/skills_section.dart — v3 MULTILINGUE
// Catégories de compétences traduites selon la langue du CV
// ============================================================

import 'package:flutter/material.dart';

class SkillsSection extends StatelessWidget {
  final String detectedCvLanguage;

  final List<String> programmingLanguages;
  final List<String> frameworks;
  final List<String> databases;
  final List<String> tools;
  final List<String> technicalSkills;
  final List<String> softSkills;

  const SkillsSection({
    super.key,
    this.detectedCvLanguage = '',
    this.programmingLanguages = const [],
    this.frameworks = const [],
    this.databases = const [],
    this.tools = const [],
    this.technicalSkills = const [],
    this.softSkills = const [],
  });

  @override
  Widget build(BuildContext context) {
    final labels = _SkillLabels(detectedCvLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (programmingLanguages.isNotEmpty)
          _CategoryChips(
            title: labels.programmingLanguages,
            icon: Icons.code,
            skills: programmingLanguages,
            color: const Color(0xFF3B82F6),
          ),

        if (frameworks.isNotEmpty)
          _CategoryChips(
            title: labels.frameworks,
            icon: Icons.layers_outlined,
            skills: frameworks,
            color: const Color(0xFF8B5CF6),
          ),

        if (databases.isNotEmpty)
          _CategoryChips(
            title: labels.databases,
            icon: Icons.storage_outlined,
            skills: databases,
            color: const Color(0xFF10B981),
          ),

        if (tools.isNotEmpty)
          _CategoryChips(
            title: labels.tools,
            icon: Icons.build_outlined,
            skills: tools,
            color: const Color(0xFFF59E0B),
          ),

        if (technicalSkills.isNotEmpty)
          _CategoryChips(
            title: labels.technicalSkills,
            icon: Icons.psychology_outlined,
            skills: technicalSkills,
            color: const Color(0xFFEC4899),
          ),

        if (softSkills.isNotEmpty)
          _CategoryChips(
            title: labels.softSkills,
            icon: Icons.people_outline,
            skills: softSkills,
            color: const Color(0xFF6B7280),
            outlined: true,
          ),
      ],
    );
  }
}

// ============================================================
// LABELS MULTILINGUES POUR SKILLS
// ============================================================

class _SkillLabels {
  final String lang;

  _SkillLabels(String detectedCvLanguage)
    : lang = detectedCvLanguage.toLowerCase().trim();

  bool get isEn =>
      lang.contains('anglais') || lang.contains('english') || lang == 'en';

  bool get isEs =>
      lang.contains('espagnol') ||
      lang.contains('spanish') ||
      lang.contains('español') ||
      lang == 'es';

  bool get isDe =>
      lang.contains('allemand') ||
      lang.contains('german') ||
      lang.contains('deutsch') ||
      lang == 'de';

  bool get isIt =>
      lang.contains('italien') ||
      lang.contains('italian') ||
      lang.contains('italiano') ||
      lang == 'it';

  bool get isPt =>
      lang.contains('portugais') ||
      lang.contains('portuguese') ||
      lang.contains('português') ||
      lang == 'pt';

  String pick({
    required String fr,
    required String en,
    required String es,
    required String de,
    required String it,
    required String pt,
  }) {
    if (isEn) return en;
    if (isEs) return es;
    if (isDe) return de;
    if (isIt) return it;
    if (isPt) return pt;
    return fr;
  }

  String get programmingLanguages => pick(
    fr: 'Langages de programmation',
    en: 'Programming languages',
    es: 'Lenguajes de programación',
    de: 'Programmiersprachen',
    it: 'Linguaggi di programmazione',
    pt: 'Linguagens de programação',
  );

  String get frameworks => pick(
    fr: 'Frameworks & Librairies',
    en: 'Frameworks & Libraries',
    es: 'Frameworks y librerías',
    de: 'Frameworks & Bibliotheken',
    it: 'Framework e librerie',
    pt: 'Frameworks e bibliotecas',
  );

  String get databases => pick(
    fr: 'Bases de données',
    en: 'Databases',
    es: 'Bases de datos',
    de: 'Datenbanken',
    it: 'Database',
    pt: 'Bases de dados',
  );

  String get tools => pick(
    fr: 'Outils & DevOps',
    en: 'Tools & DevOps',
    es: 'Herramientas y DevOps',
    de: 'Tools & DevOps',
    it: 'Strumenti e DevOps',
    pt: 'Ferramentas e DevOps',
  );

  String get technicalSkills => pick(
    fr: 'Compétences techniques',
    en: 'Technical skills',
    es: 'Competencias técnicas',
    de: 'Technische Fähigkeiten',
    it: 'Competenze tecniche',
    pt: 'Competências técnicas',
  );

  String get softSkills => pick(
    fr: 'Soft skills',
    en: 'Soft skills',
    es: 'Habilidades blandas',
    de: 'Soziale Kompetenzen',
    it: 'Soft skills',
    pt: 'Competências interpessoais',
  );
}

// ============================================================
// CATEGORY CHIPS
// ============================================================

class _CategoryChips extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> skills;
  final Color color;
  final bool outlined;

  const _CategoryChips({
    required this.title,
    required this.icon,
    required this.skills,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanSkills = skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (cleanSkills.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cleanSkills
                .map(
                  (skill) => _SkillChip(
                    label: skill,
                    color: color,
                    outlined: outlined,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SKILL CHIP
// ============================================================

class _SkillChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const _SkillChip({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.12),
        border: Border.all(
          color: color.withOpacity(outlined ? 0.6 : 0.3),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: outlined
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
