enum EducationType { school, university }

class UserProfile {
  final String id;
  String name;
  String email;
  EducationType educationType;
  
  // School fields
  String schoolGrade; // '9th', '10th', '11th', '12th'
  String schoolCourse; // 'Pre-Medical', 'Pre-Engineering', 'Computer Science', 'Commerce'
  
  // University fields
  String universityName;
  String semester;
  String program; // 'BSCS', 'BBA', 'MBBS', 'BEE', etc.

  String role; // 'student' or 'admin'
  int currentStreak;
  int longestStreak;
  DateTime lastActiveDate;
  String language; // 'English' or 'Urdu'
  List<String> earnedBadges;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.educationType = EducationType.school,
    this.schoolGrade = '11th (FSc Part 1)',
    this.schoolCourse = 'Pre-Medical',
    this.universityName = 'Virtual / Punjab University',
    this.semester = 'Semester 4',
    this.program = 'BS Computer Science',
    this.role = 'student',
    this.currentStreak = 3,
    this.longestStreak = 5,
    DateTime? lastActiveDate,
    this.language = 'English',
    List<String>? earnedBadges,
  })  : lastActiveDate = lastActiveDate ?? DateTime.now(),
        earnedBadges = earnedBadges ?? ['first_step', 'quiz_apprentice'];

  String get academicLevelString {
    if (educationType == EducationType.school) {
      return '$schoolGrade • $schoolCourse';
    } else {
      return '$program ($semester) • $universityName';
    }
  }

  bool get isAdmin => role == 'admin';
}
