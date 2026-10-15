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
}
