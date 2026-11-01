import 'package:flutter/material.dart';
import '../services/adaptive_service.dart';
import 'quiz_screen.dart';

class AdaptiveLearningScreen extends StatefulWidget {
  const AdaptiveLearningScreen({super.key});

  @override
  State<AdaptiveLearningScreen> createState() => _AdaptiveLearningScreenState();
}

class _AdaptiveLearningScreenState extends State<AdaptiveLearningScreen> {
  final _adaptiveService = AdaptiveService();

  // ML Test simulation values for supervisor demo
  double _testAttempts = 12;
  double _testAccuracy = 0.45; // 45%
  double _testAvgTime = 55; // 55 seconds
  final double _testDaysSince = 3;

  @override
  Widget build(BuildContext context) {
    final weakTopics = _adaptiveService.weakTopics;
    final allTopics = _adaptiveService.allTopics;

    final mlResult = _adaptiveService.runWeakTopicDiagnostic(
      attempts: _testAttempts.round(),
      accuracy: _testAccuracy,
      avgTime: _testAvgTime,
      daysSince: _testDaysSince.round(),
    );

    final isWeak = mlResult['isWeak'] as bool;
    final confidence = (mlResult['confidence'] as double) * 100;
    final recommendation = mlResult['recommendation'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adaptive Learning Engine',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Self-Trained ML Weak-Topic Diagnostic Engine',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personalized Syllabus Mastery',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Using your quiz attempts and response speed, our scikit-learn model detects weak topics and shapes future mock tests.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.psychology_rounded, size: 44, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Section 1: Detected Weak Topics List
            const Text(
              'Identified Weak Topics (Requires Revision)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            if (weakTopics.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                    SizedBox(width: 10),
                    Text('All assessed topics are above 60% accuracy! Keep it up.', style: TextStyle(fontSize: 13)),
                  ],
                ),
              )
            else
              ...weakTopics.map((t) => _buildWeakTopicCard(t)),

            const SizedBox(height: 26),

            // Section 2: Interactive ML Model Simulator (Viva Demo)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.memory_rounded, size: 18, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Self-Trained Model Simulator (Section G)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Simulate student feature inputs to verify the Decision Tree / Random Forest output in real-time:',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  // Feature 1: Attempts
                  Text('Attempts: ${_testAttempts.round()} questions', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _testAttempts,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setState(() => _testAttempts = val),
                  ),

                  // Feature 2: Accuracy
                  Text('Accuracy: ${(_testAccuracy * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _testAccuracy,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setState(() => _testAccuracy = val),
                  ),

                  // Feature 3: Avg Time
                  Text('Average Time: ${_testAvgTime.round()} sec / question', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _testAvgTime,
                    min: 10,
                    max: 120,
                    divisions: 22,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setState(() => _testAvgTime = val),
                  ),

                  const SizedBox(height: 12),
                  // Model Inference Result Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isWeak ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isWeak ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isWeak ? '🔴 PREDICTED: WEAK TOPIC (Label 1)' : '🟢 PREDICTED: MASTERED (Label 0)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isWeak ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              '${confidence.toStringAsFixed(0)}% Conf.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isWeak ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recommendation,
                          style: TextStyle(fontSize: 12, color: isWeak ? const Color(0xFF7F1D1D) : const Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: All Tracked Topics Table
            const Text(
              'All Tracked Topics Performance',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            ...allTopics.map((t) => _buildAllTopicTile(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakTopicCard(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.topic,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 3),
                Text(
                  '${t.subject} • Accuracy: ${(t.accuracy * 100).toStringAsFixed(0)}% (${t.correct}/${t.attempts})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuizScreen(initialTopic: t.topic)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Practice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTopicTile(dynamic t) {
    final acc = (t.accuracy * 100).round();
    final isGood = acc >= 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(t.subject, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '$acc%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isGood ? Icons.check_circle_rounded : Icons.error_rounded,
                color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
