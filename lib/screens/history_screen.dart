import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/document_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _quizService = QuizService();
  final _docService = DocumentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showExportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Formatted Study Document Export (FR-13):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document formatted & ready for PDF download!')),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Save Document'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _quizService.pastAttempts;
    final docs = _docService.documents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic History & Records',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Past quiz attempts, summaries & export (FR-12 & FR-13)',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          tabs: [
            Tab(text: 'Past Quizzes (${quizzes.length})'),
            Tab(text: 'Document Notes (${docs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Quizzes History
          quizzes.isEmpty
              ? const Center(child: Text('No quizzes taken yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, i) {
                    final q = quizzes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                q.title,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: q.isTerminated
                                      ? const Color(0xFFFEF2F2)
                                      : (q.scorePercent >= 60 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  q.isTerminated ? 'Terminated' : '${q.scorePercent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: q.isTerminated
                                        ? const Color(0xFFEF4444)
                                        : (q.scorePercent >= 60 ? const Color(0xFF059669) : const Color(0xFFEF4444)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${q.subject} • ${q.topic} • ${q.correctCount}/${q.totalQuestions} Correct',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final report = '''
LEARNOZI ACADEMIC QUIZ REPORT
Subject: ${q.subject}
Topic: ${q.topic}
Date: ${q.timestamp.toIso8601String()}
Score: ${q.scorePercent}% (${q.correctCount}/${q.totalQuestions} correct)
Status: ${q.isTerminated ? 'Terminated Mid-Exam' : 'Completed Successfully'}
=========================================
${q.questions.map((item) => "Q: ${item.question}\nCorrect: ${item.correctAnswer}\nStudent: ${item.studentAnswer ?? 'None'}\n").join('\n')}
''';
                                  _showExportDialog('Quiz Report Export', report);
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Export PDF / Text', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // 2. Document Summaries History
          docs.isEmpty
              ? const Center(child: Text('No document summaries yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                '${(d.byteSize / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final report = '''
LEARNOZI CHAPTER REVISION NOTES
Title: ${d.name}
Uploaded: ${d.uploadedAt.toIso8601String()}
=========================================
SUMMARY:
${d.summary}

KEY TAKEAWAYS:
${d.keyPoints.map((k) => "• $k").join('\n')}
''';
                                  _showExportDialog('Notes Export', report);
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Export Summary', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
