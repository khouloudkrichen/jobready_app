import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class InterviewFaceResult {
  final bool hasFace;
  final bool isValid;
  final bool faceDetected;
  final int faceCount;
  final double score;
  final String status;
  final String feedback;

  const InterviewFaceResult({
    required this.hasFace,
    required this.isValid,
    required this.faceDetected,
    required this.faceCount,
    required this.score,
    required this.status,
    required this.feedback,
  });

  factory InterviewFaceResult.noFace() {
    return const InterviewFaceResult(
      hasFace: false,
      isValid: false,
      faceDetected: false,
      faceCount: 0,
      score: 0,
      status: 'absent',
      feedback: 'Aucun visage détecté. Placez-vous face à la caméra.',
    );
  }

  factory InterviewFaceResult.multipleFaces(int count) {
    return InterviewFaceResult(
      hasFace: true,
      isValid: false,
      faceDetected: false,
      faceCount: count,
      score: 20,
      status: 'multiple',
      feedback: 'Plusieurs visages détectés. Restez seul face à la caméra.',
    );
  }
}

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableTracking: true,
      enableLandmarks: true,
      enableContours: false,
      minFaceSize: 0.18,
    ),
  );

  int _validStreak = 0;

  Future<InterviewFaceResult> detectFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
    try {
      final inputImage = _toInputImage(image: image, camera: camera);

      if (inputImage == null) {
        _validStreak = 0;
        return InterviewFaceResult.noFace();
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _validStreak = 0;
        return InterviewFaceResult.noFace();
      }

      if (faces.length > 1) {
        _validStreak = 0;
        return InterviewFaceResult.multipleFaces(faces.length);
      }

      return _analyzeSingleFace(
        face: faces.first,
        imageWidth: image.width.toDouble(),
        imageHeight: image.height.toDouble(),
      );
    } catch (e) {
      debugPrint('Face detection error: $e');
      _validStreak = 0;
      return InterviewFaceResult.noFace();
    }
  }

  InterviewFaceResult _analyzeSingleFace({
    required Face face,
    required double imageWidth,
    required double imageHeight,
  }) {
    final box = face.boundingBox;

    if (imageWidth <= 0 || imageHeight <= 0) {
      _validStreak = 0;
      return const InterviewFaceResult(
        hasFace: true,
        isValid: false,
        faceDetected: false,
        faceCount: 1,
        score: 0,
        status: 'partial',
        feedback: 'Image caméra invalide.',
      );
    }

    final widthRatio = box.width / imageWidth;
    final heightRatio = box.height / imageHeight;
    final areaRatio = (box.width * box.height) / (imageWidth * imageHeight);

    final faceCenterX = box.left + box.width / 2;
    final faceCenterY = box.top + box.height / 2;

    final imageCenterX = imageWidth / 2;
    final imageCenterY = imageHeight / 2;

    final dx = (faceCenterX - imageCenterX).abs() / imageWidth;
    final dy = (faceCenterY - imageCenterY).abs() / imageHeight;

    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;

    double score = 0;

    if (heightRatio >= 0.22) {
      score += 25;
    } else if (heightRatio >= 0.16) {
      score += 12;
    }

    if (areaRatio >= 0.08) {
      score += 20;
    } else if (areaRatio >= 0.05) {
      score += 10;
    }

    if (dx <= 0.18 && dy <= 0.22) {
      score += 20;
    } else if (dx <= 0.26 && dy <= 0.30) {
      score += 10;
    }

    if (yaw <= 18 && roll <= 18) {
      score += 20;
    } else if (yaw <= 25 && roll <= 25) {
      score += 10;
    }

    bool eyesOk = true;

    if (leftEye != null && rightEye != null) {
      if (leftEye > 0.35 && rightEye > 0.35) {
        score += 15;
      } else {
        score += 3;
        eyesOk = false;
      }
    } else {
      score += 6;
    }

    score = min(100, score);

    final sizeOk = heightRatio >= 0.18 && areaRatio >= 0.055;
    final centerOk = dx <= 0.24 && dy <= 0.28;
    final angleOk = yaw <= 22 && roll <= 22;

    final validNow = sizeOk && centerOk && angleOk && eyesOk && score >= 70;

    if (validNow) {
      _validStreak++;
    } else {
      _validStreak = 0;
    }

    final finalValid = _validStreak >= 3;

    if (finalValid) {
      return InterviewFaceResult(
        hasFace: true,
        isValid: true,
        faceDetected: true,
        faceCount: 1,
        score: score,
        status: 'valid',
        feedback: 'Votre visage est bien visible.',
      );
    }

    String feedback = 'Ajustez votre position face à la caméra.';

    if (!sizeOk) {
      feedback = 'Visage trop petit ou partiellement caché.';
    } else if (!centerOk) {
      feedback = 'Centrez mieux votre visage.';
    } else if (!angleOk) {
      feedback = 'Gardez le visage droit face à la caméra.';
    } else if (!eyesOk) {
      feedback = 'Yeux peu visibles. Évitez de cacher votre visage.';
    } else if (score < 70) {
      feedback = 'Visage détecté, mais pas assez clairement.';
    }

    return InterviewFaceResult(
      hasFace: true,
      isValid: false,
      faceDetected: false,
      faceCount: 1,
      score: score,
      status: 'partial',
      feedback: feedback,
    );
  }

  InputImage? _toInputImage({
    required CameraImage image,
    required CameraDescription camera,
  }) {
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );

    if (rotation == null) return null;

    final bytes = _cameraImageToBytes(image);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();

    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    return buffer.done().buffer.asUint8List();
  }

  Future<void> close() async {
    await _faceDetector.close();
  }
}
