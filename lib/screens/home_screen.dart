import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/quota_service.dart';
import '../services/adaptive_service.dart';
import '../services/flashcard_service.dart';
import '../services/study_planner_service.dart';
import '../services/document_service.dart';
import '../services/quiz_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/localization.dart';
import 'ai_tutor_screen.dart';
import 'document_chat_screen.dart';
import 'quiz_screen.dart';
import 'flashcards_screen.dart';
import 'study_planner_screen.dart';
import 'pomodoro_timer_screen.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'badges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _userService = UserService();
  final _quotaService = QuotaService();
  final _adaptiveService = AdaptiveService();
  final _plannerService = StudyPlannerService();
  final _flashcardService = FlashcardService();
  final _docService = DocumentService();
  final _themeService = ThemeService();
  final _quizService = QuizService();

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onStateChanged);
    _quotaService.addListener(_onStateChanged);
    _adaptiveService.addListener(_onStateChanged);
    _plannerService.addListener(_onStateChanged);
    _flashcardService.addListener(_onStateChanged);
    _docService.addListener(_onStateChanged);
    _themeService.addListener(_onStateChanged);
    _quizService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _userService.removeListener(_onStateChanged);
    _quotaService.removeListener(_onStateChanged);
    _adaptiveService.removeListener(_onStateChanged);
    _plannerService.removeListener(_onStateChanged);
    _flashcardService.removeListener(_onStateChanged);
    _docService.removeListener(_onStateChanged);
    _themeService.removeListener(_onStateChanged);
    _quizService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDark => _themeService.isDarkMode;
  Color get _bg => _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _cardBg => _isDark ? AppColors.darkSurface : Colors.white;
  Color get _cardBorder => _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _textPrimary => _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _textSecondary => _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _surfaceElevated => _isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from your Learnozi account?',
          style: TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = _userService.profile;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber);
    EducationType eduType = user.educationType;

    // University state
    String selectedUni = UserProfile.pakistaniUniversities.contains(user.universityName)
        ? user.universityName
        : (user.universityName.isNotEmpty ? 'Other (Type your own University)' : UserProfile.pakistaniUniversities.first);
    final customUniController = TextEditingController(
      text: UserProfile.pakistaniUniversities.contains(user.universityName) ? '' : user.universityName,
    );

    String selectedProg = UserProfile.universityPrograms.contains(user.program)
        ? user.program
        : (user.program.isNotEmpty ? 'Other (Type your own Degree / Program)' : UserProfile.universityPrograms.first);
    final customProgController = TextEditingController(
      text: UserProfile.universityPrograms.contains(user.program) ? '' : user.program,
    );

    String selectedSem = UserProfile.universitySemesters.contains(user.semester)
        ? user.semester
        : (user.semester.isNotEmpty ? 'Other (Type Semester)' : (user.semester.isEmpty ? 'None / Not Applicable' : '1st Semester'));
    final customSemController = TextEditingController(
      text: UserProfile.universitySemesters.contains(user.semester) ? '' : user.semester,
    );

    // School state
    String selectedSchoolGrade = UserProfile.schoolGrades.contains(user.schoolGrade)
        ? user.schoolGrade
        : (user.schoolGrade.isNotEmpty ? 'Other (Type Grade)' : UserProfile.schoolGrades.first);
    final customSchoolGradeController = TextEditingController(
      text: UserProfile.schoolGrades.contains(user.schoolGrade) ? '' : user.schoolGrade,
    );

    String selectedSchoolTrack = UserProfile.schoolTracks.contains(user.schoolCourse)
        ? user.schoolCourse
        : (user.schoolCourse.isNotEmpty ? 'Other (Type Track)' : UserProfile.schoolTracks.first);
    final customSchoolTrackController = TextEditingController(
      text: UserProfile.schoolTracks.contains(user.schoolCourse) ? '' : user.schoolCourse,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Academic Profile Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Personalize your syllabus, AI explanations, and mock test curriculum', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'e.g. 0300 1234567',
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Education Level Segmented Toggle (School vs University)
                  SegmentedButton<EducationType>(
                    segments: const [
                      ButtonSegment(
                        value: EducationType.university,
                        label: Text('University'),
                        icon: Icon(Icons.account_balance_rounded),
                      ),
                      ButtonSegment(
                        value: EducationType.school,
                        label: Text('School / College'),
                        icon: Icon(Icons.school_rounded),
                      ),
                    ],
                    selected: {eduType},
                    onSelectionChanged: (val) {
                      setModalState(() => eduType = val.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (eduType == EducationType.school) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedSchoolGrade,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Grade / Class',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserProfile.schoolGrades.map((g) {
                        return DropdownMenuItem<String>(
                          value: g,
                          child: Text(g, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSchoolGrade = val);
                      },
                    ),
                    if (selectedSchoolGrade == 'Other (Type Grade)') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customSchoolGradeController,
                        decoration: InputDecoration(
                          labelText: 'Type your grade / class',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSchoolTrack,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Course / Track',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserProfile.schoolTracks.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSchoolTrack = val);
                      },
                    ),
                    if (selectedSchoolTrack == 'Other (Type Track)') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customSchoolTrackController,
                        decoration: InputDecoration(
                          labelText: 'Type your course / track',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Pakistani Universities
                    DropdownButtonFormField<String>(
                      initialValue: selectedUni,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'University',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserProfile.pakistaniUniversities.map((u) {
                        return DropdownMenuItem<String>(
                          value: u,
                          child: Text(u, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedUni = val);
                      },
                    ),
                    if (selectedUni == 'Other (Type your own University)') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customUniController,
                        decoration: InputDecoration(
                          labelText: 'Type your university name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Programs / Degrees
                    DropdownButtonFormField<String>(
                      initialValue: selectedProg,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Degree / Program',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserProfile.universityPrograms.map((p) {
                        return DropdownMenuItem<String>(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedProg = val);
                      },
                    ),
                    if (selectedProg == 'Other (Type your own Degree / Program)') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customProgController,
                        decoration: InputDecoration(
                          labelText: 'Type your program / degree',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Semester
                    DropdownButtonFormField<String>(
                      initialValue: selectedSem,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: UserProfile.universitySemesters.map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSem = val);
                      },
                    ),
                    if (selectedSem == 'Other (Type Semester)') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customSemController,
                        decoration: InputDecoration(
                          labelText: 'Type your semester (e.g. 9th Semester)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final finalUniversity = eduType == EducationType.university
                          ? (selectedUni == 'Other (Type your own University)'
                              ? customUniController.text.trim()
                              : selectedUni)
                          : '';
                      final finalProgram = eduType == EducationType.university
                          ? (selectedProg == 'Other (Type your own Degree / Program)'
                              ? customProgController.text.trim()
                              : selectedProg)
                          : '';
                      final finalSemester = eduType == EducationType.university
                          ? (selectedSem == 'Other (Type Semester)'
                              ? customSemController.text.trim()
                              : (selectedSem == 'None / Not Applicable' ? '' : selectedSem))
                          : '';
                      final finalSchoolGrade = eduType == EducationType.school
                          ? (selectedSchoolGrade == 'Other (Type Grade)'
                              ? customSchoolGradeController.text.trim()
                              : selectedSchoolGrade)
                          : '';
                      final finalSchoolTrack = eduType == EducationType.school
                          ? (selectedSchoolTrack == 'Other (Type Track)'
                              ? customSchoolTrackController.text.trim()
                              : selectedSchoolTrack)
                          : '';

                      _userService.updateProfile(
                        name: nameController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        educationType: eduType,
                        schoolGrade: finalSchoolGrade,
                        schoolCourse: finalSchoolTrack,
                        universityName: finalUniversity,
                        semester: finalSemester,
                        program: finalProgram,
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Academic Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, _) {
        final user = _authService.currentUser;
        final profile = _userService.profile;
        final displayName = profile.name.isNotEmpty
            ? profile.name
            : (user?.displayName ?? 'Student');
        final email = user?.email ?? profile.email;

        final List<Widget> pages = [
          _buildDashboardView(displayName),
          const AiTutorScreen(),
          const QuizScreen(),
          _buildStudyToolsHub(),
          _buildProfileTab(displayName, email),
        ];

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: _buildModernBottomNav(),
        );
      },
    );
  }

  String _getGreeting([String lang = 'English']) {
    final hour = DateTime.now().hour;
    if (lang == 'Urdu') {
      if (hour < 12) return 'صبح بخیر';
      if (hour < 17) return 'دوپہر بخیر';
      return 'شام بخیر';
    }
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // --- 1. DASHBOARD VIEW ---
  Widget _buildDashboardView(String displayName) {
    final profile = _userService.profile;
    final lang = profile.language;
    final isUrdu = lang == 'Urdu';
    final remainingQuota = _quotaService.remainingAiRequests;
    final weakTopics = _adaptiveService.weakTopics;
    final primaryWeak = weakTopics.isNotEmpty ? weakTopics.first : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Greeting Header Bar (Row 1: Profile & Quick Actions)
          Row(
            children: [
              // User Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Greeting & Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? 'السلام علیکم،' : '${_getGreeting(lang)},',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dual Theme Switcher Button
              InkWell(
                onTap: () {
                  _themeService.toggleTheme();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _themeService.isDarkMode
                            ? (isUrdu ? 'ڈارک تھیم فعال ہو گئی' : 'Switched to Dark Theme')
                            : (isUrdu ? 'لائٹ تھیم فعال ہو گئی' : 'Switched to Light Theme'),
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeService.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _themeService.isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    _themeService.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 16,
                    color: _themeService.isDarkMode ? Colors.amber : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bilingual Language Switcher Pill
              InkWell(
                onTap: () {
                  _userService.toggleLanguage();
                  final currentLang = _userService.profile.language;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        currentLang == 'Urdu' ? 'اردو زبان منتخب ہو گئی ہے' : 'Switched to English language',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrdu
                        ? const Color(0xFF10B981).withValues(alpha: 0.18)
                        : (_themeService.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUrdu
                          ? const Color(0xFF10B981)
                          : (_themeService.isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: 13,
                        color: isUrdu ? const Color(0xFF10B981) : (_themeService.isDarkMode ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUrdu ? 'اردو' : 'EN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isUrdu ? const Color(0xFF047857) : (_themeService.isDarkMode ? Colors.white : const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sub-bar (Row 2: Academic Level Badge & Activity Status Pills)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Academic Level Chip
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          profile.academicLevelString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Pills: Streak + Daily AI Quota
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Streak Pill
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BadgesScreen()),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.streakOrangeSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 14,
                            color: AppColors.streakOrange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${profile.currentStreak}d',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Daily AI Quota Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '$remainingQuota AI',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hero AI Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            AppLocale.t('hero_tag', lang),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  AppLocale.t('hero_title', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocale.t('hero_subtitle', lang),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex = 1),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: Text(AppLocale.t('ask_tutor_now', lang)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DocumentChatScreen(autoOpenNewDialog: true)),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                      label: Text(AppLocale.t('upload_notes', lang), style: const TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Study Progress Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDark ? AppColors.primaryDark.withValues(alpha: 0.4) : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocale.t('today_target', lang),
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary),
                          ),
                          Text(
                            '${_plannerService.totalFocusMinutesLogged} / 45m',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_plannerService.totalFocusMinutesLogged / 45).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: _surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PomodoroTimerScreen()),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isDark ? AppColors.primaryDark.withValues(alpha: 0.4) : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          AppLocale.t('focus', lang),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Section Title: Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocale.t('core_modules', lang),
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    AppLocale.t('core_modules_sub', lang),
                    style: TextStyle(fontSize: 11.5, color: _textSecondary),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _currentIndex = 3),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        AppLocale.t('view_all', lang),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grid Action Cards (All FYP Core Modules)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _buildFeatureCard(
                title: isUrdu ? 'دستاویز و نوٹس چیٹ' : 'PDF Notes Chat',
                description: isUrdu ? 'اپنے نوٹس اور سلائیڈز سے سوال جواب' : 'Query lecture slides & notes',
                badgeText: isUrdu ? 'اے آئی دستاویز' : 'AI Document',
                icon: Icons.upload_file_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentChatScreen()),
                ),
              ),
              _buildFeatureCard(
                title: isUrdu ? 'امتحانی کوئزز' : 'Adaptive Quizzes',
                description: isUrdu ? 'ایم سی کیوز اور آن اسپاٹ چیکنگ' : 'MCQs & mocks with anti-cheat',
                badgeText: isUrdu ? 'پروکٹرڈ' : 'Proctored',
                icon: Icons.quiz_rounded,
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _buildFeatureCard(
                title: isUrdu ? 'پڑھائی اینالیٹکس' : 'Study Analytics',
                description: isUrdu ? 'چارٹس اور کارکردگی کی رپورٹ' : 'Charts, accuracy & milestones',
                badgeText: isUrdu ? 'لائیو شماریات' : 'Live Stats',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
              ),
              _buildFeatureCard(
                title: isUrdu ? 'فوکس ٹائمر' : 'Focus Timer',
                description: isUrdu ? '25 منٹ کی توجہ مرکوز پڑھائی' : '25-min Pomodoro deep work',
                badgeText: isUrdu ? 'پروڈکٹیوٹی' : 'Productivity',
                icon: Icons.timer_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PomodoroTimerScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weak Topic Diagnostic Alert Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            'Targeted Revision Needed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Weak Topic',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        primaryWeak != null
                            ? '${primaryWeak.subject}: ${primaryWeak.topic} (${(primaryWeak.accuracy * 100).toStringAsFixed(0)}% acc)'
                            : 'Physics: Rotational Motion (Accuracy: 42%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final topicToPractice = primaryWeak?.topic ?? 'Rotational & Circular Motion';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(initialTopic: topicToPractice),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Practice',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // --- RECENT SAVED NOTES SECTION ---
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Study Notes',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Saved notes & AI summaries in real-time',
                    style: TextStyle(fontSize: 11.5, color: _textSecondary),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentChatScreen(autoOpenNewDialog: true)),
                ),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '+ Add Note',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_docService.documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_add_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No saved notes yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textPrimary),
                        ),
                        Text(
                          'Type or paste your notes to generate AI summaries',
                          style: TextStyle(fontSize: 11.5, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentChatScreen(autoOpenNewDialog: true)),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            )
          else
            ..._docService.documents.take(3).map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_rounded, color: Color(0xFF7C3AED), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${d.totalCharacters} chars • ${(d.byteSize / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(fontSize: 11, color: _textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d.summary,
                      style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(initialTopic: d.name),
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz_rounded, size: 13),
                          label: const Text('Quiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentChatScreen(initialDocId: d.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13),
                          label: const Text('Open Note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required String badgeText,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _isDark ? color.withValues(alpha: 0.18) : bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. STUDY TOOLS HUB TAB (Flashcards, Planner, Timer) ---
  Widget _buildStudyToolsHub() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Smart Study Tools',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Science-backed active recall, scheduling, and deep work intervals',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 20),

          // Tool 1: Spaced Repetition Flashcards
          _buildToolBannerCard(
            title: 'Active Recall Flashcards',
            subtitle: 'SuperMemo SM-2 spaced repetition memory intervals',
            metaBadge: '${_flashcardService.cards.length} Cards in Deck',
            icon: Icons.style_rounded,
            gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            buttonText: 'Open Flashcards Deck',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // Tool 2: Smart Study Planner
          _buildToolBannerCard(
            title: 'Smart Study Planner',
            subtitle: 'Automated exam timetable & syllabus milestone checklist',
            metaBadge: '${_plannerService.activeMilestones.length} Active Milestones',
            icon: Icons.calendar_month_rounded,
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
            buttonText: 'View Study Schedule',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudyPlannerScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // Tool 3: Pomodoro Focus Timer
          _buildToolBannerCard(
            title: 'Pomodoro Focus Timer',
            subtitle: '25/5 interval timer with productivity streaks',
            metaBadge: '${_plannerService.totalFocusMinutesLogged} Mins Logged Today',
            icon: Icons.timer_rounded,
            gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
            buttonText: 'Launch Focus Timer',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroTimerScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBannerCard({
    required String title,
    required String subtitle,
    required String metaBadge,
    required IconData icon,
    required List<Color> gradient,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: gradient.first.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metaBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: gradient.first,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: gradient.first,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // --- 3. PROFILE VIEW ---
  Widget _buildProfileTab(String displayName, String email) {
    final profile = _userService.profile;
    final isUrdu = profile.language == 'Urdu';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: AppColors.primaryGlow(AppColors.primary),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 36,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(fontSize: 13.5, color: _textSecondary),
          ),
          if (profile.phoneNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  profile.phoneNumber,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 48,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDark ? AppColors.primaryDark.withValues(alpha: 0.4) : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isDark ? AppColors.primary : AppColors.primaryBorder),
                ),
                child: Text(
                  profile.academicLevelString,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: profile.isAdmin ? const Color(0xFFFEF2F2) : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: profile.isAdmin ? const Color(0xFFFECACA) : AppColors.successBorder,
                  ),
                ),
                child: Text(
                  profile.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: profile.isAdmin ? AppColors.error : AppColors.successDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // User Stats Card (4 KPIs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: '${profile.currentStreak}d',
                  label: isUrdu ? 'سٹریک' : 'Streak',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.streakOrange,
                ),
                _StatItem(
                  value: '${_quizService.pastAttempts.length}',
                  label: isUrdu ? 'کوئزز' : 'Quizzes',
                  icon: Icons.quiz_rounded,
                  color: AppColors.success,
                ),
                _StatItem(
                  value: '${_quotaService.remainingAiRequests}',
                  label: isUrdu ? 'اے آئی کوٹہ' : 'AI Credits',
                  icon: Icons.bolt_rounded,
                  color: AppColors.primary,
                ),
                _StatItem(
                  value: '${_flashcardService.cards.length}',
                  label: isUrdu ? 'فلیش کارڈز' : 'Flashcards',
                  icon: Icons.style_rounded,
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Action menu items
          _buildMenuTile(
            icon: Icons.edit_note_rounded,
            title: isUrdu ? 'اکیڈمک پروفائل سیٹ اپ' : 'Academic Profile Setup',
            subtitle: profile.academicLevelString,
            color: AppColors.primary,
            onTap: _showEditProfileDialog,
          ),
          _buildMenuTile(
            icon: Icons.language_rounded,
            title: isUrdu ? 'زبان کی ترجیح' : 'Language Preference',
            subtitle: isUrdu
                ? 'موجودہ: اردو (اردو اور انگلش سپورٹ فعال)'
                : 'Current: English (English & Urdu Support)',
            color: AppColors.success,
            onTap: () {
              _userService.toggleLanguage();
              final currentLang = _userService.profile.language;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(currentLang == 'Urdu' ? 'اردو زبان منتخب ہو گئی ہے' : 'Language switched to English'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: _themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: isUrdu ? 'ڈوئل تھیم (لائٹ و ڈارک موڈ)' : 'Dual Theme (Light & Dark Mode)',
            subtitle: _themeService.isDarkMode
                ? (isUrdu ? 'موجودہ: ڈارک تھیم • تبدیل کرنے کے لیے ٹیپ کریں' : 'Current: Dark Theme • Tap to switch')
                : (isUrdu ? 'موجودہ: لائٹ تھیم • تبدیل کرنے کے لیے ٹیپ کریں' : 'Current: Light Theme • Tap to switch'),
            color: Colors.amber.shade700,
            onTap: () {
              _themeService.toggleTheme();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _themeService.isDarkMode
                        ? (isUrdu ? 'ڈارک تھیم فعال ہو گئی' : 'Dark Theme Enabled')
                        : (isUrdu ? 'لائٹ تھیم فعال ہو گئی' : 'Light Theme Enabled'),
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.history_rounded,
            title: isUrdu ? 'ماضی کی ہسٹری اور پی ڈی ایف ایکسپورٹ' : 'Academic History & Study Notes Export',
            subtitle: isUrdu ? 'سابقہ کوئزز، سمریز اور نوٹس ایکسپورٹ' : 'Past mock quizzes, notes summaries & PDF export',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          _buildMenuTile(
            icon: Icons.military_tech_rounded,
            title: isUrdu ? 'بیجز اور سٹریکس' : 'Achievements & Badges',
            subtitle: isUrdu ? '${profile.earnedBadges.length} انعامات و بیجز کھلے ہیں' : '${profile.earnedBadges.length} Badges unlocked • View rewards',
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
          ),


          const SizedBox(height: 14),

          // Sign Out Tile
          ListTile(
            onTap: _confirmLogout,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
            ),
            tileColor: _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: Text(
              isUrdu ? 'اکاؤنٹ لاگ آؤٹ کریں' : 'Sign Out Account',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: _textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      ),
    );
  }

  // --- MODERN FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildModernBottomNav() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen && _currentIndex == 1) {
      return const SizedBox.shrink();
    }
    final isUrdu = _userService.profile.language == 'Urdu';
    final navItems = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, isUrdu ? 'ڈیش بورڈ' : 'Home'),
      (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, isUrdu ? 'اے آئی ٹیوٹر' : 'AI Tutor'),
      (Icons.quiz_outlined, Icons.quiz_rounded, isUrdu ? 'کوئز ٹیسٹ' : 'Quizzes'),
      (Icons.timer_outlined, Icons.timer_rounded, isUrdu ? 'اسٹڈی ٹولز' : 'Tools'),
      (Icons.person_outline_rounded, Icons.person_rounded, isUrdu ? 'پروفائل' : 'Profile'),
    ];

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 2),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: _isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(navItems.length, (index) {
            final isSelected = _currentIndex == index;
            final item = navItems[index];
            return Expanded(
              flex: isSelected ? 3 : 2,
              child: InkWell(
                onTap: () => setState(() => _currentIndex = index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isDark ? AppColors.primary.withValues(alpha: 0.25) : AppColors.primarySoft)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.$2 : item.$1,
                        color: isSelected
                            ? (_isDark ? AppColors.primaryLight : AppColors.primary)
                            : (_isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                        size: 20,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isDark ? AppColors.primaryLight : AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

