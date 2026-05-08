// ============================================================
// main.dart — v6 avec Firebase + choix niveau entretien
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/cv_scanner_screen.dart';
import 'screens/cv_result_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

import 'models/candidate_profile.dart';
import 'widgets/interview/interview_difficulty_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Orientation portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Lire préférences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  final locale = prefs.getString('locale') ?? 'fr';

  runApp(CareerBoostApp(isDark: isDark, savedLocale: locale));
}

class CareerBoostApp extends StatefulWidget {
  final bool isDark;
  final String savedLocale;

  const CareerBoostApp({
    super.key,
    required this.isDark,
    required this.savedLocale,
  });

  static _CareerBoostAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_CareerBoostAppState>();

  @override
  State<CareerBoostApp> createState() => _CareerBoostAppState();
}

class _CareerBoostAppState extends State<CareerBoostApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(widget.savedLocale);
  }

  void setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', mode == ThemeMode.dark);
  }

  void setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobReady',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      locale: _locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Gestion Auth Firebase ──────────────
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          return const AuthScreen();
        },
      ),

      onGenerateRoute: _generateRoute,
    );
  }

  // ─────────────────────────────────────────
  // THÈME CLAIR
  // ─────────────────────────────────────────

  ThemeData _buildLightTheme() {
    const primary = Color(0xFF1E3A5F);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: const Color(0xFFF4A623),
        brightness: Brightness.light,
        surface: Colors.white,
        background: const Color(0xFFF0F4FF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F4FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // THÈME SOMBRE
  // ─────────────────────────────────────────

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF4A90D9);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: const Color(0xFFF4A623),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E2530),
        background: const Color(0xFF0D1117),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: const Color(0xFF1E2530),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ROUTES
  // ─────────────────────────────────────────

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _slide(const HomeScreen(), settings);

      case '/cv-scanner':
        return _slide(const CvScannerScreen(), settings);

      case '/cv-result':
        final profile = settings.arguments as CandidateProfile?;
        if (profile == null) {
          return _fade(const HomeScreen(), settings);
        }
        return _slide(CvResultScreen(profile: profile), settings);

      case '/interview':
        final profile = settings.arguments as CandidateProfile?;

        // IMPORTANT :
        // Avant : on ouvrait directement InterviewScreen(profile: profile)
        // Maintenant : on ouvre d'abord l'écran de choix du niveau.
        return _slide(
          InterviewDifficultySelectorScreen(
            profile: profile ?? CandidateProfile(),
          ),
          settings,
        );

      case '/dashboard':
        return _slide(const DashboardScreen(), settings);

      case '/settings':
        return _slide(const SettingsScreen(), settings);

      case '/auth':
        return _fade(const AuthScreen(), settings);

      default:
        return _fade(const HomeScreen(), settings);
    }
  }

  PageRouteBuilder _slide(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(a),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  PageRouteBuilder _fade(Widget page, RouteSettings s) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        return FadeTransition(opacity: a, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

// ══════════════════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════════════════

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, const Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'JobReady',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: primary, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
