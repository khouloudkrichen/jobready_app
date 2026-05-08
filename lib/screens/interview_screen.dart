// ============================================================
// interview_screen.dart
// Écran complet de simulation d'entretien
// - Caméra plein écran
// - Questions générées selon le profil + niveau
// - Réponse orale : cliquer micro pour commencer, cliquer encore pour terminer
// - TTS : écouter la question
// - ML Kit Face Detection : présence caméra simple
// - Rapport final avec pénalité si peu de réponses
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/candidate_profile.dart';
import '../services/interview_question_service.dart';
import '../services/speech_answer_service.dart';
import '../widgets/app_design.dart';

class InterviewScreen extends StatefulWidget {
  final CandidateProfile profile;
  final InterviewDifficulty difficulty;

  const InterviewScreen({
    super.key,
    required this.profile,
    this.difficulty = InterviewDifficulty.beginner,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with WidgetsBindingObserver {
  static const Color _primary = Color(0xFF183B63);
  static const Color _purple = Color(0xFF6D5DFB);
  static const int _maxQuestions = 10;

  final FlutterTts _tts = FlutterTts();
  final SpeechAnswerService _speechService = SpeechAnswerService();

  late final FaceDetector _faceDetector;
  CameraController? _cameraController;

  List<InterviewQuestion> _questions = [];
  List<String> _answers = [];

  int _currentQuestionIndex = 0;

  bool _cameraReady = false;
  bool _processingFrame = false;
  bool _isListening = false;
  bool _isFinished = false;
  bool _speechReady = false;

  String _currentAnswer = '';
  String _microStatus = 'Micro prêt';

  int _totalFrames = 0;
  int _visibleFaceFrames = 0;
  _FaceSignal _faceSignal = _FaceSignal.noCamera();

  DateTime _lastFaceAnalyze = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _restartSpeechTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: false,
        minFaceSize: 0.15,
      ),
    );

    _questions = InterviewQuestionService.generateQuestions(
      widget.profile,
      difficulty: widget.difficulty,
    ).take(_maxQuestions).toList();

    if (_questions.isEmpty) {
      _questions = [
        const InterviewQuestion(
          question: 'Présentez-vous brièvement.',
          category: 'Général',
        ),
      ];
    }

    _answers = List<String>.filled(_questions.length, '');

    _initTts();
    _initSpeech();
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _restartSpeechTimer?.cancel();

    _isListening = false;
    _speechService.cancelListening();

    _tts.stop();
    _faceDetector.close();

    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();

    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.stopImageStream().catchError((_) {});
    } else if (state == AppLifecycleState.resumed && !_isFinished) {
      _restartCameraStream();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_ttsLanguage());
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speechService.initialize(
      onStatus: (status) {
        if (!mounted) return;

        debugPrint('Speech status from screen: $status');

        // Si speech_to_text s'arrête tout seul pendant que le candidat
        // est encore en mode "micro actif", on relance l'écoute.
        if (_isListening &&
            (status == 'done' ||
                status == 'notListening' ||
                status == 'not_listening')) {
          _restartSpeechTimer?.cancel();
          _restartSpeechTimer = Timer(const Duration(milliseconds: 400), () {
            if (mounted && _isListening) {
              _startListening(restart: true);
            }
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _microStatus = 'Erreur micro : $error';
        });

        if (_isListening) {
          _restartSpeechTimer?.cancel();
          _restartSpeechTimer = Timer(const Duration(milliseconds: 700), () {
            if (mounted && _isListening) {
              _startListening(restart: true);
            }
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _microStatus = _speechReady ? 'Micro prêt' : 'Micro indisponible';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _faceSignal = _FaceSignal.noCamera();
          _cameraReady = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _cameraReady = true;
      });

      await _restartCameraStream();
    } catch (e) {
      debugPrint('Camera init error: $e');

      if (!mounted) return;
      setState(() {
        _cameraReady = false;
        _faceSignal = _FaceSignal.noCamera();
      });
    }
  }

  Future<void> _restartCameraStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Camera stream error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingFrame || _isFinished) return;

    final now = DateTime.now();

    // On analyse environ 2 frames par seconde pour éviter de ralentir l'app.
    if (now.difference(_lastFaceAnalyze).inMilliseconds < 500) return;

    _lastFaceAnalyze = now;
    _processingFrame = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _processingFrame = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      final signal = _analyzeFaces(faces, image.width, image.height);

      _totalFrames++;
      if (signal.visible) {
        _visibleFaceFrames++;
      }

      if (mounted) {
        setState(() {
          _faceSignal = signal;
        });
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final camera = controller.description;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = _concatenatePlanes(image.planes);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();

    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return allBytes.done().buffer.asUint8List();
  }

  _FaceSignal _analyzeFaces(List<Face> faces, int imageWidth, int imageHeight) {
    if (faces.isEmpty) {
      return _FaceSignal(
        visible: false,
        score: 0,
        title: 'Visage absent',
        message: 'Aucun visage détecté. Placez-vous face à la caméra.',
        color: const Color(0xFFEF4444),
        icon: Icons.close_rounded,
      );
    }

    if (faces.length > 1) {
      return _FaceSignal(
        visible: false,
        score: 25,
        title: 'Plusieurs visages',
        message: 'Restez seul face à la caméra.',
        color: const Color(0xFFF59E0B),
        icon: Icons.groups_rounded,
      );
    }

    final face = faces.first;
    final box = face.boundingBox;

    final imageArea = max(1.0, imageWidth * imageHeight.toDouble());
    final faceArea = max(0.0, box.width * box.height);
    final areaRatio = faceArea / imageArea;

    final centerX = box.center.dx / max(1, imageWidth);
    final centerY = box.center.dy / max(1, imageHeight);

    final centered =
        centerX > 0.20 && centerX < 0.80 && centerY > 0.16 && centerY < 0.86;

    final goodSize = areaRatio > 0.055;

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;

    final eyesAvailable = leftEye != null && rightEye != null;
    final eyesOpen = !eyesAvailable || (leftEye > 0.25 && rightEye > 0.25);

    final noseVisible =
        face.landmarks[FaceLandmarkType.noseBase]?.position != null;

    final mouthVisible =
        face.landmarks[FaceLandmarkType.bottomMouth]?.position != null ||
        face.landmarks[FaceLandmarkType.leftMouth]?.position != null ||
        face.landmarks[FaceLandmarkType.rightMouth]?.position != null;

    // Pour éviter le problème : téléphone devant le visage mais statut vert.
    // On demande au minimum yeux + nez + bouche visibles quand ML Kit les fournit.
    final lowerFaceSeemsVisible = noseVisible && mouthVisible;

    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    final headStraight = yaw < 25 && roll < 25;

    int score = 0;
    if (centered) score += 20;
    if (goodSize) score += 20;
    if (eyesOpen) score += 20;
    if (lowerFaceSeemsVisible) score += 25;
    if (headStraight) score += 15;

    score = score.clamp(0, 100);

    if (!centered || !goodSize) {
      return _FaceSignal(
        visible: false,
        score: score.toDouble(),
        title: 'Visage mal cadré',
        message: 'Centrez votre visage et rapprochez-vous légèrement.',
        color: const Color(0xFFF59E0B),
        icon: Icons.center_focus_strong_rounded,
      );
    }

    if (!lowerFaceSeemsVisible) {
      return _FaceSignal(
        visible: false,
        score: score.toDouble(),
        title: 'Visage partiellement visible',
        message: 'Votre visage semble partiellement caché.',
        color: const Color(0xFFF59E0B),
        icon: Icons.visibility_off_rounded,
      );
    }

    if (!eyesOpen) {
      return _FaceSignal(
        visible: false,
        score: score.toDouble(),
        title: 'Yeux peu visibles',
        message: 'Gardez les yeux visibles face à la caméra.',
        color: const Color(0xFFF59E0B),
        icon: Icons.remove_red_eye_rounded,
      );
    }

    if (!headStraight) {
      return _FaceSignal(
        visible: true,
        score: score.toDouble(),
        title: 'Visage détecté',
        message: 'Gardez la tête plus stable face à la caméra.',
        color: const Color(0xFFF59E0B),
        icon: Icons.face_rounded,
      );
    }

    return _FaceSignal(
      visible: true,
      score: score.toDouble(),
      title: 'Visage bien visible',
      message: 'Votre visage est bien visible.',
      color: const Color(0xFF10B981),
      icon: Icons.check_rounded,
    );
  }

  String _speechLocale() {
    final language = InterviewQuestionService.detectInterviewLanguage(
      widget.profile,
    );

    switch (language) {
      case InterviewLanguage.english:
        return 'en_US';
      case InterviewLanguage.spanish:
        return 'es_ES';
      case InterviewLanguage.german:
        return 'de_DE';
      case InterviewLanguage.french:
        return 'fr_FR';
    }
  }

  String _ttsLanguage() {
    final language = InterviewQuestionService.detectInterviewLanguage(
      widget.profile,
    );

    switch (language) {
      case InterviewLanguage.english:
        return 'en-US';
      case InterviewLanguage.spanish:
        return 'es-ES';
      case InterviewLanguage.german:
        return 'de-DE';
      case InterviewLanguage.french:
        return 'fr-FR';
    }
  }

  Future<void> _speakQuestion() async {
    if (_questions.isEmpty) return;

    await _tts.stop();
    await _tts.setLanguage(_ttsLanguage());
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_questions[_currentQuestionIndex].question);
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _stopListeningManually();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening({bool restart = false}) async {
    if (!_speechReady && !restart) {
      await _initSpeech();
    }

    if (!_speechReady && !restart) {
      if (!mounted) return;
      setState(() {
        _microStatus = 'Micro indisponible';
      });
      return;
    }

    if (!restart) {
      _currentAnswer = _answers[_currentQuestionIndex];
    }

    if (!mounted) return;

    setState(() {
      _isListening = true;
      _microStatus = 'Écoute en cours';
    });

    final started = await _speechService.startListening(
      localeId: _speechLocale(),
      onText: (text, isFinal) {
        if (!mounted) return;

        setState(() {
          _currentAnswer = text.trim();
          _answers[_currentQuestionIndex] = _currentAnswer;
        });
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
        _microStatus = 'Impossible de démarrer le micro';
      });
    }
  }

