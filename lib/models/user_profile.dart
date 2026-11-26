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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phoneNumber': phoneNumber,
    'educationType': educationType.name,
    'schoolGrade': schoolGrade,
    'schoolCourse': schoolCourse,
    'universityName': universityName,
    'semester': semester,
    'program': program,
    'role': role,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate.toIso8601String(),
    'language': language,
    'earnedBadges': earnedBadges,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? 'user_101',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    educationType: json['educationType'] == 'school'
        ? EducationType.school
        : EducationType.university,
    schoolGrade: json['schoolGrade'] ?? '',
    schoolCourse: json['schoolCourse'] ?? '',
    universityName: json['universityName'] ?? '',
    semester: json['semester'] ?? '',
    program: json['program'] ?? '',
    role: json['role'] ?? 'student',
    currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 1,
    longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 1,
    lastActiveDate:
        DateTime.tryParse(json['lastActiveDate'] ?? '') ?? DateTime.now(),
    language: json['language'] ?? 'English',
    earnedBadges: (json['earnedBadges'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['first_step'],
  );

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

  /// Returns recommended subjects tailored to the student's exact department, program, or school stream.
  List<String> get recommendedSubjects {
    if (educationType == EducationType.school) {
      final track = schoolCourse.toLowerCase();
      final grade = schoolGrade.toLowerCase();
      if (track.contains('medical')) {
        return ['Biology', 'Chemistry', 'Physics', 'English', 'Urdu / Pak Studies'];
      } else if (track.contains('engineering')) {
        return ['Mathematics', 'Physics', 'Chemistry', 'English', 'Urdu / Pak Studies'];
      } else if (track.contains('computer') || track.contains('ics')) {
        return ['Computer Science', 'Mathematics', 'Physics', 'Statistics', 'English'];
      } else if (track.contains('commerce') || track.contains('i.com')) {
        return ['Accounting & Finance', 'Principles of Commerce', 'Economics', 'Business Math'];
      } else if (grade.contains('9th') || grade.contains('10th') || grade.contains('matric')) {
        return ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Computer Science', 'English'];
      } else {
        return ['General Science', 'Mathematics', 'English', 'Pakistan Studies', 'Islamic Studies'];
      }
    } else {
      final p = program.toLowerCase();
      if (p.contains('computer') ||
          p.contains('software') ||
          p.contains('it') ||
          p.contains('ai') ||
          p.contains('data science') ||
          p.contains('cyber')) {
        return [
          'Programming Fundamentals (C++ / Python / Java)',
          'Object Oriented Programming (OOP)',
          'Data Structures & Algorithms (DSA)',
          'Database Systems (SQL / DBMS)',
          'Operating Systems',
          'Computer Networks',
          'Artificial Intelligence (AI & ML)',
          'Software Engineering',
        ];
      } else if (p.contains('business') ||
          p.contains('bba') ||
          p.contains('accounting') ||
          p.contains('finance') ||
          p.contains('economics')) {
        return [
          'Accounting & Finance',
          'Business Administration & Management',
          'Economics',
          'Financial Accounting',
          'Marketing Management',
          'Business Mathematics & Statistics',
        ];
      } else if (p.contains('medical') ||
          p.contains('mbbs') ||
          p.contains('pharm') ||
          p.contains('dpt')) {
        return [
          'Human Anatomy & Histology',
          'Physiology & Biochemistry',
          'Pathology & Microbiology',
          'Pharmacology & Therapeutics',
          'Forensic Medicine',
          'Clinical Medicine',
        ];
      } else if (p.contains('engineering') ||
          p.contains('electrical') ||
          p.contains('mechanical') ||
          p.contains('civil')) {
        return [
          'Calculus & Analytical Geometry',
          'Linear Algebra & Differential Equations',
          'Circuit Analysis / Mechanics',
          'Thermodynamics / Fluid Mechanics',
          'Engineering Physics',
          'Digital Logic Design',
        ];
      } else if (p.contains('law') || p.contains('llb')) {
        return [
          'Constitutional Law of Pakistan',
          'Jurisprudence & Legal Theory',
          'Pakistan Penal Code (PPC)',
          'Law of Torts & Contracts',
          'Criminal Procedure Code (CrPC)',
        ];
      } else {
        return academicSubjects.sublist(0, 8);
      }
    }
  }
}
