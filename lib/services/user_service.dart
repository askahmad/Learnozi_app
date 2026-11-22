import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserProfile _currentProfile = UserProfile(
    id: 'user_101',
    name: 'Muhammad Ahmad',
    email: 'ahmad@learnozi.pk',
    phoneNumber: '',
    educationType: EducationType.university,
    schoolGrade: '',
    schoolCourse: '',
    universityName: 'Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan',
    semester: '6th Semester',
    program: 'BS Computer Science (BSCS)',
    role: 'student',
    currentStreak: 1,
    longestStreak: 1,
    lastActiveDate: DateTime.now(),
    language: 'English',
    earnedBadges: ['first_step'],
  );

  UserProfile get profile => _currentProfile;

  void setNewProfile({
    required String name,
    required String email,
    String? phoneNumber,
    required EducationType educationType,
    String? schoolGrade,
    String? schoolCourse,
    String? universityName,
    String? semester,
    String? program,
    String role = 'student',
    String language = 'English',
  }) {
    _currentProfile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phoneNumber: phoneNumber ?? '',
      educationType: educationType,
      schoolGrade: schoolGrade ?? '',
      schoolCourse: schoolCourse ?? '',
      universityName: universityName ?? '',
      semester: semester ?? '',
      program: program ?? '',
      role: role,
      currentStreak: 1,
      longestStreak: 1,
      lastActiveDate: DateTime.now(),
      language: language,
      earnedBadges: ['first_step'],
    );
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
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
    if (email != null) _currentProfile.email = email;
    if (phoneNumber != null) _currentProfile.phoneNumber = phoneNumber;
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
