import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';
import 'adaptive_service.dart';
import 'gemini_client.dart';
import 'quota_service.dart';
import 'storage_service.dart';

class QuizService extends ChangeNotifier {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal() {
    _initHistory();
  }

  static const String _storageKey = 'quiz_attempts';
  final List<QuizAttempt> _pastAttempts = [];
  List<QuizAttempt> get pastAttempts => List.unmodifiable(_pastAttempts);

  Future<void> loadFromStorage() async {
    final raw = await StorageService().loadJson(_storageKey);
    if (raw is List && raw.isNotEmpty) {
      _pastAttempts
        ..clear()
        ..addAll(raw.map((a) => QuizAttempt.fromJson(Map<String, dynamic>.from(a))));
      notifyListeners();
    }
  }

  void _persist() {
    StorageService().saveJson(
      _storageKey,
      _pastAttempts.map((a) => a.toJson()).toList(),
    );
  }

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

  /// Generates questions using Gemini API or Free AI Engine (FR-04)
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

    // 1. Tier 1: Google Gemini (via shared GeminiClient)
    try {
      final rawText = await GeminiClient.generateContent(
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ],
          }
        ],
        temperature: 0.3,
        jsonMode: true,
        timeout: const Duration(seconds: 15),
      );

      if (rawText != null && rawText.isNotEmpty) {
        final parsed = jsonDecode(GeminiClient.stripMarkdownFences(rawText));
        final questionsJson = parsed['questions'] as List?;
        if (questionsJson != null && questionsJson.isNotEmpty) {
          QuotaService().consumeAiRequest();
          return questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
        }
      }
    } catch (e) {
      debugPrint('Gemini quiz generation error: $e');
    }

    // 2. Tier 2: Free Open AI Engine (Allows real quiz generation for ANY course without API key)
    try {
      final freeQuestions = await _generateFreeAiQuizQuestions(
        topic: topic,
        subject: subject,
        studentLevel: studentLevel,
        quizType: quizType,
        count: count,
        prompt: prompt,
      );
      if (freeQuestions != null && freeQuestions.isNotEmpty) {
        QuotaService().consumeAiRequest();
        return freeQuestions;
      }
    } catch (e) {
      debugPrint('Free AI quiz generation error: $e');
    }

    // 3. Tier 3: Fallback offline mock quiz so students can test even when offline
    return _generateOfflineFallbackQuestions(topic, subject, quizType, count);
  }

  /// Free AI Quiz generator for zero-cost operation across any department
  Future<List<QuizQuestion>?> _generateFreeAiQuizQuestions({
    required String topic,
    required String subject,
    required String studentLevel,
    required String quizType,
    required int count,
    required String prompt,
  }) async {
    final cleanText = await GeminiClient.callFreeOpenAi(
      messages: [
        {
          'role': 'system',
          'content':
              'You are an academic exam generator. Return ONLY raw valid JSON with no markdown formatting or backticks.'
        },
        {'role': 'user', 'content': prompt},
      ],
      jsonMode: true,
    );

    if (cleanText != null && cleanText.isNotEmpty) {
      final parsed = jsonDecode(cleanText);
      final questionsJson = parsed['questions'] as List?;
      if (questionsJson != null && questionsJson.isNotEmpty) {
        return questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
      }
    }
    return null;
  }

  /// AI answer grader for short and long responses (FR-04)
  Future<Map<String, dynamic>> gradeWrittenAnswer({
    required String question,
    required String modelAnswer,
    required String studentAnswer,
  }) async {
    if (studentAnswer.trim().isEmpty) {
      return {'score': 0.0, 'feedback': 'No answer was provided.'};
    }

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

    // Tier 1: Gemini
    try {
      final rawText = await GeminiClient.generateContent(
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ],
          }
        ],
        temperature: 0.2,
        jsonMode: true,
        timeout: const Duration(seconds: 12),
      );
      if (rawText != null && rawText.isNotEmpty) {
        final parsed = jsonDecode(GeminiClient.stripMarkdownFences(rawText));
        return {
          'score': (parsed['score'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.75,
          'feedback': parsed['feedback'] ?? 'Answer reviewed.',
        };
      }
    } catch (e) {
      debugPrint('Gemini grading error: $e');
    }

    // Tier 2: Free OpenAI-compatible grading
    try {
      final freeText = await GeminiClient.callFreeOpenAi(
        messages: [
          {
            'role': 'system',
            'content': 'You are a strict academic grader. Return ONLY valid JSON with score (0.0-1.0) and feedback.'
          },
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
      );
      if (freeText != null && freeText.isNotEmpty) {
        final parsed = jsonDecode(freeText);
        return {
          'score': (parsed['score'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.75,
          'feedback': parsed['feedback'] ?? 'Answer reviewed.',
        };
      }
    } catch (e) {
      debugPrint('Free AI grading error: $e');
    }

    // Tier 3: Keyword overlap heuristic fallback (offline)
    final modelKeywords = modelAnswer
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet();
    final studentLower = studentAnswer.toLowerCase();
    final matches = modelKeywords.where((k) => studentLower.contains(k)).length;
    final overlap = modelKeywords.isEmpty ? 0.5 : (matches / modelKeywords.length);
    final score = overlap.clamp(0.2, 0.95);
    return {
      'score': score,
      'feedback': score >= 0.7
          ? 'Good conceptual match with key syllabus terms.'
          : 'Missing several key terms from the model answer; review the core definition.',
    };
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

    _persist();
    notifyListeners();
  }

  List<QuizQuestion> _generateOfflineFallbackQuestions(
    String topic,
    String subject,
    String type,
    int count,
  ) {
    final list = <QuizQuestion>[];
    final lowerTopic = topic.toLowerCase();
    final lowerSubject = subject.toLowerCase();

    // 1. Subject/Topic Specific Question Banks
    if (lowerTopic.contains('rotation') || lowerTopic.contains('circular') || lowerSubject.contains('physic')) {
      list.addAll([
        QuizQuestion(
          id: 'fb_phys_1',
          type: QuestionType.mcq,
          question: 'What is the rotational analogue of mass in linear mechanics?',
          options: ['A) Angular Velocity', 'B) Moment of Inertia', 'C) Torque', 'D) Centripetal Force'],
          correctAnswer: 'B) Moment of Inertia',
          explanation: 'Moment of inertia (I = m*r^2) measures rotational inertia, analogous to mass in linear kinematics.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_phys_2',
          type: QuestionType.mcq,
          question: 'Which formula correctly relates linear velocity (v) to angular velocity (w)?',
          options: ['A) v = r * w', 'B) v = w / r', 'C) v = r^2 * w', 'D) v = w / r^2'],
          correctAnswer: 'A) v = r * w',
          explanation: 'Linear speed along the circular arc is the radius multiplied by angular velocity in radians/sec.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_phys_3',
          type: QuestionType.short,
          question: 'State the law of conservation of angular momentum.',
          correctAnswer: 'If no net external torque acts on a rotating system, its total angular momentum remains constant (I1*w1 = I2*w2).',
          explanation: 'Valid whenever net external torque is zero.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_phys_4',
          type: QuestionType.mcq,
          question: 'What is the SI unit of torque in standard rotational dynamics?',
          options: ['A) Joule (J)', 'B) Newton-meter (N m)', 'C) Watt (W)', 'D) Pascal (Pa)'],
          correctAnswer: 'B) Newton-meter (N m)',
          explanation: 'Torque tau = r x F, having the SI unit of Newton-meter (N m).',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_phys_5',
          type: QuestionType.long,
          question: 'Derive the relationship between torque and angular acceleration (tau = I * alpha).',
          correctAnswer: 'For a point mass m at radius r, tangential force is F = m*a_t = m*(r*alpha). Multiplying by radius gives tau = r*F = m*r^2*alpha. Since I = m*r^2, tau = I*alpha.',
          explanation: 'Newton second law for rotational motion.',
          topicTag: topic,
        ),
      ]);
    } else if (lowerTopic.contains('tree') || lowerTopic.contains('data') || lowerSubject.contains('computer')) {
      list.addAll([
        QuizQuestion(
          id: 'fb_cs_1',
          type: QuestionType.mcq,
          question: 'What is the average-case time complexity of searching in a balanced Binary Search Tree?',
          options: ['A) O(1)', 'B) O(log n)', 'C) O(n)', 'D) O(n log n)'],
          correctAnswer: 'B) O(log n)',
          explanation: 'In balanced BSTs (like AVL or Red-Black), height is log2(n), yielding O(log n) search time.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_cs_2',
          type: QuestionType.mcq,
          question: 'Which tree traversal visits nodes in non-decreasing (sorted) order for a BST?',
          options: ['A) Preorder (Root, Left, Right)', 'B) Inorder (Left, Root, Right)', 'C) Postorder (Left, Right, Root)', 'D) Level-order'],
          correctAnswer: 'B) Inorder (Left, Root, Right)',
          explanation: 'Inorder traversal visits left subtree (< root), then root, then right subtree (> root).',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_cs_3',
          type: QuestionType.short,
          question: 'What is the worst-case scenario for an unbalanced Binary Search Tree?',
          correctAnswer: 'When elements are inserted in already sorted or reverse-sorted order, the BST degenerates into a singly linked list with O(n) height and time complexity.',
          explanation: 'Causes linear degradation.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_cs_4',
          type: QuestionType.mcq,
          question: 'What is the maximum number of nodes at depth d (where root is at depth 0)?',
          options: ['A) 2^d', 'B) 2^(d+1)', 'C) 2^d - 1', 'D) d^2'],
          correctAnswer: 'A) 2^d',
          explanation: 'Each level doubles the capacity of the previous level, giving 2^d maximum nodes.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_cs_5',
          type: QuestionType.long,
          question: 'Explain the difference between a Complete Binary Tree and a Full Binary Tree.',
          correctAnswer: 'A Full Binary Tree is a tree where every node has either 0 or 2 children. A Complete Binary Tree has all levels completely filled except possibly the last level, which is filled from left to right.',
          explanation: 'Core structural taxonomy.',
          topicTag: topic,
        ),
      ]);
    } else {
      // General Adaptive Question Bank
      list.addAll([
        QuizQuestion(
          id: 'fb_gen_1',
          type: QuestionType.mcq,
          question: 'Which of the following fundamental principles applies directly to $topic?',
          options: [
            'A) Conservation and Equilibrium principles',
            'B) Zeroth Law of Thermodynamics only',
            'C) Photoelectric work function decay',
            'D) Continuous arbitrary volume expansion'
          ],
          correctAnswer: 'A) Conservation and Equilibrium principles',
          explanation: 'In $subject, conservation and equilibrium theorems govern system dynamics and stability.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_gen_2',
          type: QuestionType.short,
          question: 'Define the primary definition and examination significance of $topic.',
          correctAnswer: 'The core concept models system behavior under standard boundary conditions and represents the governing mathematical formulation.',
          explanation: 'Tests foundational definition and formula recall.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_gen_3',
          type: QuestionType.mcq,
          question: 'What is the standard unit or mathematical representation used in $topic?',
          options: ['A) Joules (J)', 'B) Standard SI Units', 'C) Arbitrary scalars', 'D) Dimensionless ratio'],
          correctAnswer: 'B) Standard SI Units',
          explanation: 'Standard derived SI units ensure dimensional consistency across calculations.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_gen_4',
          type: QuestionType.mcq,
          question: 'How do boundary conditions affect the stability and rate of reaction in $topic?',
          options: [
            'A) They establish dynamic equilibrium constraints',
            'B) They eliminate all variable parameters',
            'C) They have zero influence on final outcomes',
            'D) They invert the dimensional coefficients'
          ],
          correctAnswer: 'A) They establish dynamic equilibrium constraints',
          explanation: 'Boundary parameters determine valid state spaces in $subject.',
          topicTag: topic,
        ),
        QuizQuestion(
          id: 'fb_gen_5',
          type: QuestionType.long,
          question: 'Provide a comprehensive overview of $topic, its core assumptions, and its real-world application.',
          correctAnswer: 'The topic establishes how theoretical principles translate into practical engineering and scientific analysis. Key assumptions include homogeneity, standard temperature/pressure, and closed system conservation.',
          explanation: 'Evaluates thorough synthetic understanding.',
          topicTag: topic,
        ),
      ]);
    }

    // Filter by requested question type if specific
    List<QuizQuestion> filtered;
    if (type == 'mcq') {
      filtered = list.where((q) => q.type == QuestionType.mcq).toList();
    } else if (type == 'short') {
      filtered = list.where((q) => q.type == QuestionType.short).toList();
    } else if (type == 'long') {
      filtered = list.where((q) => q.type == QuestionType.long).toList();
    } else {
      filtered = list; // mixed
    }

    // If filtered is empty or less than count, backfill from list
    if (filtered.length < count) {
      for (final q in list) {
        if (!filtered.contains(q)) {
          filtered.add(q);
        }
        if (filtered.length >= count) break;
      }
    }

    return filtered.take(count).toList();
  }
}
