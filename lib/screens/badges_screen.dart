import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _userService = UserService();
  String _filter = 'All'; // 'All', 'Unlocked', 'Locked'

  final List<Map<String, dynamic>> _allBadges = const [
    {
      'id': 'first_step',
      'title': 'First Step',
      'desc': 'Registered and began study companion journey',
      'icon': Icons.flag_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'id': 'quiz_apprentice',
      'title': 'Quiz Apprentice',
      'desc': 'Attempted first adaptive mock test',
      'icon': Icons.school_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'quiz_master',
      'title': 'Quiz Master',
      'desc': 'Passed adaptive assessments with >= 60% score',
      'icon': Icons.military_tech_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'streak_starter',
      'title': '3-Day Fire Streak',
      'desc': 'Maintained a 3-day active study streak',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEA580C),
    },
    {
      'id': 'focus_scholar',
      'title': 'Focus Scholar',
      'desc': 'Logged 5 completed Pomodoro focus blocks',
      'icon': Icons.timer_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'id': 'flashcard_champ',
      'title': 'Flashcard Champ',
      'desc': 'Completed 20 SM-2 active recall repetitions',
      'icon': Icons.style_rounded,
      'color': Color(0xFF06B6D4),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = _userService.profile;
    final earned = user.earnedBadges;
    final unlockedCount = _allBadges.where((b) => earned.contains(b['id'])).length;
    final progress = _allBadges.isNotEmpty ? unlockedCount / _allBadges.length : 0.0;

    final displayedBadges = _allBadges.where((b) {
      final isUnlocked = earned.contains(b['id']);
      if (_filter == 'Unlocked') return isUnlocked;
      if (_filter == 'Locked') return !isUnlocked;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements & Badges',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Daily streaks, exam milestones & study rewards',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Hero Streak Flame Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.fireStreakGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.streakOrange.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.currentStreak} Day Study Streak! 🔥',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Longest streak: ${user.longestStreak} days. Study each day to keep your momentum alive!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Milestone Progress Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Badges Mastered',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$unlockedCount of ${_allBadges.length} Unlocked',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Tabs (All, Unlocked, Locked)
            Row(
              children: ['All', 'Unlocked', 'Locked'].map((tab) {
                final isSelected = _filter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _filter = tab),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Badges Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedBadges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) {
                final badge = displayedBadges[i];
                final isUnlocked = earned.contains(badge['id']);
                final color = badge['color'] as Color;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnlocked ? color.withValues(alpha: 0.5) : AppColors.border,
                      width: isUnlocked ? 1.6 : 1.0,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? color.withValues(alpha: 0.14)
                                  : AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              badge['icon'] as IconData,
                              size: 32,
                              color: isUnlocked ? color : AppColors.textMuted,
                            ),
                          ),
                          if (!isUnlocked)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF64748B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        badge['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
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
                          color: isUnlocked ? AppColors.textSecondary : AppColors.textPlaceholder,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUnlocked ? AppColors.successSoft : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUnlocked ? AppColors.successBorder : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isUnlocked ? 'UNLOCKED' : 'LOCKED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: isUnlocked ? AppColors.successDark : AppColors.textMuted,
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
