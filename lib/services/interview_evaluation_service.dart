// ============================================================
// interview_evaluation_service.dart
// Evaluation des reponses d'entretien avec Groq
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
      hardSkillsScore: 2,
      communicationScore: 2,
      structureScore: 2,
      globalFeedback:
          'L evaluation IA est limitee. Le candidat doit donner des reponses plus completes, avec des exemples concrets et une structure plus claire.',
      strengths: ['Quelques elements ont ete captures.'],
      improvements: [
        'Repondre directement a chaque question.',
        'Ajouter plus de details techniques.',
        'Structurer les reponses avec contexte, action et resultat.',
      ],
      advice: [
        'Preparer des exemples precis de projets.',
        'Expliquer clairement le role joue dans chaque experience.',
        'Mentionner les technologies utilisees et les resultats obtenus.',
      ],
    );
  }

  factory InterviewEvaluationResult.limited({required int answeredCount}) {
    final hasSomeAnswers = answeredCount > 0;

    return InterviewEvaluationResult(
      hardSkillsScore: hasSomeAnswers ? 2 : 0,
      communicationScore: hasSomeAnswers ? 2 : 0,
      structureScore: hasSomeAnswers ? 1 : 0,
      globalFeedback:
          'Evaluation limitee : le candidat a donne seulement $answeredCount reponse(s) exploitable(s). Le score reste volontairement bas car il manque assez de contenu oral pour evaluer l entretien correctement.',
      strengths: hasSomeAnswers
          ? ['Debut de participation detecte.']
          : ['Aucune reponse exploitable detectee.'],
      improvements: [
        'Repondre a davantage de questions.',
        'Donner des exemples concrets lies au CV.',
        'Structurer chaque reponse avec contexte, action et resultat.',
      ],
      advice: [
        'Preparer une reponse courte pour chaque experience et projet.',
        'Parler au moins 30 secondes par question importante.',
        'Eviter de passer les questions sans reponse.',
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
  // Remplace par ta vraie cle Groq.
  // Ne la publie jamais sur GitHub.
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';

  static Future<InterviewEvaluationResult> evaluate({
    required CandidateProfile profile,
    required List<InterviewEvaluationAnswer> answers,
  }) async {
    if (answers.isEmpty) {
      return InterviewEvaluationResult.limited(answeredCount: 0);
    }

    if (answers.length < 3) {
      return InterviewEvaluationResult.limited(answeredCount: answers.length);
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
              'temperature': 0.05,
              'max_tokens': 2500,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Tu es un recruteur technique strict mais juste. Tu evalues uniquement les reponses orales donnees, pas le CV seul. Tu reponds uniquement en JSON valide.',
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
Evalue cet entretien de candidat.

PROFIL CANDIDAT :
Nom : ${profile.fullName}
Titre : ${profile.profileTitle}
Domaine : ${profile.mainDomain}
Competences : ${profile.allTechnicalSkills.join(', ')}
Experiences : ${profile.experiences.map((e) => '${e.poste} chez ${e.entreprise}').join(' | ')}
Projets : ${profile.projects.map((p) => p.nom).join(' | ')}

REPONSES DU CANDIDAT :
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

REGLES STRICTES :
- Les scores doivent etre entre 0 et 10.
- hardSkillsScore evalue la qualite technique des reponses orales.
- communicationScore evalue la clarte, la precision et la coherence.
- structureScore evalue si les reponses sont organisees avec contexte, action et resultat.
- Evalue uniquement ce qui est dit dans les reponses, pas ce qui existe dans le CV.
- Si une reponse est vague, hors sujet, trop courte ou incomprehensible, elle doit etre fortement penalisee.
- Ne donne pas un bon score parce que le CV semble bon.
- Ne mentionne un point fort que s'il est clairement demontre dans les reponses.
- Si les reponses manquent de details, les scores doivent rester bas meme si le candidat est etudiant.
- Pour une evaluation LinkedIn/presentation projet, sois professionnel, exigeant et credible.
- Ne donne pas de diagnostic psychologique.
- Donne un feedback simple, utile et professionnel.
- Reponds dans la langue dominante du profil candidat.
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
