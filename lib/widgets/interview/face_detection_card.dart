import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/face_detection_service.dart';

class FaceDetectionStats {
  final int totalFrames;
  final int detectedFrames;

  const FaceDetectionStats({
    required this.totalFrames,
    required this.detectedFrames,
  });

  double get presenceRate {
    if (totalFrames == 0) return 0.0;
    return detectedFrames / totalFrames;
  }

  int get presencePercent => (presenceRate * 100).round();
}

class FaceDetectionCard extends StatefulWidget {
  final void Function(FaceDetectionStats stats)? onStatsChanged;

  const FaceDetectionCard({super.key, this.onStatsChanged});

  @override
  State<FaceDetectionCard> createState() => _FaceDetectionCardState();
}

class _FaceDetectionCardState extends State<FaceDetectionCard> {
  final FaceDetectionService _service = FaceDetectionService();

  CameraController? _controller;
  CameraDescription? _frontCamera;

  bool _initializing = true;
  bool _cameraError = false;
  bool _processingFrame = false;

  InterviewFaceResult _lastResult = InterviewFaceResult.noFace();

  int _totalFrames = 0;
  int _validFrames = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    _service.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Aucune caméra trouvée');
      }

      _frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final imageFormatGroup = Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888;

      final controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await controller.initialize();

      _controller = controller;

      if (!mounted) return;

      setState(() {
        _initializing = false;
        _cameraError = false;
      });

      await controller.startImageStream(_handleCameraImage);
    } catch (e) {
      debugPrint('Camera init error: $e');

      if (!mounted) return;

      setState(() {
        _initializing = false;
        _cameraError = true;
      });
    }
  }

  Future<void> _handleCameraImage(CameraImage image) async {
    if (_processingFrame || _frontCamera == null) return;

    _processingFrame = true;

    try {
      final result = await _service.detectFromCameraImage(
        image: image,
        camera: _frontCamera!,
      );

      _totalFrames++;

      // Important :
      // On compte seulement les frames où le visage est vraiment valide.
      if (result.isValid) {
        _validFrames++;
      }

      widget.onStatsChanged?.call(
        FaceDetectionStats(
          totalFrames: _totalFrames,
          detectedFrames: _validFrames,
        ),
      );

      if (mounted && _totalFrames % 5 == 0) {
        setState(() {
          _lastResult = result;
        });
      }
    } catch (e) {
      debugPrint('Face stream error: $e');
    } finally {
      _processingFrame = false;
    }
  }

  Widget _buildFullCameraPreview(BuildContext context) {
    final controller = _controller!;

    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_cameraError ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Caméra indisponible.\nVérifiez la permission caméra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final presence = _totalFrames == 0
        ? 0
        : ((_validFrames / _totalFrames) * 100).round();

    final Color color;
    final IconData icon;
    final String title;

    if (_lastResult.status == 'valid') {
      color = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
      title = 'Visage bien visible';
    } else if (_lastResult.status == 'partial') {
      color = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      title = 'Visage partiellement visible';
    } else if (_lastResult.status == 'multiple') {
      color = const Color(0xFFF59E0B);
      icon = Icons.groups_rounded;
      title = 'Plusieurs visages';
    } else {
      color = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
      title = 'Visage absent';
    }

    return Stack(
      children: [
        Positioned.fill(child: _buildFullCameraPreview(context)),

        Positioned(
          left: 16,
          right: 16,
          top: 250,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$title · $presence%\n${_lastResult.feedback}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
