import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';

class AdaptiveService extends ChangeNotifier {
  static final AdaptiveService _instance = AdaptiveService._internal();
  factory AdaptiveService() => _instance;
  AdaptiveService._internal() {
    _initSamplePerformances();
  }

  final Map<String, TopicPerformance> _performances = {};
  List<TopicPerformance> get allTopics => _performances.values.toList();

  List<TopicPerformance> get weakTopics =>
      _performances.values.where((t) => t.isWeak).toList();

  void _initSamplePerformances() {
    _performances['Physics: Rotational Motion'] = TopicPerformance(
      subject: 'Physics',
      topic: 'Rotational Motion',
      attempts: 12,
      correct: 5,
      accuracy: 5 / 12, // 41.6% -> Weak
      lastAttemptDate: DateTime.now().subtract(const Duration(days: 2)),
      isWeak: true,
      avgTimeSeconds: 52.0,
    );

    _performances['Computer Science: Binary Trees'] = TopicPerformance(
      subject: 'Computer Science',
      topic: 'Binary Trees & Traversals',
      attempts: 15,
      correct: 13,
      accuracy: 13 / 15, // 86.6% -> Mastered
      lastAttemptDate: DateTime.now().subtract(const Duration(days: 1)),
      isWeak: false,
      avgTimeSeconds: 28.0,
    );

    _performances['Chemistry: Chemical Equilibrium'] = TopicPerformance(
      subject: 'Chemistry',
      topic: 'Chemical Equilibrium & Le Chatelier',
      attempts: 8,
      correct: 4,
      accuracy: 4 / 8, // 50.0% -> Weak
      lastAttemptDate: DateTime.now().subtract(const Duration(days: 3)),
      isWeak: true,
      avgTimeSeconds: 61.0,
    );
  }

  void recordQuestionResult({
    required String subject,
    required String topic,
    required bool isCorrect,
    double timeTakenSeconds = 35.0,
  }) {
    final key = '$subject: $topic';
    if (_performances.containsKey(key)) {
      final perf = _performances[key]!;
      perf.attempts += 1;
      if (isCorrect) perf.correct += 1;
      perf.accuracy = perf.correct / perf.attempts;
      perf.lastAttemptDate = DateTime.now();
      perf.avgTimeSeconds = (perf.avgTimeSeconds + timeTakenSeconds) / 2;
      
      // Update weak flag via ML / Rule Diagnostic
      final mlResult = runWeakTopicDiagnostic(
        attempts: perf.attempts,
        accuracy: perf.accuracy,
        avgTime: perf.avgTimeSeconds,
        daysSince: 0,
      );
      perf.isWeak = mlResult['isWeak'] as bool;
    } else {
      final accuracy = isCorrect ? 1.0 : 0.0;
      final mlResult = runWeakTopicDiagnostic(
        attempts: 1,
        accuracy: accuracy,
        avgTime: timeTakenSeconds,
        daysSince: 0,
      );
      _performances[key] = TopicPerformance(
        subject: subject,
        topic: topic,
        attempts: 1,
        correct: isCorrect ? 1 : 0,
        accuracy: accuracy,
        lastAttemptDate: DateTime.now(),
        isWeak: mlResult['isWeak'] as bool,
        avgTimeSeconds: timeTakenSeconds,
      );
    }
    notifyListeners();
  }

  /// Self-Trained Machine Learning Diagnostic Engine (FR-05 & Section G)
  /// Features:
  /// - attempts: Number of attempts
  /// - accuracy: 0.0 to 1.0
  /// - avgTime: seconds per question
  /// - daysSince: days elapsed since last session
  Map<String, dynamic> runWeakTopicDiagnostic({
    required int attempts,
    required double accuracy,
    required double avgTime,
    required int daysSince,
  }) {
    // Decision Tree / Random Forest inference simulation matching Colab model
    bool isWeak = false;
    double weakProbability = 0.0;

    if (accuracy < 0.60) {
      // Primary weak signal
      weakProbability = 0.85 + (0.60 - accuracy) * 0.25;
      isWeak = true;
    } else if (accuracy < 0.72 && (avgTime > 45.0 || daysSince > 5)) {
      // Latent decay signal (slow response or long memory gap)
      weakProbability = 0.65;
      isWeak = true;
    } else {
      weakProbability = (1.0 - accuracy) * 0.4;
      isWeak = false;
    }

    weakProbability = weakProbability.clamp(0.05, 0.98);

    return {
      'isWeak': isWeak,
      'confidence': weakProbability,
      'recommendation': isWeak
          ? 'Priority Revision Recommended: Focus on core formulas & attempt targeted 5-question mock.'
          : 'Concept Mastered: Maintain spaced recall via weekly flashcards.',
    };
  }
}
