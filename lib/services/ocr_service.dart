// ============================================================
// ocr_service.dart
// Service OCR isolé — Firebase ML Kit Text Recognition
// Offline · Supporte latin, arabe, et texte mixte
// ============================================================

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // Instance unique (singleton)
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  // Recognizer réutilisable (évite de le recréer à chaque appel)
  TextRecognizer? _recognizer;

  // ─────────────────────────────────────────
  // EXTRACTION TEXTE BRUT
  // ─────────────────────────────────────────

  /// Extrait tout le texte d'une image (chemin fichier)
  /// Retourne le texte brut complet ou une chaîne vide si rien détecté
  Future<String> extractText(String imagePath) async {
    try {
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await _recognizer!.processImage(inputImage);

      return result.text.trim();
    } catch (e) {
      throw OcrException('Erreur OCR lors de l\'extraction : $e');
    }
  }

  /// Extrait le texte depuis un File directement
  Future<String> extractTextFromFile(File file) async {
    return extractText(file.path);
  }

  /// Extrait le texte et retourne aussi les blocs structurés (lignes, mots)
  Future<OcrResult> extractStructured(String imagePath) async {
    try {
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await _recognizer!.processImage(inputImage);

      // Construire les lignes propres
      final List<String> lines = [];
      final List<String> words = [];

      for (final block in result.blocks) {
        for (final line in block.lines) {
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            lines.add(lineText);
          }
          for (final element in line.elements) {
            final word = element.text.trim();
            if (word.isNotEmpty) words.add(word);
          }
        }
      }

      return OcrResult(
        rawText: result.text.trim(),
        lines: lines,
        words: words,
        blockCount: result.blocks.length,
        confidence: _estimateConfidence(result.text, lines),
      );
    } catch (e) {
      throw OcrException('Erreur OCR structurée : $e');
    }
  }

  // ─────────────────────────────────────────
  // VALIDATION IMAGE
  // ─────────────────────────────────────────

  /// Vérifie que le fichier image est valide avant traitement
  static bool isValidImage(String path) {
    final file = File(path);
    if (!file.existsSync()) return false;

    final ext = path.toLowerCase().split('.').last;
    const supported = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'heic'];
    return supported.contains(ext);
  }

  /// Retourne true si le texte extrait ressemble à un CV
  static bool looksLikeCv(String text) {
    if (text.length < 50) return false;

    final lower = text.toLowerCase();
    const cvKeywords = [
      'expérience',
      'experience',
      'formation',
      'education',
      'compétences',
      'skills',
      'email',
      'téléphone',
      'phone',
      'linkedin',
      'stage',
      'université',
      'university',
      'langues',
      'languages',
      'projets',
      'projects',
    ];

    int matches = 0;
    for (final kw in cvKeywords) {
      if (lower.contains(kw)) matches++;
    }
    return matches >= 2;
  }

  // ─────────────────────────────────────────
  // NETTOYAGE TEXTE OCR
  // ─────────────────────────────────────────

  /// Nettoie le texte brut OCR (artefacts, espaces doubles, etc.)
  static String cleanText(String rawText) {
    return rawText
        // Supprimer les caractères parasites courants OCR
        .replaceAll(RegExp(r'[|●•·▪▸►]'), ' ')
        // Réduire les espaces multiples
        .replaceAll(RegExp(r' {2,}'), ' ')
        // Réduire les sauts de ligne multiples (> 2)
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Supprimer les espaces en début/fin de ligne
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n')
        .trim();
  }

  // ─────────────────────────────────────────
  // SCORE DE CONFIANCE OCR
  // ─────────────────────────────────────────

  static double _estimateConfidence(String rawText, List<String> lines) {
    if (rawText.isEmpty) return 0.0;

    // Ratio lignes non vides / total caractères — heuristique simple
    final avgLineLength = lines.isEmpty
        ? 0.0
        : lines.fold<int>(0, (s, l) => s + l.length) / lines.length;

    // Texte trop court ou lignes très courtes = faible confiance
    if (rawText.length < 100) return 0.3;
    if (avgLineLength < 5) return 0.4;
    if (avgLineLength > 20) return 0.85;
    return 0.65;
  }

  // ─────────────────────────────────────────
  // LIBÉRATION RESSOURCES
  // ─────────────────────────────────────────

  /// À appeler quand l'OCR n'est plus nécessaire (ex: dispose du widget)
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

// ============================================================
// MODÈLES RÉSULTAT
// ============================================================

class OcrResult {
  final String rawText;
  final List<String> lines;
  final List<String> words;
  final int blockCount;
  final double confidence;

  OcrResult({
    required this.rawText,
    required this.lines,
    required this.words,
    required this.blockCount,
    required this.confidence,
  });

  bool get isEmpty => rawText.isEmpty;
  bool get isNotEmpty => rawText.isNotEmpty;

  /// Texte nettoyé prêt pour le parser
  String get cleanedText => OcrService.cleanText(rawText);
}

class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
