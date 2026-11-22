enum EducationType { school, university }

class UserProfile {
  final String id;
  String name;
  String email;
  String phoneNumber;
  EducationType educationType;
  
  // School fields
  String schoolGrade; 
  String schoolCourse; 
  
  // University fields
  String universityName;
  String semester;
  String program; 

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
    this.phoneNumber = '',
    this.educationType = EducationType.university,
    this.schoolGrade = '',
    this.schoolCourse = '',
    this.universityName = 'Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan',
    this.semester = '',
    this.program = 'BS Computer Science (BSCS)',
    this.role = 'student',
    this.currentStreak = 1,
    this.longestStreak = 1,
    DateTime? lastActiveDate,
    this.language = 'English',
    List<String>? earnedBadges,
  })  : lastActiveDate = lastActiveDate ?? DateTime.now(),
        earnedBadges = earnedBadges ?? ['first_step'];

  String get academicLevelString {
    if (educationType == EducationType.school) {
      if (schoolGrade.isNotEmpty && schoolCourse.isNotEmpty) {
        return '$schoolGrade • $schoolCourse';
      } else if (schoolGrade.isNotEmpty) {
        return schoolGrade;
      } else if (schoolCourse.isNotEmpty) {
        return schoolCourse;
      } else {
        return 'School / College Student';
      }
    } else {
      final parts = <String>[];
      if (program.isNotEmpty) parts.add(program);
      if (semester.isNotEmpty) parts.add(semester);
      final programAndSem = parts.join(' - ');
      
      if (programAndSem.isNotEmpty && universityName.isNotEmpty) {
        return '$programAndSem • $universityName';
      } else if (programAndSem.isNotEmpty) {
        return programAndSem;
      } else if (universityName.isNotEmpty) {
        return universityName;
      } else {
        return 'University Student';
      }
    }
  }

  bool get isAdmin => role == 'admin';

  // Constants for Pakistani Education System
  static const List<String> pakistaniUniversities = [
    'Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan',
    'NUST - National University of Sciences & Technology, Islamabad',
    'FAST - NUCES (National University of Computer & Emerging Sciences)',
    'COMSATS University Islamabad (CUI)',
    'LUMS - Lahore University of Management Sciences',
    'University of the Punjab (PU), Lahore',
    'UET Lahore - University of Engineering & Technology',
    'UET Taxila',
    'Quaid-i-Azam University (QAU), Islamabad',
    'GIKI - Ghulam Ishaq Khan Institute, Topi',
    'Virtual University of Pakistan (VU)',
    'Allama Iqbal Open University (AIOU)',
    'Bahria University, Islamabad',
    'Air University, Islamabad',
    'IBA - Institute of Business Administration, Karachi',
    'NED University of Engineering & Technology, Karachi',
    'University of Karachi (UoK)',
    'Bahauddin Zakariya University (BZU), Multan',
    'The Islamia University of Bahawalpur (IUB)',
    'Government College University (GCU), Lahore',
    'University of Agriculture Faisalabad (UAF)',
    'University of Gujrat (UOG)',
    'Mehran University of Engineering & Technology (MUET), Jamshoro',
    'University of Peshawar (UoP)',
    'Rawalpindi Medical University (RMU)',
    'King Edward Medical University (KEMU), Lahore',
    'Other (Type your own University)',
  ];

  static const List<String> universityPrograms = [
    'BS Computer Science (BSCS)',
    'BS Software Engineering (BSSE)',
    'BS Information Technology (BSIT)',
    'BS Artificial Intelligence (BSAI)',
    'BS Data Science (BSDS)',
    'BS Cyber Security',
    'BBA - Bachelor of Business Administration',
    'BS Electrical Engineering (BSEE)',
    'BS Mechanical Engineering (BSME)',
    'BS Civil Engineering (BSCE)',
    'BS Mathematics',
    'BS Physics',
    'BS Chemistry',
    'BS English Literature & Linguistics',
    'BS Economics',
    'BS Accounting & Finance (BSAF)',
    'MBBS / BDS / Medical Sciences',
    'Pharm-D (Doctor of Pharmacy)',
    'DPT (Doctor of Physical Therapy)',
    'LLB - Law',
    'Other (Type your own Degree / Program)',
  ];

  static const List<String> universitySemesters = [
    'None / Not Applicable',
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
    'Graduated / Alumni',
    'Other (Type Semester)',
  ];

  static const List<String> schoolGrades = [
    '9th Class (Matric Part 1)',
    '10th Class (Matric Part 2)',
    '11th Class (FSc / ICS Part 1)',
    '12th Class (FSc / ICS Part 2)',
    'O-Levels',
    'A-Levels',
    'Other (Type Grade)',
  ];

  static const List<String> schoolTracks = [
    'Pre-Medical',
    'Pre-Engineering',
    'Computer Science (ICS)',
    'General Science',
    'Commerce (I.Com)',
    'Arts / Humanities (FA)',
    'Other (Type Track)',
  ];

  static const List<String> academicSubjects = [
    // Sciences
    'Physics',
    'Chemistry',
    'Biology',
    'Biochemistry',

    // Mathematics & Computing
    'Mathematics',
    'Calculus & Analytical Geometry',
    'Linear Algebra',
    'Probability & Statistics',
    'Computer Science',
    'Software Engineering',
    'Programming Fundamentals (C++ / Python / Java)',
    'Data Structures & Algorithms (DSA)',
    'Object Oriented Programming (OOP)',
    'Database Systems (SQL / DBMS)',
    'Operating Systems',
    'Computer Networks',
    'Artificial Intelligence (AI & ML)',
    'Web Development',
    'Cyber Security',
    'Compiler Construction',
    'Computer Architecture',

    // Humanities & Social Sciences
    'English Language & Literature',
    'Islamic Studies',
    'Pakistan Studies',
    'Economics',
    'Accounting & Finance',
    'Business Administration & Management',
    'Psychology',
    'Sociology',
    'Law / Jurisprudence',

    // Custom Subject
    'Other (Type Custom Subject)',
  ];
}
