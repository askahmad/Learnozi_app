import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final UserProfile _currentProfile = UserProfile(
    id: 'user_101',
    name: 'Muhammad Ahmad',
    email: 'ahmad@learnozi.pk',
    educationType: EducationType.school,
    schoolGrade: '11th (FSc Part 1)',
    schoolCourse: 'Pre-Medical',
    universityName: 'Virtual University',
    semester: 'Semester 4',
    program: 'BS Computer Science',
    role: 'student',
    currentStreak: 3,
    longestStreak: 7,
    lastActiveDate: DateTime.now(),
    language: 'English',
    earnedBadges: ['first_step', 'quiz_apprentice', 'streak_starter'],
  );

  UserProfile get profile => _currentProfile;

  void updateProfile({
    String? name,
    EducationType? educationType,
    String? schoolGrade,
    String? schoolCourse,
    String? universityName,
    String? semester,
    String? program,
    String? role,
    String? language,
  }) {
    if (name != null) _currentProfile.name = name;
    if (educationType != null) _currentProfile.educationType = educationType;
    if (schoolGrade != null) _currentProfile.schoolGrade = schoolGrade;
    if (schoolCourse != null) _currentProfile.schoolCourse = schoolCourse;
    if (universityName != null) _currentProfile.universityName = universityName;
    if (semester != null) _currentProfile.semester = semester;
    if (program != null) _currentProfile.program = program;
    if (role != null) _currentProfile.role = role;
    if (language != null) _currentProfile.language = language;
    notifyListeners();
  }

  void incrementStreak() {
    _currentProfile.currentStreak += 1;
    if (_currentProfile.currentStreak > _currentProfile.longestStreak) {
      _currentProfile.longestStreak = _currentProfile.currentStreak;
    }
    _currentProfile.lastActiveDate = DateTime.now();
    notifyListeners();
  }

  void unlockBadge(String badgeId) {
    if (!_currentProfile.earnedBadges.contains(badgeId)) {
      _currentProfile.earnedBadges.add(badgeId);
      notifyListeners();
    }
  }

  void toggleAdminRole() {
    _currentProfile.role = (_currentProfile.role == 'admin') ? 'student' : 'admin';
    notifyListeners();
  }

  void toggleLanguage() {
    _currentProfile.language = (_currentProfile.language == 'English') ? 'Urdu' : 'English';
    notifyListeners();
  }
}
