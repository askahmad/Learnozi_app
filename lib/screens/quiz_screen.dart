import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/user_service.dart';
import '../services/adaptive_service.dart';
import '../utils/app_colors.dart';

class QuizScreen extends StatefulWidget {
  final String? initialTopic;
  const QuizScreen({super.key, this.initialTopic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizService = QuizService();
  final _userService = UserService();
  final _adaptiveService = AdaptiveService();

  // Active quiz session state
  bool _isQuizActive = false;
  bool _isLoading = false;
  List<QuizQuestion> _currentQuestions = [];
  int _currentIndex = 0;
  bool _isAnswerSubmitted = false;
  String? _selectedMcqOption;
  final _writtenAnswerController = TextEditingController();
  bool _isGradingAnswer = false;

  // Quiz Setup Config
  final _topicController = TextEditingController(text: 'Rotational & Circular Motion');
  String _selectedSubject = 'Physics';
  String _selectedQuizType = 'mcq'; // 'mcq', 'short', 'long', 'mixed'
  final int _questionCount = 4;
  bool _focusWeakTopics = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null && widget.initialTopic!.isNotEmpty) {
      _topicController.text = widget.initialTopic!;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _writtenAnswerController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isQuizActive = false;
    });

    final weakTopicNames = _focusWeakTopics
        ? _adaptiveService.weakTopics.map((t) => t.topic).toList()
        : <String>[];

    try {
      final questions = await _quizService.generateQuiz(
        topic: topic,
        subject: _selectedSubject,
        studentLevel: _userService.profile.academicLevelString,
        quizType: _selectedQuizType,
        count: _questionCount,
        weakTopics: weakTopicNames,
      );

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate questions. Please try again.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _currentQuestions = questions;
        _currentIndex = 0;
        _isQuizActive = true;
        _isLoading = false;
        _isAnswerSubmitted = false;
        _selectedMcqOption = null;
        _writtenAnswerController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Anti-Cheat Navigation Guard (FR-04)
  Future<bool> _handleAntiCheatExit() async {
    if (!_isQuizActive) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Anti-Cheat Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Leaving or switching screens mid-test will immediately terminate your attempt with 0 marks according to examination security protocols. Are you sure you want to quit?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Terminate Quiz', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      // Record terminated attempt
      _quizService.saveQuizAttempt(
        QuizAttempt(
          id: 'term_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_topicController.text.trim()} (Terminated)',
          subject: _selectedSubject,
          topic: _topicController.text.trim(),
          questions: _currentQuestions,
          timestamp: DateTime.now(),
          isTerminated: true,
          scorePercent: 0.0,
        ),
      );
      setState(() => _isQuizActive = false);
      return true;
    }

    return false;
  }

  void _submitMcqAnswer(String selectedOption) {
    if (_isAnswerSubmitted) return;
    final currentQ = _currentQuestions[_currentIndex];

    currentQ.studentAnswer = selectedOption;
    // Check if correct (case-insensitive substring match or exact option check)
    final isCorrect = selectedOption.trim().toLowerCase() == currentQ.correctAnswer.trim().toLowerCase() ||
        selectedOption.startsWith(currentQ.correctAnswer.split(')').first);

    currentQ.score = isCorrect ? 1.0 : 0.0;
    currentQ.aiFeedback = isCorrect ? 'Correct! Well done.' : 'Incorrect. See explanation below.';

    setState(() {
      _selectedMcqOption = selectedOption;
      _isAnswerSubmitted = true;
    });
  }

