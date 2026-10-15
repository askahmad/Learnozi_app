import 'package:flutter/material.dart';
import '../services/user_service.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final user = userService.profile;

    final allBadges = [
      {
        'id': 'first_step',
        'title': 'First Step',
        'desc': 'Registered and began study companion journey',
        'icon': Icons.flag_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'quiz_apprentice',
        'title': 'Quiz Apprentice',
        'desc': 'Attempted first adaptive mock test',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'quiz_master',
        'title': 'Quiz Master',
        'desc': 'Passed adaptive assessments with >= 60% score',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'streak_starter',
        'title': '3-Day Fire Streak',
        'desc': 'Maintained a 3-day active study streak',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFEA580C),
      },
      {
        'id': 'focus_scholar',
        'title': 'Focus Scholar',
        'desc': 'Logged 5 completed Pomodoro focus blocks',
        'icon': Icons.timer_rounded,
        'color': const Color(0xFF7C3AED),
      },
      {
        'id': 'flashcard_champ',
        'title': 'Flashcard Champ',
        'desc': 'Completed 20 SM-2 active recall repetitions',
        'icon': Icons.style_rounded,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements & Badges',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Daily streaks & milestones gamification (FR-15)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Hero Streak Flame Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.currentStreak} Day Study Streak! 🔥',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Longest streak: ${user.longestStreak} days. Study daily to keep your fire burning!',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Badges Grid
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Catalogue of Badges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allBadges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) {
                final badge = allBadges[i];
                final isUnlocked = user.earnedBadges.contains(badge['id']);
                final color = badge['color'] as Color;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnlocked ? color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                      width: isUnlocked ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked ? color.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge['icon'] as IconData,
                          size: 32,
                          color: isUnlocked ? color : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        badge['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge['desc'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isUnlocked ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUnlocked ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isUnlocked ? 'UNLOCKED' : 'LOCKED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
