import 'package:flutter/material.dart';

import '../models/candidate_profile.dart';
import '../models/cv_analysis_result.dart';
import '../services/cv_analysis_service.dart';
import '../widgets/app_design.dart';
import '../widgets/profile/certifications_section.dart';
import '../widgets/profile/projects_section.dart';
import '../widgets/profile/skills_section.dart';
import '../widgets/profile/timeline_section.dart';

class CvResultScreen extends StatelessWidget {
  final CandidateProfile profile;

  const CvResultScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final analysis = CvAnalysisService.analyze(profile);

    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text(
            'JobReady',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: AppDesign.pageBg(context),
          foregroundColor: AppDesign.textColor(context),
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  children: [
                    _ProfileHero(profile: profile),
                    const SizedBox(height: 12),
                    const PillTabShell(
                      tabs: [
                        Tab(text: 'Profil'),
                        Tab(text: 'Analyse CV'),
                        Tab(text: 'Détails'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _TabList(child: _ProfileTab(profile: profile)),
                    _TabList(child: _AnalysisTab(analysis: analysis)),
                    _TabList(child: _DetailsTab(profile: profile)),
                  ],
                ),
              ),
              _BottomActions(profile: profile),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final CandidateProfile profile;

  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final title = profile.profileTitle.isNotEmpty
        ? profile.profileTitle
        : (profile.mainDomain.isNotEmpty ? profile.mainDomain : 'Profil CV');

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppDesign.violet.withOpacity(0.14),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: AppDesign.violet,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isEmpty
                      ? 'Profil candidat'
                      : profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppDesign.textColor(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (profile.location.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppDesign.mutedText(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppDesign.mutedText(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (profile.linkedin.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'LinkedIn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabList extends StatelessWidget {
  final Widget child;

  const _TabList({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [child],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final CandidateProfile profile;

  const _ProfileTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Profil détecté',
          icon: Icons.auto_awesome_rounded,
          children: [
            _Kv('Langue du CV', _value(profile.detectedCvLanguage)),
            _Kv('Domaine détecté', _value(profile.mainDomain)),
            if (profile.secondaryDomains.isNotEmpty)
              _Kv('Domaines secondaires', profile.secondaryDomains.join(', ')),
          ],
        ),
        _InfoCard(
          title: 'Résumé professionnel',
          icon: Icons.notes_rounded,
          children: [
            Text(
              profile.summary.isEmpty
                  ? 'Aucun résumé professionnel détecté dans le CV.'
                  : profile.summary,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        _InfoCard(
          title: 'Informations principales',
          icon: Icons.badge_outlined,
          children: [
            _Kv('Email', _value(profile.email)),
            _Kv('Téléphone', _value(profile.phone)),
            _Kv('Localisation', _value(profile.location)),
            _Kv('LinkedIn', _value(profile.linkedin)),
            _Kv('GitHub', _value(profile.github)),
            _Kv('Portfolio', _value(profile.portfolio)),
          ],
        ),
      ],
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final CvAnalysisResult analysis;

  const _AnalysisTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ScoreCard(score: analysis.score)),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                title: 'Vérification',
                icon: Icons.fact_check_outlined,
                compact: true,
                children: [
                  _CheckLine('Email détecté', analysis.hasEmail),
                  _CheckLine('Téléphone détecté', analysis.hasPhone),
                  _CheckLine('LinkedIn détecté', analysis.hasLinkedIn),
                  _CheckLine('GitHub détecté', analysis.hasGitHub),
                  _CheckLine(
                    'Compétences détectées',
                    analysis.skillsCount >= 3,
                  ),
                  _CheckLine(
                    'Expériences détectées',
                    analysis.experiencesCount > 0,
                  ),
                  _CheckLine('Projets détectés', analysis.projectsCount > 0),
                  _CheckLine('Résumé détecté', analysis.hasSummary),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Compétences',
                value: '${analysis.skillsCount}',
                icon: Icons.psychology_rounded,
                color: AppDesign.violet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppStatCard(
                label: 'Expériences',
                value: '${analysis.experiencesCount}',
                icon: Icons.work_rounded,
                color: AppDesign.navy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppStatCard(
                label: 'Projets',
                value: '${analysis.projectsCount}',
                icon: Icons.rocket_launch_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        _BulletCard(
          title: 'Points forts',
          icon: Icons.auto_awesome_rounded,
          color: AppDesign.violet,
          items: analysis.strengths,
          empty: 'Aucun point fort détecté pour le moment.',
        ),
        _BulletCard(
          title: 'Points à améliorer',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFF59E0B),
          items: analysis.improvements,
          empty: 'Aucun point bloquant détecté.',
        ),
        _BulletCard(
          title: 'Conseils d’amélioration',
          icon: Icons.lightbulb_outline_rounded,
          color: AppDesign.violet,
          items: analysis.advice,
          empty: 'Votre CV contient déjà les éléments essentiels.',
          highlighted: true,
        ),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final CandidateProfile profile;

  const _DetailsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (profile.hasEducation)
          _InfoCard(
            title: 'Formation',
            icon: Icons.school_rounded,
            children: [EducationTimeline(education: profile.education)],
          ),
        if (profile.hasExperiences)
          _InfoCard(
            title: 'Expériences',
            icon: Icons.work_rounded,
            children: [ExperienceTimeline(experiences: profile.experiences)],
          ),
        if (profile.hasProjects)
          _InfoCard(
            title: 'Projets',
            icon: Icons.rocket_launch_rounded,
            children: [ProjectsSection(projects: profile.projects)],
          ),
        if (profile.hasCertifications)
          _InfoCard(
            title: 'Certifications',
            icon: Icons.verified_rounded,
            children: [
              CertificationsSection(certifications: profile.certifications),
            ],
          ),
        if (profile.hasSkills || profile.hasSoftSkills)
          _InfoCard(
            title: 'Compétences',
            icon: Icons.psychology_rounded,
            children: [
              SkillsSection(
                detectedCvLanguage: profile.detectedCvLanguage,
                programmingLanguages: profile.programmingLanguages,
                frameworks: profile.frameworks,
                databases: profile.databases,
                tools: profile.tools,
                technicalSkills: profile.technicalSkills,
                softSkills: profile.softSkills,
              ),
            ],
          ),
        if (profile.hasLanguages)
          _InfoCard(
            title: 'Langues',
            icon: Icons.language_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.spokenLanguages
                    .map(
                      (l) => Chip(
                        label: Text(
                          l.niveau.isEmpty
                              ? l.langue
                              : '${l.langue} · ${l.niveau}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        if (profile.hasAssociations)
          _InfoCard(
            title: 'Centres d’intérêt',
            icon: Icons.favorite_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.associations
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
          ),
        if (!profile.hasEducation &&
            !profile.hasExperiences &&
            !profile.hasProjects &&
            !profile.hasSkills)
          AppCard(
            child: Text(
              'Aucun détail structuré détecté. Scannez une image plus lisible du CV.',
              style: TextStyle(color: AppDesign.mutedText(context)),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool compact;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: AppDesign.violet, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppDesign.textColor(context),
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;

  const _Kv(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppDesign.textColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final level = _CvScoreLevel.fromScore(score);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: const Color(0xFFE8EDF5),
                  valueColor: AlwaysStoppedAnimation(level.color),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          color: level.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          color: AppDesign.mutedText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score CV',
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              level.label,
              style: TextStyle(
                color: level.color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Qualité des informations présentes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppDesign.mutedText(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CvScoreLevel {
  final String label;
  final Color color;

  const _CvScoreLevel(this.label, this.color);

  factory _CvScoreLevel.fromScore(int score) {
    if (score <= 39)
      return const _CvScoreLevel('À améliorer', Color(0xFFEF4444));
    if (score <= 69) return const _CvScoreLevel('Correct', Color(0xFFF59E0B));
    if (score <= 84) return const _CvScoreLevel('Bon', AppDesign.violet);
    return const _CvScoreLevel('Excellent', Color(0xFF10B981));
  }
}

class _CheckLine extends StatelessWidget {
  final String label;
  final bool ok;

  const _CheckLine(this.label, this.ok);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String empty;
  final bool highlighted;

  const _BulletCard({
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
        color: highlighted
            ? AppDesign.violet.withOpacity(0.55)
            : const Color(0xFFE7ECF5),
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
                  color: highlighted
                      ? AppDesign.violet
                      : AppDesign.textColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, color: color, size: 7),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppDesign.textColor(context),
                        height: 1.35,
                        fontSize: 13,
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

class _BottomActions extends StatelessWidget {
  final CandidateProfile profile;

  const _BottomActions({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppDesign.pageBg(context).withOpacity(0.96),
          border: Border(top: BorderSide(color: AppDesign.borderColor(context))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/cv-scanner'),
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Autre CV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppDesign.textColor(context),
                  side: BorderSide(color: AppDesign.borderColor(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: 'Simuler l’entretien',
                icon: Icons.video_call_rounded,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/interview',
                  arguments: profile,
                ),
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _value(String value) {
  final clean = value.trim();
  return clean.isEmpty ? 'Non détecté' : clean;
}
