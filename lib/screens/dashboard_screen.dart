import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/candidate_profile.dart';
import '../services/app_localizations.dart';
import '../services/firebase_service.dart';
import '../widgets/app_design.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _interviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profiles = await FirebaseService.getProfiles();
      final interviews = await FirebaseService.getInterviews();
      if (!mounted) return;
      setState(() {
        _profiles = _dedupeProfiles(profiles);
        _interviews = interviews;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: const Text(
          'Cette action supprimera ce profil de votre historique.',
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
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'JobReady',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppDesign.bg,
        foregroundColor: AppDesign.ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l.t('Actualiser', 'Refresh'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Text(
                    l.t(
                      'Bonjour, ${_firstName(user)}',
                      'Hi, ${_firstName(user)}',
                    ),
                    style: const TextStyle(
                      color: AppDesign.ink,
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
                    style: const TextStyle(
                      color: AppDesign.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppStatCard(
                          label: l.t('CVs analysés', 'Analyzed CVs'),
                          value: '${_profiles.length}',
                          icon: Icons.description_rounded,
                          color: AppDesign.violet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppStatCard(
                          label: l.t('Entretiens', 'Interviews'),
                          value: '${_interviews.length}',
                          icon: Icons.videocam_rounded,
                          color: AppDesign.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _InsightCard(
                    onScan: () => Navigator.pushNamed(context, '/cv-scanner'),
                  ),
                  const SizedBox(height: 22),
                  SectionTitle(
                    title: l.t('Profils enregistrés', 'Saved profiles'),
                    trailing: '${_profiles.length}',
                  ),
                  if (_profiles.isEmpty)
                    _EmptyState(
                      onTap: () => Navigator.pushNamed(context, '/cv-scanner'),
                    )
                  else
                    ..._profiles.map(
                      (p) => _ProfileRow(
                        data: p,
                        onOpen: () {
                          Navigator.pushNamed(
                            context,
                            '/cv-result',
                            arguments: CandidateProfile.fromJson(p),
                          );
                        },
                        onDelete: () => _confirmDelete(p),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _firstName(User? user) {
    final name = user?.displayName?.trim();
    if (name == null || name.isEmpty) return 'vous';
    return name.split(RegExp(r'\s+')).first;
  }
}

class _InsightCard extends StatelessWidget {
  final VoidCallback onScan;

  const _InsightCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyse AI de votre CV',
            style: TextStyle(
              color: AppDesign.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Obtenez un score de compatibilité instantané pour votre poste cible.',
            style: TextStyle(
              color: AppDesign.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: onScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Scanner maintenant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ProfileRow({
    required this.data,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['fullName'] ?? 'Profil candidat').toString();
    final title = (data['profileTitle'] ?? data['mainDomain'] ?? '').toString();
    final initials = _initials(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        radius: 18,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppDesign.violet.withOpacity(0.14),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppDesign.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.trim().isEmpty ? 'Profil candidat' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppDesign.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppDesign.muted,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const IconBadge(
            icon: Icons.folder_open_rounded,
            color: AppDesign.violet,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun profil sauvegardé',
            style: TextStyle(
              color: AppDesign.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Analysez un CV pour retrouver vos profils ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppDesign.muted,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Scanner un CV',
            icon: Icons.document_scanner_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
