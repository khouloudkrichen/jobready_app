import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

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
  String toString() {
    final percent = (confidence * 100).toStringAsFixed(0);
    return '$flag $name ($percent%)';
  }
}

class LanguageDetectionService {
  static LanguageIdentifier? _identifier;

  static LanguageIdentifier get _languageIdentifier {
    return _identifier ??= LanguageIdentifier(confidenceThreshold: 0.25);
  }

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

  static Future<DetectedLanguage> detectLanguage(String text) async {
    final normalized = _normalizeForDetection(text);
    debugPrint(
      'CV language detection OCR sample: ${_preview(normalized, max: 700)}',
    );

    if (normalized.isEmpty) return _fallback(confidence: 0.0);

    try {
      final sample = normalized.length > 2500
          ? normalized.substring(0, 2500)
          : normalized;
      final candidates = await _languageIdentifier.identifyPossibleLanguages(
        sample,
      );

      final sorted = candidates.toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      debugPrint(
        'CV language candidates: ${sorted.map((l) => '${l.languageTag}:${l.confidence.toStringAsFixed(2)}').join(', ')}',
      );

      if (sorted.isNotEmpty && sorted.first.confidence >= 0.25) {
        return _fromCode(sorted.first.languageTag, sorted.first.confidence);
      }

      final langCode = await _languageIdentifier.identifyLanguage(sample);
      if (langCode == 'und') return _fallback(confidence: 0.0);

      return _fromCode(langCode, 0.5);
    } catch (e) {
      debugPrint('CV language detection error: $e');
      return _fallback(confidence: 0.0);
    }
  }

  static Future<List<DetectedLanguage>> detectAllLanguages(String text) async {
    final normalized = _normalizeForDetection(text);
    if (normalized.isEmpty) return [];

    try {
      final sample = normalized.length > 2500
          ? normalized.substring(0, 2500)
          : normalized;
      final languages = await _languageIdentifier.identifyPossibleLanguages(
        sample,
      );

      return languages
          .where((language) => language.confidence > 0.1)
          .map(
            (language) => _fromCode(
              language.languageTag,
              language.confidence,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('CV language multi-detection error: $e');
      return [];
    }
  }

  static void dispose() {
    _identifier?.close();
    _identifier = null;
  }

  static DetectedLanguage _fromCode(String code, double confidence) {
    return DetectedLanguage(
      code: code,
      name: _langNames[code] ?? code.toUpperCase(),
      flag: _langFlags[code] ?? '🌐',
      confidence: confidence,
    );
  }

  static DetectedLanguage _fallback({required double confidence}) {
    return DetectedLanguage(
      code: 'fr',
      name: _langNames['fr']!,
      flag: _langFlags['fr']!,
      confidence: confidence,
    );
  }

  static String _normalizeForDetection(String text) {
    return text
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'\S+@\S+'), ' ')
        .replaceAll(RegExp(r'\+?\d[\d\s().-]{6,}'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _preview(String text, {required int max}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }
}
