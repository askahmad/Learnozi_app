import 'package:flutter/foundation.dart';
import '../models/study_plan_model.dart';
import 'user_service.dart';

class StudyPlannerService extends ChangeNotifier {
  static final StudyPlannerService _instance = StudyPlannerService._internal();
  factory StudyPlannerService() => _instance;
  StudyPlannerService._internal() {
    _initSamplePlan();
  }

  final List<StudyPlan> _plans = [];
  List<StudyPlan> get plans => List.unmodifiable(_plans);

  final List<FocusSession> _focusSessions = [];
  List<FocusSession> get focusSessions => List.unmodifiable(_focusSessions);

  int get totalFocusMinutesLogged =>
      _focusSessions.fold(0, (sum, item) => sum + item.durationMinutes);

  void _initSamplePlan() {
    final now = DateTime.now();
    _plans.add(
      StudyPlan(
        id: 'plan_1',
        subject: 'Physics (Board / Entry Test)',
        examDate: now.add(const Duration(days: 28)),
        dailyMinutes: 60,
        tasks: [
          StudyTask(
            id: 't1',
            title: 'Revise Angular Momentum & Torque derivations',
            subject: 'Physics',
            dueDate: now,
            minutesEstimated: 30,
            isCompleted: true,
          ),
          StudyTask(
            id: 't2',
            title: 'Attempt 10 MCQs on Work & Energy',
            subject: 'Physics',
            dueDate: now,
            minutesEstimated: 25,
            isCompleted: false,
          ),
          StudyTask(
            id: 't3',
            title: 'Review Chapter 6 Fluid Dynamics past papers',
            subject: 'Physics',
            dueDate: now.add(const Duration(days: 2)),
            minutesEstimated: 45,
            isCompleted: false,
          ),
          StudyTask(
            id: 't4',
            title: 'Milestone Mock Exam: Mechanics & Thermodynamics',
            subject: 'Physics',
            dueDate: now.add(const Duration(days: 7)),
            minutesEstimated: 60,
            isCompleted: false,
          ),
        ],
      ),
    );

    _plans.add(
      StudyPlan(
        id: 'plan_2',
        subject: 'Computer Science (Data Structures)',
        examDate: now.add(const Duration(days: 14)),
        dailyMinutes: 45,
        tasks: [
          StudyTask(
            id: 't5',
            title: 'Implement Binary Search & Bubble Sort in code',
            subject: 'Computer Science',
            dueDate: now,
            minutesEstimated: 40,
            isCompleted: true,
          ),
          StudyTask(
            id: 't6',
            title: 'Solve recursion stack trace problems',
            subject: 'Computer Science',
            dueDate: now.add(const Duration(days: 1)),
            minutesEstimated: 35,
            isCompleted: false,
          ),
        ],
      ),
    );

    // Initial focus sessions
    _focusSessions.addAll([
      FocusSession(
        id: 'fs_1',
        subject: 'Physics',
        durationMinutes: 25,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      FocusSession(
        id: 'fs_2',
        subject: 'Computer Science',
        durationMinutes: 25,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      FocusSession(
        id: 'fs_3',
        subject: 'Physics',
        durationMinutes: 25,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  void toggleTaskCompletion(String planId, String taskId) {
    for (final plan in _plans) {
      if (plan.id == planId) {
        for (final task in plan.tasks) {
          if (task.id == taskId) {
            task.isCompleted = !task.isCompleted;
            if (task.isCompleted) {
              UserService().incrementStreak();
            }
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void createStudyPlan({
    required String subject,
    required DateTime examDate,
    required int dailyMinutes,
  }) {
    final days = examDate.difference(DateTime.now()).inDays.clamp(1, 365);
    final tasks = <StudyTask>[];

    tasks.add(
      StudyTask(
        id: 't_${DateTime.now().millisecondsSinceEpoch}_1',
        title: 'Core syllabus review & chapter breakdown',
        subject: subject,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        minutesEstimated: dailyMinutes,
      ),
    );
    tasks.add(
      StudyTask(
        id: 't_${DateTime.now().millisecondsSinceEpoch}_2',
        title: 'High-frequency exam questions practice',
        subject: subject,
        dueDate: DateTime.now().add(Duration(days: (days / 2).round().clamp(2, 60))),
        minutesEstimated: dailyMinutes,
      ),
    );
    tasks.add(
      StudyTask(
        id: 't_${DateTime.now().millisecondsSinceEpoch}_3',
        title: 'Final comprehensive mock exam & revision',
        subject: subject,
        dueDate: examDate.subtract(const Duration(days: 1)),
        minutesEstimated: dailyMinutes * 2,
      ),
    );

    _plans.add(
      StudyPlan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        examDate: examDate,
        dailyMinutes: dailyMinutes,
        tasks: tasks,
      ),
    );
    notifyListeners();
  }

  void logFocusSession({
    required String subject,
    required int durationMinutes,
  }) {
    _focusSessions.insert(
      0,
      FocusSession(
        id: 'fs_${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        durationMinutes: durationMinutes,
        timestamp: DateTime.now(),
      ),
    );

    // Productivity streak & badge unlock (FR-08, FR-15)
    UserService().incrementStreak();
    if (_focusSessions.length >= 5) {
      UserService().unlockBadge('focus_scholar');
    }

    notifyListeners();
  }
}
