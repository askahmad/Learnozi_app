import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_tutor_service.dart';
import 'quota_service.dart';

class UploadedDoc {
  final String id;
  final String name;
  final String content;
  final int byteSize;
  final String summary;
  final List<String> keyPoints;
  final List<DocChatMessage> chatHistory;
  final DateTime uploadedAt;

  UploadedDoc({
    required this.id,
    required this.name,
    required this.content,
    required this.byteSize,
    required this.summary,
    required this.keyPoints,
    required this.chatHistory,
    required this.uploadedAt,
  });

  int get totalCharacters => content.length;
}

class DocChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int charactersUsed; // Usage metric (FR-03)

  DocChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.charactersUsed = 0,
  });
}

class DocumentService extends ChangeNotifier {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal() {
    _initializeSampleDocuments();
  }

  final List<UploadedDoc> _documents = [];
  List<UploadedDoc> get documents => List.unmodifiable(_documents);

  void _initializeSampleDocuments() {
    _documents.add(
      UploadedDoc(
        id: 'doc_sample_1',
        name: 'Physics Ch 5: Rotational & Circular Motion.txt',
        content: '''
Physics Class 11 - Chapter 5: Rotational and Circular Motion.
1. Angular Displacement: When a body moves along a circular path, the angle swept out by the radius vector in a given time is called angular displacement (theta = s / r). Measured in radians.
2. Angular Velocity: The rate of change of angular displacement (omega = delta theta / delta t). Related to linear velocity by v = r * omega.
3. Centripetal Force: The inward force required to keep a body moving in a circular path (Fc = m * v^2 / r = m * r * omega^2).
4. Moment of Inertia (I): The rotational analogue of mass. For a point mass, I = m * r^2. For a solid cylinder, I = (1/2) * m * r^2.
5. Angular Momentum (L): L = r x p = I * omega. Law of conservation of angular momentum states that if net external torque is zero, total angular momentum remains constant (I1 * omega1 = I2 * omega2).
''',
        byteSize: 1024 * 3, // ~3 KB
        summary: 'Overview of rotational dynamics covering angular displacement, centripetal force equations, moment of inertia formulas, and conservation of angular momentum.',
        keyPoints: [
          'Angular displacement formula: theta = s / r (measured in radians).',
          'Linear vs Angular velocity link: v = r * omega.',
          'Centripetal Force equation: Fc = m * v^2 / r.',
          'Moment of inertia (I) is rotational mass: I = m * r^2.',
          'Conservation of Angular Momentum holds when net external torque = 0.',
        ],
        chatHistory: [
          DocChatMessage(
            id: 'm1',
            text: 'What is the relation between linear velocity and angular velocity?',
            isUser: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          DocChatMessage(
            id: 'm2',
            text: 'According to Section 2 of your notes, linear velocity (v) is related to angular velocity (omega) by: v = r * omega, where r is the radius of the circular path.',
            isUser: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            charactersUsed: 420,
          ),
        ],
        uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );
  }

  /// Summarizes document text using Gemini
  Future<Map<String, dynamic>> summarizeDocument({
    required String docName,
    required String docText,
    required int byteSize,
  }) async {
    // 5MB limit check (FR-03)
    if (byteSize > 5 * 1024 * 1024) {
      throw Exception('File size exceeds 5 MB limit. Please upload a smaller document.');
    }

    if (!QuotaService().canUploadDocument()) {
      throw Exception('Daily document upload quota reached (3/3). Please try again tomorrow.');
    }

    final apiKey = AiTutorService.apiKey;
    String summary = 'Document summary generated successfully.';
    List<String> keyPoints = ['Key point extracted from document.'];

    if (apiKey.isNotEmpty) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final prompt = '''
Summarize this academic document and extract 4-6 high-yield key revision points.
Return ONLY valid JSON matching this structure:
{
  "summary": "2-3 concise summary sentences",
  "key_points": ["Point 1", "Point 2", "Point 3", "Point 4"]
}

Document:
"""
$docText
"""
''';

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {
              'response_mime_type': 'application/json',
              'temperature': 0.3,
            }
          }),
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          final parsed = jsonDecode(text);
          summary = parsed['summary'] ?? summary;
          keyPoints = (parsed['key_points'] as List?)?.map((e) => e.toString()).toList() ?? keyPoints;
        }
      } catch (e) {
        debugPrint('Gemini summary parsing error: $e');
        summary = 'Summary generated from notes: Covers core concepts, formulas, and examination principles.';
        keyPoints = docText.split('\n').where((l) => l.trim().length > 10).take(4).toList();
      }
    } else {
      summary = 'Document processed. (To generate AI-powered summaries, ensure your Gemini API Key is entered in settings).';
      keyPoints = docText.split('\n').where((l) => l.trim().length > 10).take(4).toList();
    }

    final doc = UploadedDoc(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: docName,
      content: docText,
      byteSize: byteSize,
      summary: summary,
      keyPoints: keyPoints,
      chatHistory: [],
      uploadedAt: DateTime.now(),
    );

    _documents.insert(0, doc);
    QuotaService().consumeDocUpload();
    notifyListeners();

    return {
      'document': doc,
      'summary': summary,
      'keyPoints': keyPoints,
    };
  }

  /// Grounded Document Q&A Chat (FR-03)
  Future<String> askDocumentChat({
    required String docId,
    required String question,
    required String language,
  }) async {
    final docIndex = _documents.indexWhere((d) => d.id == docId);
    if (docIndex == -1) return 'Document not found.';
    final doc = _documents[docIndex];

    if (!QuotaService().canMakeAiRequest()) {
      return '⚠️ Daily AI request limit reached. Resets at midnight.';
    }

    final apiKey = AiTutorService.apiKey;
    if (apiKey.isEmpty) {
      final simulatedResponse = 'Document context extracted: Answering based on "${doc.name}". Please add your Gemini API key in settings for live AI replies.';
      _appendChatMessage(docIndex, question, simulatedResponse, doc.content.length);
      return simulatedResponse;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
You are an academic document tutor. Answer the student's question ONLY using the document text below.
If the answer is NOT present or cannot be inferred from the document text, reply:
"This topic is not covered in your uploaded document."
Language: $language.
For programming or technical material, provide code in the matching programming language.

Document:
"""
${doc.content}
"""

Question: $question
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final answer = body['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No response generated.';
        QuotaService().consumeAiRequest();
        _appendChatMessage(docIndex, question, answer, doc.content.length);
        return answer;
      } else {
        return 'AI error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Network error connecting to AI: $e';
    }
  }

  void _appendChatMessage(int docIndex, String userText, String aiText, int charCount) {
    _documents[docIndex].chatHistory.add(
      DocChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _documents[docIndex].chatHistory.add(
      DocChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: aiText,
        isUser: false,
        timestamp: DateTime.now(),
        charactersUsed: charCount,
      ),
    );
    notifyListeners();
  }
}
