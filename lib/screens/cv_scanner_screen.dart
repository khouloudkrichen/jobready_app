import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/candidate_profile.dart';
import '../services/app_localizations.dart';
import '../services/cv_profile_builder.dart';
import '../services/firebase_service.dart';
import '../services/language_detection_service.dart';
import '../services/ocr_service.dart';
import '../widgets/app_design.dart';

class CvScannerScreen extends StatefulWidget {
  const CvScannerScreen({super.key});

  @override
  State<CvScannerScreen> createState() => _CvScannerScreenState();
}

class _CvScannerScreenState extends State<CvScannerScreen> {
  File? _image;
  bool _processing = false;
  int _step = 0;
  String _detectedLang = '';

  @override
  void dispose() {
    LanguageDetectionService.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 92,
    );
    if (file == null) return;
    setState(() {
      _image = File(file.path);
      _detectedLang = '';
    });
  }

  Future<void> _run() async {
    final image = _image;
    if (image == null) return;

    final l = AppLocalizations.of(context);
    setState(() {
      _processing = true;
      _step = 1;
      _detectedLang = '';
    });

    try {
      final ocr = await OcrService().extractStructured(image.path);
      if (ocr.isEmpty) {
        _showError(l.t('Aucun texte détecté.', 'No text detected.'));
        return;
      }

      debugPrint(
        'CV OCR extracted text: ${_logPreview(ocr.cleanedText, max: 1200)}',
      );

      setState(() => _step = 2);
      final detectedLanguage = await LanguageDetectionService.detectLanguage(
        ocr.cleanedText,
      );
      setState(() => _detectedLang = detectedLanguage.displayName);
      debugPrint(
        'CV detected language: ${detectedLanguage.code} '
        '${detectedLanguage.name} '
        'confidence=${detectedLanguage.confidence.toStringAsFixed(2)}',
      );
      debugPrint(
        'CV feedback language: ${detectedLanguage.name} '
        '(${detectedLanguage.code})',
      );

      setState(() => _step = 3);
      final CandidateProfile profile = await CvProfileBuilder.buildAsync(
        ocr.cleanedText,
        detectedCvLanguage: detectedLanguage.name,
      );

      try {
        await FirebaseService.saveProfile(profile);
      } catch (_) {
        // Le profil reste utilisable localement si la sauvegarde échoue.
      }

      setState(() => _step = 4);
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/cv-result', arguments: profile);
    } catch (e) {
      _showError('${l.t('Erreur', 'Error')} : $e');
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _step = 0;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _step = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'JobReady',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppDesign.bg,
        elevation: 0,
        foregroundColor: AppDesign.ink,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Text(
              l.t('Scanner le CV', 'Scan the CV'),
              style: const TextStyle(
                color: AppDesign.ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.t(
                'Importe ton CV pour générer automatiquement ton profil.',
                'Import your CV to generate your profile automatically.',
              ),
              style: const TextStyle(
                color: AppDesign.muted,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (_processing)
              _ProcessingCard(step: _step, detectedLang: _detectedLang)
            else if (_image == null)
              _PickPanel(
                onGallery: () => _pick(ImageSource.gallery),
                onCamera: () => _pick(ImageSource.camera),
              )
            else
              _PreviewPanel(
                image: _image!,
                onChange: () => setState(() => _image = null),
                onAnalyze: _run,
              ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  IconBadge(icon: Icons.info_outline_rounded, size: 34),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le texte du CV sera extrait automatiquement. L’analyse fournit un profil structuré et des conseils d’amélioration.',
                      style: TextStyle(
                        color: AppDesign.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _logPreview(String text, {required int max}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}

class _PickPanel extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _PickPanel({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: AppDesign.gradient,
              shape: BoxShape.circle,
              boxShadow: [AppDesign.softShadow(opacity: 0.12)],
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Déposer le fichier',
            style: TextStyle(
              color: AppDesign.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Image claire du CV recommandée',
            style: TextStyle(
              color: AppDesign.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: l.t('Importer depuis la galerie', 'Import from gallery'),
            icon: Icons.photo_library_outlined,
            onPressed: onGallery,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l.t('Prendre une photo', 'Take a photo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppDesign.navy,
                side: const BorderSide(color: AppDesign.navy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final File image;
  final VoidCallback onChange;
  final VoidCallback onAnalyze;

  const _PreviewPanel({
    required this.image,
    required this.onChange,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              image,
              width: double.infinity,
              height: 340,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GradientButton(
          label: l.t(
            'Créer le profil automatiquement',
            'Create profile automatically',
          ),
          icon: Icons.auto_awesome_rounded,
          onPressed: onAnalyze,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l.t('Choisir une autre image', 'Choose another image')),
        ),
      ],
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  final int step;
  final String detectedLang;

  const _ProcessingCard({required this.step, required this.detectedLang});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [
      '',
      l.t('Extraction du texte...', 'Extracting text...'),
      l.t('Détection de la langue...', 'Detecting language...'),
      l.t('Analyse IA en cours...', 'AI analysis in progress...'),
      l.t('Profil créé.', 'Profile created.'),
    ];
    final current = step.clamp(0, labels.length - 1);

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 18),
          Text(
            labels[current],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (detectedLang.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(detectedLang, style: const TextStyle(color: AppDesign.muted)),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: current / (labels.length - 1),
              minHeight: 5,
              backgroundColor: const Color(0xFFE5EAF3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.violet),
            ),
          ),
        ],
      ),
    );
  }
}
