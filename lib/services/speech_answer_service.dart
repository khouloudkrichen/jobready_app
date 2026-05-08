// ============================================================
// speech_answer_service.dart
// Service Speech-to-Text pour réponses orales d'entretien
// Mode manuel : cliquer micro pour commencer, recliquer pour terminer
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechAnswerService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _ready = false;
  bool _manualStop = false;
  bool _keepListening = false;

  String _localeId = 'fr_FR';
  String _lastText = '';

  Timer? _restartTimer;

  void Function(String text, bool isFinal)? _onText;
  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  bool get isReady => _ready;
  bool get isListening => _speech.isListening || _keepListening;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;

    try {
      _ready = await _speech.initialize(
        onStatus: _handleStatus,
        onError: (error) {
          _handleError(error.errorMsg);
        },
        debugLogging: false,
        finalTimeout: const Duration(seconds: 60),
      );

      return _ready;
    } catch (e) {
      debugPrint('Speech init error: $e');
      _ready = false;
      _onError?.call(e.toString());
      return false;
    }
  }

  Future<bool> startListening({
    required String localeId,
    required void Function(String text, bool isFinal) onText,
  }) async {
    if (!_ready) {
      _ready = await initialize(onStatus: _onStatus, onError: _onError);
    }

    if (!_ready) return false;

    _localeId = localeId;
    _onText = onText;

    _lastText = '';
    _manualStop = false;
    _keepListening = true;

    return _startNativeListening();
  }

  Future<bool> _startNativeListening() async {
    try {
      _restartTimer?.cancel();

      if (_speech.isListening) {
        await _speech.cancel();
      }

      await _speech.listen(
        localeId: _localeId,

        // Durée maximale d'une session micro.
        listenFor: const Duration(minutes: 5),

        // Grande pause autorisée.
        // Le candidat peut réfléchir sans que ça coupe directement.
        pauseFor: const Duration(seconds: 60),

        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,

        onResult: (result) {
          final recognized = result.recognizedWords.trim();

          if (recognized.isNotEmpty) {
            _lastText = recognized;
          }

          // On sauvegarde la réponse en arrière-plan.
          // Mais on ne la considère pas terminée tant que l'utilisateur
          // ne reclique pas sur le micro.
          _onText?.call(_lastText, false);
        },
      );

      _onStatus?.call('Écoute en cours... recliquez pour terminer');
      return true;
    } catch (e) {
      debugPrint('Speech listen error: $e');
      _onError?.call(e.toString());
      return false;
    }
  }

  void _handleStatus(String status) {
    debugPrint('Speech status: $status');

    final lower = status.toLowerCase();

    if (lower == 'listening') {
      _onStatus?.call('Écoute en cours... recliquez pour terminer');
      return;
    }

    // Si Android coupe tout seul mais que l'utilisateur n'a pas cliqué stop,
    // on relance automatiquement le micro.
    if ((lower == 'done' || lower == 'notlistening') &&
        _keepListening &&
        !_manualStop) {
      _restartMicro();
      return;
    }

    _onStatus?.call(status);
  }

  void _handleError(String errorMsg) {
    debugPrint('Speech error: $errorMsg');

    final lower = errorMsg.toLowerCase();

    // error_no_match arrive souvent pendant une pause.
    // On ne le considère pas comme une vraie erreur.
    if (lower.contains('no_match') && _keepListening && !_manualStop) {
      _restartMicro();
      return;
    }

    if (_manualStop) return;

    _keepListening = false;
    _onError?.call(errorMsg);
  }

  void _restartMicro() {
    if (!_keepListening || _manualStop) return;

    _onStatus?.call('Pause détectée... micro toujours actif');

    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!_keepListening || _manualStop) return;
      await _startNativeListening();
    });
  }

  Future<void> stopListening() async {
    _manualStop = true;
    _keepListening = false;
    _restartTimer?.cancel();

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Speech stop error: $e');
    }

    // Ici seulement, on considère la réponse comme finale.
    _onText?.call(_lastText, true);

    if (_lastText.trim().isEmpty) {
      _onStatus?.call('Aucune réponse capturée');
    } else {
      _onStatus?.call('Réponse enregistrée');
    }
  }

  Future<void> cancelListening() async {
    _manualStop = true;
    _keepListening = false;
    _restartTimer?.cancel();

    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('Speech cancel error: $e');
    }
  }
}
