import 'dart:async';
import 'package:flutter/material.dart';
import '../services/study_planner_service.dart';

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  final _plannerService = StudyPlannerService();

  final int _focusMinutes = 25;
  final int _breakMinutes = 5;
  bool _isBreak = false;
  bool _isRunning = false;
  late int _remainingSeconds;
  Timer? _timer;

  String _selectedSubject = 'Physics';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _focusMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _isRunning = false;
        _handleSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = (_isBreak ? _breakMinutes : _focusMinutes) * 60;
    });
  }

  void _skipToNext() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = !_isBreak;
      _remainingSeconds = (_isBreak ? _breakMinutes : _focusMinutes) * 60;
    });
  }

  void _handleSessionComplete() {
    if (!_isBreak) {
      // Completed focus session -> Log it!
      _plannerService.logFocusSession(
        subject: _selectedSubject,
        durationMinutes: _focusMinutes,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Focus Session Done!'),
            ],
          ),
          content: Text(
            '$_focusMinutes minutes logged for $_selectedSubject! Your daily streak has been incremented. Time for a $_breakMinutes minute break.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _skipToNext();
                _startTimer();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Start Break', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Break Finished'),
          content: const Text('Ready to dive back into deep focus study?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _skipToNext();
              },
              child: const Text('Next Focus Block'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final totalSecs = (_isBreak ? _breakMinutes : _focusMinutes) * 60;
    final progress = totalSecs > 0 ? (totalSecs - _remainingSeconds) / totalSecs : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pomodoro Focus Timer',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Deep work & productivity streaks (FR-08)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode Indicator Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isBreak ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _isBreak ? const Color(0xFFA7F3D0) : const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isBreak ? Icons.coffee_rounded : Icons.local_fire_department_rounded,
                    color: _isBreak ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isBreak ? 'Rest & Refresh (${_breakMinutes}m)' : 'Deep Focus (${_focusMinutes}m)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _isBreak ? const Color(0xFF065F46) : const Color(0xFF3730A3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Big Circular Countdown Clock
            Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: _isBreak ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          _isRunning ? 'FOCUSING' : 'PAUSED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: _isRunning ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Subject Selector Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  isExpanded: true,
                  items: ['Physics', 'Chemistry', 'Computer Science', 'Biology', 'Mathematics']
                      .map((s) => DropdownMenuItem(value: s, child: Text('Subject: $s')))
                      .toList(),
                  onChanged: _isRunning ? null : (val) => setState(() => _selectedSubject = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Play / Pause / Reset Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.replay_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 18),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                  label: Text(_isRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(width: 18),
                IconButton.filled(
                  icon: const Icon(Icons.skip_next_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: _skipToNext,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Total Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Focus Time', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                        '${_plannerService.totalFocusMinutesLogged} Mins',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Sessions Logged', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                        '${_plannerService.focusSessions.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
