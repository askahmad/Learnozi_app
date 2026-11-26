class StudyTask {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final int minutesEstimated;
  bool isCompleted;

  StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.minutesEstimated,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'dueDate': dueDate.toIso8601String(),
    'minutesEstimated': minutesEstimated,
    'isCompleted': isCompleted,
  };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    subject: json['subject'] ?? '',
    dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
    minutesEstimated: (json['minutesEstimated'] as num?)?.toInt() ?? 30,
    isCompleted: json['isCompleted'] ?? false,
  );
}

class StudyPlan {
  final String id;
  final String subject;
  final DateTime examDate;
  final int dailyMinutes;
  final List<StudyTask> tasks;

  StudyPlan({
    required this.id,
    required this.subject,
    required this.examDate,
    required this.dailyMinutes,
    required this.tasks,
  });

  int get daysRemaining => examDate.difference(DateTime.now()).inDays;
  int get completedTasksCount => tasks.where((t) => t.isCompleted).length;
  double get progressPercentage => tasks.isEmpty ? 0.0 : (completedTasksCount / tasks.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'examDate': examDate.toIso8601String(),
    'dailyMinutes': dailyMinutes,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
    id: json['id'] ?? '',
    subject: json['subject'] ?? '',
    examDate: DateTime.tryParse(json['examDate'] ?? '') ?? DateTime.now(),
    dailyMinutes: (json['dailyMinutes'] as num?)?.toInt() ?? 45,
    tasks: (json['tasks'] as List?)
            ?.map((t) => StudyTask.fromJson(Map<String, dynamic>.from(t)))
            .toList() ??
        [],
  );
}

class FocusSession {
  final String id;
  final String subject;
  final int durationMinutes;
  final DateTime timestamp;

  FocusSession({
    required this.id,
    required this.subject,
    required this.durationMinutes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'durationMinutes': durationMinutes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'] ?? '',
    subject: json['subject'] ?? '',
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 25,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}
