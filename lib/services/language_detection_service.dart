import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

/// ============================================================
/// MODÈLE DE DONNÉES
/// ============================================================
class DetectedLanguage {
  final String code;
  final String name;
  final String flag;
  final double confidence;

  const DetectedLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.confidence,
  });

  String get displayName => '$flag $name';

  @override
  String toString() =>
      '$flag $name (${(confidence * 100).toStringAsFixed(0)}%)';
}

/// ============================================================
/// SERVICE DE DÉTECTION
/// ============================================================
class LanguageDetectionService {
  // Instance unique de l'identificateur avec un seuil de confiance de 0.4
  static final _identifier = LanguageIdentifier(confidenceThreshold: 0.4);

  // Dictionnaire des noms de langues
  static const _langNames = <String, String>{
    'fr': 'Français',
    'en': 'Anglais',
    'ar': 'Arabe',
    'es': 'Espagnol',
    'de': 'Allemand',
    'it': 'Italien',
    'pt': 'Portugais',
    'zh': 'Chinois',
    'ru': 'Russe',
    'tr': 'Turc',
  };

  // Dictionnaire des drapeaux
  static const _langFlags = <String, String>{
    'fr': '🇫🇷',
    'en': '🇬🇧',
    'ar': '🇹🇳',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'zh': '🇨🇳',
    'ru': '🇷🇺',
    'tr': '🇹🇷',
  };

  /// Détecter la langue principale du texte
  static Future<DetectedLanguage> detectLanguage(String text) async {
    if (text.trim().isEmpty) {
      return const DetectedLanguage(
        code: 'fr',
        name: 'Français',
        flag: '🇫🇷',
        confidence: 0.0,
      );
    }

    try {
      // Analyse des 500 premiers caractères pour optimiser les performances
      final sample = text.length > 500 ? text.substring(0, 500) : text;
      final langCode = await _identifier.identifyLanguage(sample);

      if (langCode == 'und') {
        // 'und' signifie indéterminé -> Retour par défaut
        return const DetectedLanguage(
          code: 'fr',
          name: 'Français',
          flag: '🇫🇷',
          confidence: 0.5,
        );
      }

      return DetectedLanguage(
        code: langCode,
        name: _langNames[langCode] ?? langCode.toUpperCase(),
        flag: _langFlags[langCode] ?? '🌐',
        confidence: 1.0,
      );
    } catch (e) {
      print("Erreur de détection ML Kit: $e");
      return const DetectedLanguage(
        code: 'fr',
        name: 'Français',
        flag: '🇫🇷',
        confidence: 0.0,
      );
    }
  }

  /// Détecter toutes les langues possibles avec leur score de confiance
  static Future<List<DetectedLanguage>> detectAllLanguages(String text) async {
    if (text.trim().isEmpty) return [];

    try {
      final sample = text.length > 500 ? text.substring(0, 500) : text;
      final languages = await _identifier.identifyPossibleLanguages(sample);

      return languages
          .where(
            (l) => l.confidence > 0.1,
          ) // Filtrer les résultats peu probables
          .map(
            (l) => DetectedLanguage(
              code: l.languageTag,
              name: _langNames[l.languageTag] ?? l.languageTag.toUpperCase(),
              flag: _langFlags[l.languageTag] ?? '🌐',
              confidence: l.confidence,
            ),
          )
          .toList();
    } catch (e) {
      print("Erreur de détection multiple ML Kit: $e");
      return [];
    }
  }

  /// Libérer les ressources
  static void dispose() {
    _identifier.close();
  }
}
