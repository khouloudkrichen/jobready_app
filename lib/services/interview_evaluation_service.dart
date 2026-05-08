// ============================================================
// interview_evaluation_service.dart
// Évaluation des réponses d'entretien avec Groq
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/candidate_profile.dart';

class InterviewEvaluationResult {
  final int hardSkillsScore;
  final int communicationScore;
  final int structureScore;
  final String globalFeedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> advice;

  InterviewEvaluationResult({
    required this.hardSkillsScore,
    required this.communicationScore,
    required this.structureScore,
    required this.globalFeedback,
    required this.strengths,
    required this.improvements,
    required this.advice,
  });

  factory InterviewEvaluationResult.fallback() {
    return InterviewEvaluationResult(
      hardSkillsScore: 6,
      communicationScore: 6,
      structureScore: 6,
      globalFeedback:
          'Les réponses sont correctes. Pour progresser, il faut donner plus d’exemples concrets, expliquer les technologies utilisées et mieux structurer les réponses.',
      strengths: [
        'Le candidat a répondu à toutes les questions.',
        'Les réponses montrent une compréhension générale du parcours.',
      ],
      improvements: [
        'Ajouter plus de détails techniques.',
        'Structurer les réponses avec contexte, action et résultat.',
      ],
      advice: [
        'Préparer des exemples précis de projets.',
        'Expliquer clairement le rôle joué dans chaque expérience.',
        'Mentionner les technologies utilisées et les résultats obtenus.',
      ],
    );
  }

  factory InterviewEvaluationResult.fromJson(Map<String, dynamic> json) {
    return InterviewEvaluationResult(
      hardSkillsScore: _toInt(json['hardSkillsScore']),
      communicationScore: _toInt(json['communicationScore']),
      structureScore: _toInt(json['structureScore']),
      globalFeedback: (json['globalFeedback'] ?? '').toString(),
      strengths: _toStringList(json['strengths']),
      improvements: _toStringList(json['improvements']),
      advice: _toStringList(json['advice']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 10);
    if (value is double) return value.round().clamp(0, 10);
    if (value is String) {
      return (int.tryParse(value) ?? 0).clamp(0, 10);
    }
    return 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class InterviewEvaluationAnswer {
  final String question;
  final String category;
  final String answer;

  InterviewEvaluationAnswer({
    required this.question,
    required this.category,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'category': category,
    'answer': answer,
  };
}

class InterviewEvaluationService {
  // Remplace par ta vraie clé Groq.
  // Ne la publie jamais sur GitHub.
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';

  static Future<InterviewEvaluationResult> evaluate({
    required CandidateProfile profile,
    required List<InterviewEvaluationAnswer> answers,
  }) async {
    if (answers.isEmpty) {
      return InterviewEvaluationResult.fallback();
    }

    try {
      final prompt = _buildPrompt(profile: profile, answers: answers);

      final response = await http
          .post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: jsonEncode({
              'model': _groqModel,
              'temperature': 0.1,
              'max_tokens': 2500,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Tu es un recruteur technique. Tu évalues les réponses d’un candidat de façon juste, simple et pédagogique. Tu réponds uniquement en JSON valide.',
                },
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 35));

      print('Interview Groq status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('Interview Groq erreur: ${response.body}');
        return InterviewEvaluationResult.fallback();
      }

      final data = jsonDecode(response.body);
      final content = (data['choices']?[0]?['message']?['content'] ?? '')
          .toString();

      final jsonText = _extractJson(content);
      print('Interview evaluation JSON: $jsonText');

      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;

      return InterviewEvaluationResult.fromJson(parsed);
    } catch (e) {
      print('Interview evaluation erreur: $e');
      return InterviewEvaluationResult.fallback();
    }
  }

  static String _buildPrompt({
    required CandidateProfile profile,
    required List<InterviewEvaluationAnswer> answers,
  }) {
    final answersJson = answers.map((a) => a.toJson()).toList();

    return '''
Évalue cet entretien de candidat.

PROFIL CANDIDAT :
Nom : ${profile.fullName}
Titre : ${profile.profileTitle}
Domaine : ${profile.mainDomain}
Compétences : ${profile.allTechnicalSkills.join(', ')}
Expériences : ${profile.experiences.map((e) => '${e.poste} chez ${e.entreprise}').join(' | ')}
Projets : ${profile.projects.map((p) => p.nom).join(' | ')}

RÉPONSES DU CANDIDAT :
${jsonEncode(answersJson)}

Retourne uniquement ce JSON :

{
  "hardSkillsScore": 0,
  "communicationScore": 0,
  "structureScore": 0,
  "globalFeedback": "",
  "strengths": [],
  "improvements": [],
  "advice": []
}

RÈGLES :
- Les scores doivent être entre 0 et 10.
- hardSkillsScore évalue la qualité technique des réponses.
- communicationScore évalue la clarté et la précision.
- structureScore évalue si les réponses sont bien organisées.
- Ne sois pas trop sévère si le candidat est étudiant.
- Ne donne pas de diagnostic psychologique.
- Donne un feedback simple, utile et professionnel.
- Réponds dans la langue dominante du profil candidat.
- Aucune phrase hors JSON.
''';
  }

  static String _extractJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start >= 0 && end > start) {
      return cleaned.substring(start, end + 1);
    }

    return cleaned;
  }
}
