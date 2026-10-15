enum QuestionType { mcq, short, long }

class QuizQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String> options; // For MCQ
  final String correctAnswer;
  final String explanation;
  final String topicTag;

  // Student response
  String? studentAnswer;
  double score; // 0.0 to 1.0
  String? aiFeedback;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    required this.correctAnswer,
    required this.explanation,
    required this.topicTag,
    this.studentAnswer,
    this.score = 0.0,
    this.aiFeedback,
  });

  bool get isCorrect => score >= 0.7;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'topicTag': topicTag,
    'studentAnswer': studentAnswer,
    'score': score,
    'aiFeedback': aiFeedback,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    QuestionType parseType(String? val) {
      if (val == 'short') return QuestionType.short;
      if (val == 'long') return QuestionType.long;
      return QuestionType.mcq;
    }

    return QuizQuestion(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: parseType(json['type']),
      question: json['question'] ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: json['answer'] ?? json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
      topicTag: json['topic_tag'] ?? json['topicTag'] ?? 'General',
      studentAnswer: json['studentAnswer'],
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      aiFeedback: json['aiFeedback'] ?? json['feedback'],
    );
  }
}

class QuizAttempt {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final List<QuizQuestion> questions;
  final DateTime timestamp;
  final bool isTerminated; // If student closed or navigated away mid-quiz
  final double scorePercent;

  QuizAttempt({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.questions,
    required this.timestamp,
    this.isTerminated = false,
    required this.scorePercent,
  });

  int get totalQuestions => questions.length;
  int get correctCount => questions.where((q) => q.isCorrect).length;
}

class TopicPerformance {
  final String subject;
  final String topic;
  int attempts;
  int correct;
  double accuracy;
  DateTime lastAttemptDate;

  // ML / Rule-based diagnostic fields
  bool isWeak;
  double avgTimeSeconds;

  TopicPerformance({
    required this.subject,
    required this.topic,
    required this.attempts,
    required this.correct,
    required this.accuracy,
    required this.lastAttemptDate,
    this.isWeak = false,
    this.avgTimeSeconds = 45.0,
  });
}
