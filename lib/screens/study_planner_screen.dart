import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../services/study_planner_service.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final _plannerService = StudyPlannerService();

  void _showNewPlanDialog() {
    final subjectController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    int dailyMins = 60;

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
                  const Text('Create Smart Study Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Input your exam date and daily minutes; Learnozi breaks your syllabus into daily milestones.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject / Exam Name',
                      hintText: 'e.g. Physics Board Exam 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_rounded),
                          label: Text('Exam: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daily Study Goal:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$dailyMins minutes / day', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: dailyMins.toDouble(),
                    min: 20,
                    max: 180,
                    divisions: 16,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setModalState(() => dailyMins = val.round()),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      final subject = subjectController.text.trim();
                      if (subject.isEmpty) return;

                      _plannerService.createStudyPlan(
                        subject: subject,
                        examDate: selectedDate,
                        dailyMinutes: dailyMins,
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
                    child: const Text('Generate Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final plans = _plannerService.plans;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Study Planner',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Timetable & Milestone Scheduler (FR-07)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5)),
            onPressed: _showNewPlanDialog,
          ),
        ],
      ),
      body: plans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_rounded, size: 54, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text('No Study Plans Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showNewPlanDialog,
                    child: const Text('Create Exam Study Plan'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: plans.length,
              itemBuilder: (context, i) => _buildPlanCard(plans[i]),
            ),
    );
  }

  Widget _buildPlanCard(StudyPlan plan) {
    final progress = plan.progressPercentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.subject,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${plan.daysRemaining} days left',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Milestones: ${plan.completedTasksCount}/${plan.tasks.length} Done',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(6),
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dynamic Syllabus Tasks:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          ...plan.tasks.map(
            (task) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: task.isCompleted,
              activeColor: const Color(0xFF4F46E5),
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'Due: ${task.dueDate.day}/${task.dueDate.month} • ${task.minutesEstimated} mins',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              onChanged: (_) {
                setState(() {
                  _plannerService.toggleTaskCompletion(plan.id, task.id);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
