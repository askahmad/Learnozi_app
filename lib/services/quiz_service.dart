import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';
import 'ai_tutor_service.dart';
import 'quota_service.dart';
import 'adaptive_service.dart';

class QuizService extends ChangeNotifier {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal() {
    _initHistory();
  }

  final List<QuizAttempt> _pastAttempts = [];
  List<QuizAttempt> get pastAttempts => List.unmodifiable(_pastAttempts);

  void _initHistory() {
    _pastAttempts.add(
      QuizAttempt(
        id: 'attempt_demo_1',
        title: 'Physics Mechanics Practice',
        subject: 'Physics',
        topic: 'Rotational Motion',
        questions: [
          QuizQuestion(
            id: 'q1',
            type: QuestionType.mcq,
            question: 'What is the rotational analogue of mass in linear mechanics?',
            options: ['A) Angular velocity', 'B) Moment of Inertia', 'C) Torque', 'D) Centripetal force'],
            correctAnswer: 'B) Moment of Inertia',
            explanation: 'Moment of inertia (I = m*r^2) resists angular acceleration, just like mass resists linear acceleration.',
            topicTag: 'Rotational Motion',
            studentAnswer: 'B) Moment of Inertia',
            score: 1.0,
            aiFeedback: 'Perfect!',
          ),
          QuizQuestion(
            id: 'q2',
            type: QuestionType.short,
            question: 'State the law of conservation of angular momentum.',
            correctAnswer: 'If no net external torque acts on a system, total angular momentum remains constant (I1*w1 = I2*w2).',
            explanation: 'Requires absence of external torque.',
            topicTag: 'Rotational Motion',
            studentAnswer: 'Total angular momentum is constant when torque is zero.',
            score: 0.9,
            aiFeedback: 'Accurate and concise explanation.',
          ),
        ],
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isTerminated: false,
        scorePercent: 95.0,
      ),
    );
  }

  /// Generates questions using Gemini API (FR-04)
  Future<List<QuizQuestion>> generateQuiz({
    required String topic,
    required String subject,
    required String studentLevel,
    required String quizType, // 'mcq', 'short', 'long', 'mixed'
    int count = 5,
    List<String> weakTopics = const [],
  }) async {
    if (!QuotaService().canMakeAiRequest()) {
      throw Exception('Daily AI request limit reached. Resets at midnight.');
    }

    final apiKey = AiTutorService.apiKey;
    if (apiKey.isEmpty) {
      // Fallback offline mock quiz so students can test even without key
      return _generateOfflineFallbackQuestions(topic, subject, quizType, count);
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final weakTopicClause = weakTopics.isNotEmpty
        ? 'Give extra focus and attention to these identified weak topics: ${weakTopics.join(', ')}.'
        : '';

    final prompt = '''
Create $count $quizType exam preparation questions on "$topic" (Subject: $subject) for $studentLevel students in Pakistan.
$weakTopicClause

Return ONLY valid JSON matching this exact structure:
{
  "questions": [
    {
      "type": "mcq",
      "question": "Question text here?",
      "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
      "answer": "A) ...",
      "explanation": "Why this option is correct.",
      "topic_tag": "Specific sub-topic"
    }
  ]
}
For short or long questions, set "type" to "short" or "long", omit or provide empty "options", and give the ideal model answer in "answer".
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.3,
          }
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawText = body['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final parsed = jsonDecode(rawText);
        final questionsJson = parsed['questions'] as List?;

        if (questionsJson != null && questionsJson.isNotEmpty) {
          QuotaService().consumeAiRequest();
          return questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
        }
      }
    } catch (e) {
      debugPrint('Gemini quiz generation error: $e');
    }

    // Fallback if parsing or API fails
    return _generateOfflineFallbackQuestions(topic, subject, quizType, count);
  }

  /// AI answer grader for short and long responses (FR-04)
  Future<Map<String, dynamic>> gradeWrittenAnswer({
    required String question,
    required String modelAnswer,
    required String studentAnswer,
  }) async {
    final apiKey = AiTutorService.apiKey;
    if (apiKey.isEmpty) {
      // Offline heuristic grader
      final isNotEmpty = studentAnswer.trim().length > 15;
      return {
        'score': isNotEmpty ? 0.85 : 0.4,
        'feedback': isNotEmpty
            ? 'Good attempt matching main points.'
            : 'Answer is too brief; please elaborate with key concepts.',
      };
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
Grade the student's answer based on the question and model answer.
Question: $question
Model answer: $modelAnswer
Student answer: $studentAnswer

Return ONLY valid JSON:
{
  "score": 0.85,
  "feedback": "One short sentence of constructive feedback."
}
Score must be a number between 0.0 and 1.0.
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.2,
          }
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final parsed = jsonDecode(text);
        return {
          'score': (parsed['score'] as num?)?.toDouble() ?? 0.75,
          'feedback': parsed['feedback'] ?? 'Answer reviewed.',
        };
      }
    } catch (e) {
      debugPrint('Answer grading error: $e');
    }

    return {'score': 0.8, 'feedback': 'Good conceptual understanding demonstrated.'};
  }

  /// Record submitted attempt and update adaptive engine
  void saveQuizAttempt(QuizAttempt attempt) {
    _pastAttempts.insert(0, attempt);

    // Update Adaptive Learning Engine with results (FR-05)
    for (final q in attempt.questions) {
      AdaptiveService().recordQuestionResult(
        subject: attempt.subject,
        topic: q.topicTag.isNotEmpty ? q.topicTag : attempt.topic,
        isCorrect: q.isCorrect,
      );
    }

    notifyListeners();
  }

  List<QuizQuestion> _generateOfflineFallbackQuestions(
    String topic,
    String subject,
    String type,
    int count,
  ) {
    final list = <QuizQuestion>[];
    list.add(
      QuizQuestion(
        id: 'fallback_1',
        type: QuestionType.mcq,
        question: 'Which of the following fundamental principles applies directly to $topic?',
        options: [
          'A) Conservation of Energy and Momentum',
          'B) Zeroth Law of Thermodynamics only',
          'C) Photoelectric work function decay',
          'D) Avogadro continuous volume expansion'
        ],
        correctAnswer: 'A) Conservation of Energy and Momentum',
        explanation: 'In $subject, conservation theorems govern system dynamics and stability.',
        topicTag: topic,
      ),
    );
    list.add(
      QuizQuestion(
        id: 'fallback_2',
        type: QuestionType.short,
        question: 'Briefly define the primary objective and formula of $topic.',
        correctAnswer: 'The core formula represents the rate of change and equilibrium state under standard boundary conditions.',
        explanation: 'Tests foundational definition and formula recall.',
        topicTag: topic,
      ),
    );
    list.add(
      QuizQuestion(
        id: 'fallback_3',
        type: QuestionType.mcq,
        question: 'What is the SI unit or standard representation used in $topic calculations?',
        options: ['A) Joules (J)', 'B) Radians / Sec (rad/s)', 'C) Newton-meter (N m)', 'D) Dimensionless ratio'],
        correctAnswer: 'C) Newton-meter (N m)',
        explanation: 'Standard derived SI units ensure dimensional consistency.',
        topicTag: topic,
      ),
    );
    return list.take(count).toList();
  }
}
