import 'package:flutter/material.dart';

import '../../models/candidate_profile.dart';
import '../../screens/interview_screen.dart';
import '../../services/interview_question_service.dart';
import '../app_design.dart';

Future<void> openInterviewDifficultySelector(
  BuildContext context, {
  required CandidateProfile profile,
}) async {
  final difficulty = await showModalBottomSheet<InterviewDifficulty>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return const _InterviewDifficultySheet();
    },
  );

  if (difficulty == null) return;
  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InterviewScreen(profile: profile, difficulty: difficulty),
    ),
  );
}

class _InterviewDifficultySheet extends StatelessWidget {
  const _InterviewDifficultySheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, bottom + 18),
      decoration: BoxDecoration(
        color: AppDesign.pageBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Text(
            'Choisir le niveau',
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const _DifficultyTile(
            difficulty: InterviewDifficulty.beginner,
            icon: Icons.school_rounded,
            title: 'Débutant',
            subtitle: 'Questions simples sur CV, formation et projets.',
          ),
          const SizedBox(height: 10),
          const _DifficultyTile(
            difficulty: InterviewDifficulty.nonBeginner,
            icon: Icons.work_outline_rounded,
            title: 'Non débutant',
            subtitle: 'Questions plus professionnelles et techniques.',
          ),
        ],
      ),
    );
  }
}

class InterviewDifficultySelectorScreen extends StatefulWidget {
  final CandidateProfile profile;

  const InterviewDifficultySelectorScreen({super.key, required this.profile});

  @override
  State<InterviewDifficultySelectorScreen> createState() =>
      _InterviewDifficultySelectorScreenState();
}

class _InterviewDifficultySelectorScreenState
    extends State<InterviewDifficultySelectorScreen> {
  InterviewDifficulty _selected = InterviewDifficulty.nonBeginner;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Text(
              'Prêt pour votre entretien ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppDesign.textColor(context),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez votre niveau pour personnaliser les questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _SelectableDifficultyCard(
              selected: _selected == InterviewDifficulty.beginner,
              difficulty: InterviewDifficulty.beginner,
              icon: Icons.school_rounded,
              title: 'Débutant',
              subtitle:
                  'Questions simples axées sur les fondamentaux, la motivation et le parcours académique.',
              onTap: () =>
                  setState(() => _selected = InterviewDifficulty.beginner),
            ),
            const SizedBox(height: 14),
            _SelectableDifficultyCard(
              selected: _selected == InterviewDifficulty.nonBeginner,
              difficulty: InterviewDifficulty.nonBeginner,
              icon: Icons.work_outline_rounded,
              title: 'Non débutant',
              subtitle:
                  'Questions professionnelles complexes, mises en situation et défis techniques avancés.',
              onTap: () =>
                  setState(() => _selected = InterviewDifficulty.nonBeginner),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(icon: Icons.auto_awesome_rounded, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Première question prévue : “Présentez-vous brièvement.”',
                      style: TextStyle(
                        color: AppDesign.textColor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Commencer l’entretien',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InterviewScreen(
                      profile: widget.profile,
                      difficulty: _selected,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Vous pouvez quitter l’entretien à tout moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD7DEE9),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final InterviewDifficulty difficulty;
  final IconData icon;
  final String title;
  final String subtitle;

  const _DifficultyTile({
    required this.difficulty,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.pop(context, difficulty),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppDesign.violet, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppDesign.textColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppDesign.textColor(context),
          ),
        ],
      ),
    );
  }
}

class _SelectableDifficultyCard extends StatelessWidget {
  final bool selected;
  final InterviewDifficulty difficulty;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectableDifficultyCard({
    required this.selected,
    required this.difficulty,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: Border.all(
        color: selected ? AppDesign.violet : AppDesign.borderColor(context),
        width: selected ? 1.5 : 1,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: AppDesign.violet, size: 42),
              const Spacer(),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppDesign.violet
                    : AppDesign.mutedText(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppDesign.mutedText(context),
              height: 1.35,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: selected
                    ? AppDesign.violet
                    : AppDesign.textColor(context),
              ),
              const SizedBox(width: 5),
              Text(
                difficulty == InterviewDifficulty.beginner
                    ? '10-15 minutes'
                    : '15-20 minutes',
                style: TextStyle(
                  color: selected
                      ? AppDesign.violet
                      : AppDesign.textColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