  Future<void> _submitWrittenAnswer() async {
    final studentAns = _writtenAnswerController.text.trim();
    if (studentAns.isEmpty || _isAnswerSubmitted) return;

    final currentQ = _currentQuestions[_currentIndex];
    currentQ.studentAnswer = studentAns;

    setState(() => _isGradingAnswer = true);

    final gradingResult = await _quizService.gradeWrittenAnswer(
      question: currentQ.question,
      modelAnswer: currentQ.correctAnswer,
      studentAnswer: studentAns,
    );

    if (!mounted) return;

    setState(() {
      currentQ.score = (gradingResult['score'] as double?) ?? 0.7;
      currentQ.aiFeedback = gradingResult['feedback'] as String?;
      _isGradingAnswer = false;
      _isAnswerSubmitted = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswerSubmitted = false;
        _selectedMcqOption = null;
        _writtenAnswerController.clear();
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final total = _currentQuestions.length;
    final totalScore = _currentQuestions.fold<double>(0.0, (sum, q) => sum + q.score);
    final scorePercent = total > 0 ? (totalScore / total) * 100 : 0.0;

    final attempt = QuizAttempt(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: '${_topicController.text.trim()} Test',
      subject: _selectedSubject,
      topic: _topicController.text.trim(),
      questions: _currentQuestions,
      timestamp: DateTime.now(),
      scorePercent: scorePercent,
    );

    _quizService.saveQuizAttempt(attempt);

    // Gamification check: Quiz Master badge (FR-15)
    if (scorePercent >= 60.0) {
      _userService.unlockBadge('quiz_master');
      _userService.incrementStreak();
    }

    _showResultDialog(attempt, scorePercent);
  }

  void _showResultDialog(QuizAttempt attempt, double percent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: percent >= 60 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                percent >= 60 ? Icons.emoji_events_rounded : Icons.replay_rounded,
                color: percent >= 60 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              percent >= 60 ? 'Assessment Passed! 🎉' : 'Needs Practice',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'You scored ${percent.toStringAsFixed(1)}% on ${_topicController.text.trim()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Questions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${attempt.totalQuestions}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Correct', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${attempt.correctCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF10B981))),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4F46E5))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isQuizActive = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Quiz Hub', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_isQuizActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isQuizActive) {
          _handleAntiCheatExit();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          elevation: 0,
          leading: _isQuizActive
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
                  onPressed: _handleAntiCheatExit,
                )
              : null,
          title: Text(
            _isQuizActive ? 'Exam in Progress' : 'AI Quiz & Assessment Generator',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            if (_isQuizActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: Color(0xFFEF4444)),
                    SizedBox(width: 4),
                    Text(
                      'Anti-Cheat Active',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    SizedBox(height: 16),
                    Text(
                      'Generating tailored exam questions with Gemini AI...',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              )
            : _isQuizActive
                ? _buildActiveQuizBody()
                : _buildQuizSetupBody(),
      ),
    );
  }

  Widget _buildActiveQuizBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _currentQuestions[_currentIndex];
    final total = _currentQuestions.length;
    final progress = (_currentIndex + 1) / total;

    return Column(
      children: [
        // Top Progress Bar (FR-04)
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          color: const Color(0xFF4F46E5),
          minHeight: 5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  q.type.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
        ),

        // Question Details & Interactive Answer Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    q.question,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // If MCQ -> Options
                if (q.type == QuestionType.mcq && q.options.isNotEmpty)
                  ...q.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final opt = entry.value;
                    final optionLetter = String.fromCharCode(65 + index);
                    final isSelected = _selectedMcqOption == opt;
                    final isCorrect = opt.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase() ||
                        opt.startsWith(q.correctAnswer.split(')').first);

                    Color bgColor = isDark ? AppColors.darkSurface : Colors.white;
                    Color borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
                    Color textColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B);
                    Color pillBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);
                    Color pillText = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

                    if (_isAnswerSubmitted) {
                      if (isCorrect) {
                        bgColor = const Color(0xFFECFDF5);
                        borderColor = const Color(0xFF10B981);
                        textColor = const Color(0xFF065F46);
                        pillBg = const Color(0xFF10B981);
                        pillText = Colors.white;
                      } else if (isSelected) {
                        bgColor = const Color(0xFFFEF2F2);
                        borderColor = const Color(0xFFEF4444);
                        textColor = const Color(0xFF991B1B);
                        pillBg = const Color(0xFFEF4444);
                        pillText = Colors.white;
                      }
                    } else if (isSelected) {
                      bgColor = const Color(0xFFEEF2FF);
                      borderColor = const Color(0xFF4F46E5);
                      textColor = const Color(0xFF4F46E5);
                      pillBg = const Color(0xFF4F46E5);
                      pillText = Colors.white;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _isAnswerSubmitted ? null : () => _submitMcqAnswer(opt),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: pillText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: textColor),
                                ),
                              ),
                              if (_isAnswerSubmitted && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                              if (_isAnswerSubmitted && isSelected && !isCorrect)
                                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                // If Short / Long -> Written Input
                else ...[
                  TextField(
                    controller: _writtenAnswerController,
                    maxLines: 4,
                    enabled: !_isAnswerSubmitted && !_isGradingAnswer,
                    decoration: InputDecoration(
                      hintText: 'Type your concise answer here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isAnswerSubmitted)
                    ElevatedButton(
                      onPressed: _isGradingAnswer ? null : _submitWrittenAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isGradingAnswer
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit for Instant AI Grading', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],

                // Instant Feedback & Explanation Card
                if (_isAnswerSubmitted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              q.isCorrect ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                              color: q.isCorrect ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              q.isCorrect ? 'Correct (+1 Point)' : 'Review & Explanation',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Model Answer: ${q.correctAnswer}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.explanation,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                        if (q.aiFeedback != null && q.aiFeedback!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'AI Note: ${q.aiFeedback}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentIndex < total - 1 ? 'Next Question →' : 'Complete & View Results',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSetupBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Auto-Quiz Generator',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'MCQs, Short & Long questions tailored to Pakistani exam boards with instant grading.',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.quiz_rounded, size: 42, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Config form
          Text(
            'Subject & Topic',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
            initialValue: _selectedSubject,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
            ),
            items: ['Physics', 'Chemistry', 'Computer Science', 'Biology', 'Mathematics']
                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSubject = val);
            },
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _topicController,
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Topic / Chapter Name',
              hintText: 'e.g. Circular Motion, Organic Chemistry, Arrays',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Question Format',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('mcq', 'MCQs Only'),
              const SizedBox(width: 8),
              _buildTypeChip('short', 'Short Answer'),
              const SizedBox(width: 8),
              _buildTypeChip('mixed', 'Mixed Exam'),
            ],
          ),
          const SizedBox(height: 18),

          // Weak topic targeting switch (FR-05 integration)
          SwitchListTile(
            title: const Text('Target Identified Weak Topics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: const Text('Injects topics with <60% accuracy from Adaptive Engine', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _focusWeakTopics,
            activeThumbColor: const Color(0xFF4F46E5),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _focusWeakTopics = val),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: const Text('Generate & Start Assessment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedQuizType == type;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF4F46E5),
        backgroundColor: Colors.white,
        onSelected: (val) {
          if (val) setState(() => _selectedQuizType = type);
        },
      ),
    );
  }
}
