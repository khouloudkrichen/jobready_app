import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/app_localizations.dart';
import '../services/firebase_service.dart';
import '../widgets/app_design.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLocale = 'fr';
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _selectedLocale = prefs.getString('locale') ?? 'fr';
    });
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    if (!mounted) return;
    setState(() => _darkMode = value);
    CareerBoostApp.of(
      context,
    )?.setTheme(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _setLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
    CareerBoostApp.of(context)?.setLocale(Locale(value));
  }

  Future<void> _confirmClear() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.t('Effacer les données ?', 'Clear data?')),
        content: Text(
          l.t(
            'Cette action supprimera tous vos profils et rapports d’entretien.',
            'This will delete all your profiles and interview reports.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.t('Annuler', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.t('Effacer', 'Clear'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);
    await FirebaseService.clearUserHistory();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastProfile');
    await prefs.remove('lastCvResult');
    await prefs.remove('lastInterviewReport');
    if (!mounted) return;
    setState(() => _clearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.t('Données supprimées avec succès', 'Data deleted successfully'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = FirebaseService.currentUser;
    final displayName = user?.displayName?.trim();

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          l.t('Paramètres', 'Settings'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppDesign.pageBg(context),
        foregroundColor: AppDesign.textColor(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          Text(
            l.t('Paramètres', 'Settings'),
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.t(
              'Personnalisez votre expérience',
              'Personalize your experience',
            ),
            style: TextStyle(
              color: AppDesign.mutedText(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppDesign.violet.withOpacity(0.14),
                  child: Text(
                    _initials(displayName ?? user?.email ?? 'U'),
                    style: const TextStyle(
                      color: AppDesign.violet,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  displayName?.isNotEmpty == true
                      ? displayName!
                      : (user?.email ?? 'CareerBoost User'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppDesign.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'AI Ready',
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(title: l.t('Apparence', 'Appearance')),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: const IconBadge(
                icon: Icons.dark_mode_outlined,
                color: AppDesign.navy,
                size: 38,
              ),
              title: Text(l.t('Mode sombre', 'Dark mode')),
              subtitle: Text(
                l.t(
                  'Ajuster la luminosité de l’interface.',
                  'Adjust screen brightness.',
                ),
              ),
              value: _darkMode,
              onChanged: _setDarkMode,
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(title: l.t('Langue', 'Language')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconBadge(
                      icon: Icons.language_rounded,
                      color: AppDesign.violet,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.t('Langue de l’app', 'App language'),
                        style: TextStyle(
                          color: AppDesign.textColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l.t(
                    'Cette option change uniquement la langue de l’interface.',
                    'This option only changes the interface language.',
                  ),
                  style: TextStyle(
                    color: AppDesign.mutedText(context),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LocaleButton(
                        label: 'Français',
                        selected: _selectedLocale == 'fr',
                        onTap: () => _setLocale('fr'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LocaleButton(
                        label: 'English',
                        selected: _selectedLocale == 'en',
                        onTap: () => _setLocale('en'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(title: l.t('Données', 'Data')),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              enabled: !_clearing,
              leading: const IconBadge(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                size: 38,
              ),
              title: Text(
                l.t('Effacer les données', 'Clear saved data'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                l.t(
                  'Supprimer profils et historique.',
                  'Delete profiles and history.',
                ),
              ),
              trailing: _clearing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 15),
              onTap: _clearing ? null : _confirmClear,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _LocaleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocaleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesign.isDark(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected
            ? AppDesign.textColor(context)
            : AppDesign.mutedText(context),
        backgroundColor: selected
            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4FF))
            : AppDesign.cardColor(context),
        side: BorderSide(
          color: selected ? AppDesign.violet : AppDesign.borderColor(context),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}