  Future<void> _stopListeningManually() async {
    _restartSpeechTimer?.cancel();

    setState(() {
      _isListening = false;
      _microStatus = 'Réponse enregistrée';
    });

    await _speechService.stopListening();

    final answer = _currentAnswer.trim();
    _answers[_currentQuestionIndex] = answer;
  }

  Future<void> _nextQuestion({bool skip = false}) async {
    if (_isListening) {
      await _stopListeningManually();
    }

    await _tts.stop();

    if (skip) {
      _answers[_currentQuestionIndex] = '';
      _currentAnswer = '';
    } else {
      _answers[_currentQuestionIndex] = _currentAnswer.trim();
    }

    if (_currentQuestionIndex >= _questions.length - 1) {
      await _finishInterview();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _currentAnswer = _answers[_currentQuestionIndex];
      _microStatus = 'Micro prêt';
    });
  }

  Future<void> _finishInterview() async {
    if (_isFinished) return;

    await _tts.stop();

    setState(() {
      _isFinished = true;
      _isListening = false;
    });

    await _speechService.stopListening();
    await _cameraController?.stopImageStream().catchError((_) {});
  }

  Future<void> _restartInterview() async {
    await _tts.stop();
    await _speechService.cancelListening();

    setState(() {
      _questions = InterviewQuestionService.generateQuestions(
        widget.profile,
        difficulty: widget.difficulty,
      ).take(_maxQuestions).toList();

      if (_questions.isEmpty) {
        _questions = [
          const InterviewQuestion(
            question: 'Présentez-vous brièvement.',
            category: 'Général',
          ),
        ];
      }

      _answers = List<String>.filled(_questions.length, '');
      _currentQuestionIndex = 0;
      _currentAnswer = '';
      _microStatus = 'Micro prêt';
      _isListening = false;
      _isFinished = false;
      _totalFrames = 0;
      _visibleFaceFrames = 0;
      _faceSignal = _FaceSignal.noCamera();
    });

    await _restartCameraStream();
  }

  double get _cameraPresencePercent {
    if (_totalFrames <= 0) return 0;
    return (_visibleFaceFrames / _totalFrames * 100).clamp(0, 100);
  }

  InterviewQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _FinishedView(
        difficulty: widget.difficulty,
        questions: _questions,
        answers: _answers,
        cameraPresencePercent: _cameraPresencePercent,
        onBackToProfile: () => Navigator.pop(context),
        onRestart: _restartInterview,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraBackground()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.52),
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.72),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                _buildQuestionCard(),
                const SizedBox(height: 8),
                _buildFaceStatus(),
                const Spacer(),
                _buildMicroStatus(),
                const SizedBox(height: 10),
                _buildBottomControls(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    final controller = _cameraController;

    if (!_cameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF111827),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Center(
      child: Transform.scale(
        scale: _cameraScale(controller),
        child: CameraPreview(controller),
      ),
    );
  }

  double _cameraScale(CameraController controller) {
    final screen = MediaQuery.of(context).size;
    final preview = controller.value.previewSize;

    if (preview == null) return 1;

    final previewRatio = preview.height / preview.width;
    final screenRatio = screen.width / screen.height;

    return max(1.0, previewRatio / screenRatio);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () async {
              await _tts.stop();
              if (mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entretien en cours',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Niveau ${widget.difficulty.label}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _ProgressBadge(
            current: _currentQuestionIndex + 1,
            total: _questions.length,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.difficulty.label,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _currentQuestion.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Question complète',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  onPressed: _showFullQuestion,
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _currentQuestion.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: _speakQuestion,
                    icon: const Icon(Icons.volume_up_rounded, size: 15),
                    label: const Text('Écouter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: BorderSide(color: _primary.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullQuestion() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Question ${_currentQuestionIndex + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion.question,
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _speakQuestion,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Écouter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceStatus() {
    final signal = _faceSignal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.52),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: signal.color.withOpacity(0.75)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: signal.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(signal.icon, color: signal.color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${signal.title} · ${signal.score.round()}%',
                    style: TextStyle(
                      color: signal.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    signal.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMicroStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _isListening
              ? _purple.withOpacity(0.9)
              : Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isListening ? 'Cliquez pour terminer' : _microStatus,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final hasAnswer = _isRealInterviewAnswer(_currentAnswer);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SmallActionButton(
            icon: Icons.volume_up_rounded,
            label: 'Question',
            onTap: _speakQuestion,
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _isListening ? 86 : 78,
              height: _isListening ? 86 : 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                      : [_purple, const Color(0xFF3B82F6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : _purple).withOpacity(
                      0.42,
                    ),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.75),
                  width: 3,
                ),
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: _isListening ? 42 : 36,
              ),
            ),
          ),
          const Spacer(),
          _SmallActionButton(
            icon: hasAnswer
                ? Icons.arrow_forward_rounded
                : Icons.skip_next_rounded,
            label: hasAnswer ? 'Suivante' : 'Passer',
            onTap: () => _nextQuestion(skip: !hasAnswer),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Rapport final
// ============================================================

class _FinishedView extends StatelessWidget {
  final InterviewDifficulty difficulty;
  final List<InterviewQuestion> questions;
  final List<String> answers;
  final double cameraPresencePercent;
  final VoidCallback onBackToProfile;
  final VoidCallback onRestart;

  const _FinishedView({
    required this.difficulty,
    required this.questions,
    required this.answers,
    required this.cameraPresencePercent,
    required this.onBackToProfile,
    required this.onRestart,
  });

  static const Color _primary = Color(0xFF183B63);

  @override
  Widget build(BuildContext context) {
    final report = _buildReport();
    final globalScore = report.realAnswers == 0
        ? 0
        : (((report.hardSkills + report.communication + report.structure) /
                          30) *
                      70 +
                  (cameraPresencePercent / 100) * 30)
              .round()
              .clamp(0, 100)
              .toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(
          'Simulation entretien · ${difficulty.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        foregroundColor: _primary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF10B981),
                  size: 74,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Rapport d’entretien',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Niveau ${difficulty.label}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${report.realAnswers} réponse(s) réelle(s) sur ${questions.length} questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.45),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report.realAnswers < 3) ...[
              const SizedBox(height: 12),
              const _LimitedEvaluationBanner(),
            ],
            const SizedBox(height: 18),
            _GlobalInterviewScoreCard(
              score: globalScore,
              realAnswers: report.realAnswers,
              totalQuestions: questions.length,
            ),
            const SizedBox(height: 14),
            _ScoreCard(
              icon: Icons.psychology_rounded,
              title: 'Hard skills',
              score: report.hardSkills,
              subtitle:
                  'Évalue la capacité à expliquer les compétences et expériences techniques.',
              scoreText: '${report.hardSkills}/10',
              color: const Color(0xFF8B5CF6),
            ),
            _ScoreCard(
              icon: Icons.record_voice_over_rounded,
              title: 'Communication',
              score: report.communication,
              subtitle: 'Évalue la clarté et la fluidité des réponses.',
              scoreText: '${report.communication}/10',
              color: const Color(0xFF3B82F6),
            ),
            _ScoreCard(
              icon: Icons.account_tree_rounded,
              title: 'Structure',
              score: report.structure,
              subtitle:
                  'Évalue l’organisation des idées et la logique des réponses.',
              scoreText: '${report.structure}/10',
              color: const Color(0xFFF59E0B),
            ),
            _ScoreCard(
              icon: Icons.videocam_rounded,
              title: 'Présence caméra',
              score: (cameraPresencePercent / 10).round().clamp(0, 10).toInt(),
              subtitle:
                  'Évalue la visibilité du visage et la stabilité face à la caméra. ${report.cameraFeedback}',
              scoreText: '${cameraPresencePercent.round()}%',
              color: cameraPresencePercent >= 60
                  ? const Color(0xFF10B981)
                  : cameraPresencePercent >= 30
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            _InfoBox(
              icon: Icons.auto_awesome_rounded,
              title: 'Feedback global',
              color: const Color(0xFF10B981),
              items: [report.globalFeedback],
            ),
            _InfoBox(
              icon: Icons.check_circle_outline_rounded,
              title: 'Points forts',
              color: const Color(0xFF10B981),
              items: report.strengths,
            ),
            _InfoBox(
              icon: Icons.trending_up_rounded,
              title: 'Points à améliorer',
              color: const Color(0xFFF59E0B),
              items: report.improvements,
            ),
            _InfoBox(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Conseils',
              color: const Color(0xFF6366F1),
              items: report.tips,
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Retour au profil',
              icon: Icons.arrow_back_rounded,
              onPressed: onBackToProfile,
              height: 58,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recommencer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppDesign.violet,
                side: BorderSide(color: AppDesign.violet.withOpacity(0.55)),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _InterviewReport _buildReport() {
    final realAnswers = answers.where(_isRealInterviewAnswer).length;
    final noRealAnswers = realAnswers == 0;

    final words = answers
        .where(_isRealInterviewAnswer)
        .map(_wordCount)
        .toList();

    final avgWords = words.isEmpty
        ? 0
        : (words.reduce((a, b) => a + b) / words.length).round();

    int hard = noRealAnswers ? 0 : _baseHardSkillsScore(avgWords);
    int communication = noRealAnswers ? 0 : _baseCommunicationScore(avgWords);
    int structure = noRealAnswers ? 0 : _baseStructureScore();

    hard = _scoreWithAnswerPenalty(
      originalScore: hard,
      realAnswers: realAnswers,
      totalQuestions: questions.length,
    );

    communication = _scoreWithAnswerPenalty(
      originalScore: communication,
      realAnswers: realAnswers,
      totalQuestions: questions.length,
    );

    structure = _scoreWithAnswerPenalty(
      originalScore: structure,
      realAnswers: realAnswers,
      totalQuestions: questions.length,
    );

    final cameraFeedback = cameraPresencePercent >= 60
        ? 'Bonne présence caméra.'
        : cameraPresencePercent >= 30
        ? 'Présence caméra moyenne. Essayez de rester plus stable face à la caméra.'
        : 'Présence caméra faible. Le visage était souvent absent ou hors cadre.';

    final globalFeedback = noRealAnswers
        ? "Le candidat n'a fourni aucune réponse exploitable. L'entretien ne permet donc pas d'évaluer ses compétences."
        : realAnswers < 3
        ? "Le candidat a répondu à très peu de questions. L’évaluation reste limitée. Pour obtenir une note plus fiable, il doit répondre à davantage de questions avec des exemples concrets."
        : "Le candidat possède une base intéressante. Pour progresser, les réponses doivent être plus détaillées, mieux structurées et appuyées par des exemples réels.";

    final strengths = noRealAnswers
        ? ['Aucun point fort détecté car aucune réponse exploitable.']
        : [
            if (hard >= 5)
              'Compétences techniques présentes dans les réponses'
            else
              'Début de réponse technique détecté',
            if (realAnswers >= 5)
              'Participation régulière aux questions'
            else
              'Quelques réponses exploitables',
          ];

    final improvements = noRealAnswers
        ? [
            'Répondre oralement aux questions au lieu de les passer',
            'Donner des exemples liés au CV',
          ]
        : [
            'Développer davantage les réponses avec des détails concrets',
            'Structurer les réponses avec contexte, action et résultat',
            if (cameraPresencePercent < 50)
              'Rester plus stable et bien cadré face à la caméra',
          ];

    final tips = [
      'Préparer une présentation personnelle courte et claire',
      'Utiliser la méthode : contexte, action réalisée, résultat obtenu',
      'Donner au moins un exemple concret pour chaque expérience ou projet',
    ];

    return _InterviewReport(
      realAnswers: realAnswers,
      hardSkills: hard,
      communication: communication,
      structure: structure,
      cameraFeedback: cameraFeedback,
      globalFeedback: globalFeedback,
      strengths: strengths,
      improvements: improvements,
      tips: tips,
    );
  }

  int _baseHardSkillsScore(int avgWords) {
    final technicalCategories = {
      'Compétence',
      'Skill',
      'Tecnología',
      'Technologie',
      'Technology',
      'Projet',
      'Project',
      'Proyecto',
      'Problem solving',
      'Résolution problème',
    };

    int technicalAnswered = 0;

    for (var i = 0; i < questions.length; i++) {
      final category = questions[i].category;
      if (technicalCategories.contains(category) &&
          i < answers.length &&
          _isRealInterviewAnswer(answers[i])) {
        technicalAnswered++;
      }
    }

    int score = 3;

    if (technicalAnswered >= 1) score += 2;
    if (technicalAnswered >= 2) score += 2;
    if (avgWords >= 30) score += 1;
    if (avgWords >= 55) score += 1;

    return score.clamp(0, 10);
  }

  int _baseCommunicationScore(int avgWords) {
    if (avgWords < 5) return 1;
    if (avgWords < 15) return 3;
    if (avgWords < 30) return 5;
    if (avgWords < 55) return 7;
    return 8;
  }

  int _baseStructureScore() {
    final structureWords = [
      'd’abord',
      'ensuite',
      'après',
      'finalement',
      'contexte',
      'action',
      'résultat',
      'first',
      'then',
      'after',
      'finally',
      'result',
      'primero',
      'después',
      'resultado',
      'zuerst',
      'danach',
      'ergebnis',
    ];

    final joined = answers.join(' ').toLowerCase();
    final hits = structureWords.where((w) => joined.contains(w)).length;

    if (hits >= 4) return 8;
    if (hits >= 2) return 6;
    if (hits >= 1) return 4;
    return 3;
  }

  int _scoreWithAnswerPenalty({
    required int originalScore,
    required int realAnswers,
    required int totalQuestions,
  }) {
    if (realAnswers <= 0) return 0;
    if (realAnswers == 1) return originalScore.clamp(0, 2);
    if (realAnswers == 2) return originalScore.clamp(0, 3);
    if (realAnswers <= 4) return originalScore.clamp(0, 5);
    if (realAnswers <= 6) return originalScore.clamp(0, 7);
    return originalScore.clamp(0, 10);
  }
}

// ============================================================
// Widgets UI
// ============================================================

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF183B63), size: 20),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.34)),
      ),
      child: Center(
        child: Text(
          '$current/$total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.52),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minWidth: 98),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int score;
  final String scoreText;
  final Color color;

  const _ScoreCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.score,
    required this.scoreText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                scoreText,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score.clamp(0, 10).toDouble() / 10,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalInterviewScoreCard extends StatelessWidget {
  final int score;
  final int realAnswers;
  final int totalQuestions;

  const _GlobalInterviewScoreCard({
    required this.score,
    required this.realAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppDesign.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppDesign.softShadow(opacity: 0.16)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score entretien',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$realAnswers réponse(s) réelle(s) sur $totalQuestions questions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 55) return const Color(0xFFA78BFA);
    if (score >= 35) return const Color(0xFFF59E0B);
    return const Color(0xFFFCA5A5);
  }
}

class _LimitedEvaluationBanner extends StatelessWidget {
  const _LimitedEvaluationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'L’évaluation est limitée car le candidat a répondu à peu de questions.',
              style: TextStyle(
                color: Color(0xFF92400E),
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.68),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Models internes
// ============================================================

class _FaceSignal {
  final bool visible;
  final double score;
  final String title;
  final String message;
  final Color color;
  final IconData icon;

  const _FaceSignal({
    required this.visible,
    required this.score,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  factory _FaceSignal.noCamera() {
    return const _FaceSignal(
      visible: false,
      score: 0,
      title: 'Caméra',
      message: 'Initialisation de la caméra...',
      color: Color(0xFFF59E0B),
      icon: Icons.videocam_rounded,
    );
  }
}

class _InterviewReport {
  final int realAnswers;
  final int hardSkills;
  final int communication;
  final int structure;
  final String cameraFeedback;
  final String globalFeedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> tips;

  const _InterviewReport({
    required this.realAnswers,
    required this.hardSkills,
    required this.communication,
    required this.structure,
    required this.cameraFeedback,
    required this.globalFeedback,
    required this.strengths,
    required this.improvements,
    required this.tips,
  });
}

// ============================================================
// Helpers
// ============================================================

bool _isRealInterviewAnswer(String answer) {
  final clean = answer.trim().toLowerCase();

  if (clean.isEmpty) return false;

  final badAnswers = {
    'skip',
    'passer',
    'suivant',
    'suivante',
    'next',
    'no',
    'non',
    'nothing',
    'rien',
    'aucune réponse',
    'error_no_match',
  };

  if (badAnswers.contains(clean)) return false;

  final words = clean
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().length > 1)
      .toList();

  return words.length >= 3;
}

int _wordCount(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .length;
}
