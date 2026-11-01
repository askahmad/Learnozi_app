import 'package:flutter/material.dart';
import '../services/study_planner_service.dart';
import '../services/quiz_service.dart';
import '../services/adaptive_service.dart';
import '../services/user_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plannerService = StudyPlannerService();
    final quizService = QuizService();
    final adaptiveService = AdaptiveService();
    final userService = UserService();

    final totalFocusMins = plannerService.totalFocusMinutesLogged;
    final totalFocusHours = (totalFocusMins / 60).toStringAsFixed(1);
    final pastQuizzes = quizService.pastAttempts;

    final avgAccuracy = pastQuizzes.isEmpty
        ? 85.0
        : pastQuizzes.fold<double>(0.0, (sum, q) => sum + q.scorePercent) / pastQuizzes.length;

    final weakCount = adaptiveService.weakTopics.length;
    final totalTopics = adaptiveService.allTopics.length;
    final masteredCount = totalTopics - weakCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Study hours, accuracy trends & syllabus mastery progress',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top 3 KPI Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Study Time',
                    value: '${totalFocusHours}h',
                    subtitle: '$totalFocusMins mins recorded',
                    color: const Color(0xFF4F46E5),
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Avg. Accuracy',
                    value: '${avgAccuracy.toStringAsFixed(0)}%',
                    subtitle: '${pastQuizzes.length} exams taken',
                    color: const Color(0xFF10B981),
                    icon: Icons.track_changes_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Current Streak',
                    value: '${userService.profile.currentStreak} Days',
                    subtitle: 'Longest: ${userService.profile.longestStreak} days',
                    color: const Color(0xFFEA580C),
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Topics Mastered',
                    value: '$masteredCount / $totalTopics',
                    subtitle: '$weakCount flagged weak',
                    color: const Color(0xFF7C3AED),
                    icon: Icons.psychology_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Visual Chart 1: Study Activity Bar Chart (Last 5 Days)
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Focus Hours Logged',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                      ),
                      Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildActivityBar('Mon', 0.45, '45m'),
                      _buildActivityBar('Tue', 0.80, '80m'),
                      _buildActivityBar('Wed', 0.60, '60m'),
                      _buildActivityBar('Thu', 0.95, '95m'),
                      _buildActivityBar('Fri', 0.50, '50m'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visual Chart 2: Topic Mastery Ratio Breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Syllabus Coverage Breakdown',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (masteredCount * 10).clamp(1, 100),
                          child: Container(
                            height: 22,
                            color: const Color(0xFF10B981),
                            alignment: Alignment.center,
                            child: const Text('Mastered (75%)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          flex: (weakCount * 10).clamp(1, 100),
                          child: Container(
                            height: 22,
                            color: const Color(0xFFEF4444),
                            alignment: Alignment.center,
                            child: const Text('Weak (25%)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                      SizedBox(width: 4),
                      Text('High Accuracy (>= 60%)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(width: 16),
                      Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
                      SizedBox(width: 4),
                      Text('Adaptive Priority (< 60%)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildActivityBar(String day, double heightFraction, String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 120 * heightFraction,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
      ],
    );
  }
}
