import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/candidate_profile.dart';
import '../services/app_localizations.dart';
import '../services/firebase_service.dart';
import '../widgets/app_design.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _loadProfiles();
  }

  Future<List<Map<String, dynamic>>> _loadProfiles() async {
    final profiles = await FirebaseService.getProfiles();
    return _dedupeProfiles(profiles);
  }

  Future<void> _refreshProfiles() async {
    setState(() {
      _profilesFuture = _loadProfiles();
    });
    await _profilesFuture;
  }

  List<Map<String, dynamic>> _dedupeProfiles(
    List<Map<String, dynamic>> values,
  ) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final profile in values) {
      final id = (profile['id'] ?? '').toString();
      final fallbackKey =
          '${profile['fullName'] ?? ''}-${profile['email'] ?? ''}-${profile['phone'] ?? ''}';
      final key = id.isNotEmpty ? id : fallbackKey;
      if (seen.add(key)) result.add(profile);
    }

    return result;
  }

  Future<void> _confirmDelete(Map<String, dynamic> profile) async {
    final name = (profile['fullName'] ?? 'ce profil').toString().trim();
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text(
          name.isEmpty
              ? 'Cette action supprimera ce profil de votre historique.'
              : 'Cette action supprimera "$name" de votre historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (delete != true) return;

    final id = (profile['id'] ?? '').toString();
    if (id.isEmpty) return;

    await FirebaseService.deleteProfile(id);
    if (!mounted) return;
    await _refreshProfiles();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil supprimé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return AppScaffold(
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profilesFuture,
          builder: (context, snapshot) {
            final profiles = snapshot.data ?? const <Map<String, dynamic>>[];

            return RefreshIndicator(
              onRefresh: _refreshProfiles,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  _Header(
                    onSettings: () => Navigator.pushNamed(context, '/settings'),
                    onSignOut: FirebaseService.signOut,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l.t('Bonjour, ${_firstName()}', 'Hi, ${_firstName()}'),
                    style: TextStyle(
                      color: AppDesign.textColor(context),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.t(
                      'Prêt pour votre prochaine étape de carrière ?',
                      'Ready for your next career step?',
                    ),
                    style: TextStyle(
                      color: AppDesign.mutedText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _HeroCard(
                    onTap: () => Navigator.pushNamed(context, '/cv-scanner'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.document_scanner_rounded,
                          title: l.t('Scanner le CV', 'Scan CV'),
                          body: l.t(
                            'Analyse et conseils pour améliorer ton profil.',
                            'Analysis and advice to improve your profile.',
                          ),
                          onTap: () =>
                              Navigator.pushNamed(context, '/cv-scanner'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.dashboard_rounded,
                          title: l.t('Tableau de bord', 'Dashboard'),
                          body: l.t(
                            'Suis tes profils et tes simulations.',
                            'Track profiles and simulations.',
                          ),
                          onTap: () =>
                              Navigator.pushNamed(context, '/dashboard'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (profiles.isNotEmpty)
                    _ProfilesList(
                      profiles: profiles,
                      onOpen: (profile) => Navigator.pushNamed(
                        context,
                        '/cv-result',
                        arguments: CandidateProfile.fromJson(profile),
                      ),
                      onDelete: _confirmDelete,
                    )
                  else
                    _EmptyProfileCard(
                      onScan: () => Navigator.pushNamed(context, '/cv-scanner'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _firstName() {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name == null || name.isEmpty) return 'vous';
    return name.split(RegExp(r'\s+')).first;
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const _Header({required this.onSettings, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppDesign.gradient,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'JobReady',
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Paramètres',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'Déconnexion',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppDesign.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppDesign.softShadow(opacity: 0.18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Construis ton avenir professionnel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.03,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Analyse ton CV, améliore ton profil et entraîne-toi aux entretiens.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppDesign.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: const Text('Analyser mon CV'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: icon,
            color: AppDesign.isDark(context) ? AppDesign.violetSoft : AppDesign.navy,
            size: 38,
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
          const SizedBox(height: 5),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppDesign.mutedText(context),
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilesList extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _ProfilesList({
    required this.profiles,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Profils analysés', trailing: '${profiles.length}'),
        ...profiles.map(
          (profile) => _ProfileHistoryCard(
            profile: profile,
            onOpen: () => onOpen(profile),
            onDelete: () => onDelete(profile),
          ),
        ),
      ],
    );
  }
}

class _ProfileHistoryCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ProfileHistoryCard({
    required this.profile,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = (profile['fullName'] ?? '').toString().trim();
    final title = (profile['profileTitle'] ?? '').toString().trim();
    final domain = (profile['mainDomain'] ?? '').toString().trim();
    final displayTitle = title.isNotEmpty
        ? title
        : (domain.isNotEmpty ? domain : 'Profil détecté');
    final initials = _initials(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppDesign.violet.withOpacity(0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppDesign.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Profil candidat' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppDesign.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppDesign.mutedText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ouvrir',
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onPressed: onOpen,
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _LastProfileCard extends StatelessWidget {
  final CandidateProfile profile;

  const _LastProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Dernier profil analysé'),
        AppCard(
          onTap: () =>
              Navigator.pushNamed(context, '/cv-result', arguments: profile),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppDesign.violet.withOpacity(0.12),
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: AppDesign.violet,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.profileTitle.isNotEmpty
                          ? profile.profileTitle
                          : (profile.mainDomain.isNotEmpty
                                ? profile.mainDomain
                                : 'Profil détecté'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppDesign.mutedText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyProfileCard extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyProfileCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.folder_open_rounded,
            color: AppDesign.violet,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun profil analysé',
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scanne un CV pour créer ton premier profil candidat.',
            style: TextStyle(
              color: AppDesign.mutedText(context),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Scanner un CV',
            icon: Icons.document_scanner_rounded,
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}
