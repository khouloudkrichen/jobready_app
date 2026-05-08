import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_localizations.dart';
import '../services/firebase_service.dart';
import '../widgets/app_design.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AuthLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'JobReady',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppDesign.ink,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.t(
                      'Votre coach intelligent pour CV et entretien.',
                      'Your intelligent CV and interview coach.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppDesign.muted,
                      height: 1.35,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    radius: 26,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        PillTabShell(
                          controller: _tab,
                          tabs: [
                            Tab(text: l.t('Connexion', 'Sign in')),
                            Tab(text: l.t('Inscription', 'Create account')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          child: _tab.index == 0
                              ? _LoginForm(
                                  email: _loginEmail,
                                  password: _loginPassword,
                                  obscure: _obscure,
                                  onToggle: () =>
                                      setState(() => _obscure = !_obscure),
                                )
                              : _SignupForm(
                                  name: _signupName,
                                  email: _signupEmail,
                                  password: _signupPassword,
                                  obscure: _obscure,
                                  onToggle: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                        ),
                        const SizedBox(height: 18),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          GradientButton(
                            label: _tab.index == 0
                                ? l.t('Se connecter', 'Sign in')
                                : l.t('Créer le compte', 'Create account'),
                            icon: _tab.index == 0
                                ? Icons.arrow_forward_rounded
                                : Icons.person_add_alt_rounded,
                            onPressed: _tab.index == 0 ? _login : _signup,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  l.t('ou', 'or').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppDesign.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _googleSignIn,
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 30,
                              ),
                              label: Text(
                                l.t(
                                  'Continuer avec Google',
                                  'Continue with Google',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppDesign.ink,
                                side: const BorderSide(
                                  color: Color(0xFFD7DEE9),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          if (_tab.index == 0)
                            TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                l.t(
                                  'Mot de passe oublié ?',
                                  'Forgot password?',
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppDesign.muted,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Sécurisé par CareerBoost Cloud',
                        style: TextStyle(
                          color: AppDesign.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l = AppLocalizations.of(context);
    if (_loginEmail.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      _showError(l.t('Remplissez tous les champs.', 'Fill in all fields.'));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseService.signIn(
        email: _loginEmail.text.trim(),
        password: _loginPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    final l = AppLocalizations.of(context);
    if (_signupName.text.trim().isEmpty ||
        _signupEmail.text.trim().isEmpty ||
        _signupPassword.text.isEmpty) {
      _showError(l.t('Remplissez tous les champs.', 'Fill in all fields.'));
      return;
    }
    if (_signupPassword.text.length < 6) {
      _showError(
        l.t(
          'Mot de passe minimum 6 caractères.',
          'Password must be at least 6 characters.',
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseService.signUp(
        name: _signupName.text.trim(),
        email: _signupEmail.text.trim(),
        password: _signupPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_authError(e.code));
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        _showError(
          l.t('Connexion Google impossible : $e', 'Google sign-in failed: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    if (_loginEmail.text.trim().isEmpty) {
      _showError(l.t('Entrez votre email d’abord.', 'Enter your email first.'));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseService.resetPassword(_loginEmail.text.trim());
      if (!mounted) return;
      _showSuccess(
        l.t('Email de réinitialisation envoyé.', 'Password reset email sent.'),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_authError(e.code));
    } catch (e) {
      if (mounted) {
        _showError(
          l.t('Envoi impossible : $e', 'Unable to send reset email: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    final l = AppLocalizations.of(context);
    switch (code) {
      case 'user-not-found':
        return l.t(
          'Aucun compte avec cet email.',
          'No account found for this email.',
        );
      case 'wrong-password':
        return l.t('Mot de passe incorrect.', 'Incorrect password.');
      case 'email-already-in-use':
        return l.t('Email déjà utilisé.', 'Email already in use.');
      case 'weak-password':
        return l.t('Mot de passe trop faible.', 'Password is too weak.');
      case 'invalid-email':
        return l.t('Email invalide.', 'Invalid email.');
      case 'missing-email':
        return l.t('Email obligatoire.', 'Email is required.');
      case 'user-disabled':
        return l.t('Ce compte est dÃ©sactivÃ©.', 'This account is disabled.');
      case 'operation-not-allowed':
        return l.t(
          'Cette mÃ©thode de connexion nâ€™est pas activÃ©e dans Firebase.',
          'This sign-in method is not enabled in Firebase.',
        );
      case 'too-many-requests':
        return l.t(
          'Trop de tentatives. RÃ©essayez plus tard.',
          'Too many attempts. Try again later.',
        );
      case 'network-request-failed':
        return l.t(
          'ProblÃ¨me de connexion Internet.',
          'Network connection problem.',
        );
      case 'account-exists-with-different-credential':
        return l.t(
          'Un compte existe dÃ©jÃ  avec cet email via une autre mÃ©thode.',
          'An account already exists with this email using another method.',
        );
      case 'invalid-credential':
        return l.t(
          'Identifiants invalides ou expirÃ©s.',
          'Invalid or expired credentials.',
        );
      default:
        return code;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesign.gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppDesign.softShadow(opacity: 0.14)],
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggle;

  const _LoginForm({
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        _Field(
          controller: email,
          label: 'Adresse Email',
          hint: 'nom@exemple.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: password,
          label: l.t('Mot de passe', 'Password'),
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: obscure,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _SignupForm extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggle;

  const _SignupForm({
    required this.name,
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        _Field(
          controller: name,
          label: l.t('Nom complet', 'Full name'),
          hint: 'Alex Sterling',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: email,
          label: 'Adresse Email',
          hint: 'nom@exemple.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: password,
          label: l.t('Mot de passe', 'Password'),
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: obscure,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final VoidCallback? onToggle;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppDesign.muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: const Color(0xFF8B95A5)),
            suffixIcon: onToggle == null
                ? null
                : IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
            filled: true,
            fillColor: const Color(0xFFF1F4F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
