import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'gemini_client.dart';
import 'quota_service.dart';
import 'storage_service.dart';

class UploadedDoc {
  final String id;
  final String name;
  final String content;
  final int byteSize;
  final String summary;
  final List<String> keyPoints;
  final List<DocChatMessage> chatHistory;
  final DateTime uploadedAt;
  final String? base64Pdf;
  final bool isPdf;

  UploadedDoc({
    required this.id,
    required this.name,
    required this.content,
    required this.byteSize,
    required this.summary,
    required this.keyPoints,
    required this.chatHistory,
    required this.uploadedAt,
    this.base64Pdf,
    this.isPdf = false,
  });

  int get totalCharacters => content.isNotEmpty ? content.length : byteSize;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'content': content,
    'byteSize': byteSize,
    'summary': summary,
    'keyPoints': keyPoints,
    'chatHistory': chatHistory.map((m) => m.toJson()).toList(),
    'uploadedAt': uploadedAt.toIso8601String(),
    'isPdf': isPdf,
  };

  factory UploadedDoc.fromJson(Map<String, dynamic> json) => UploadedDoc(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    content: json['content'] ?? '',
    byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
    summary: json['summary'] ?? '',
    keyPoints: (json['keyPoints'] as List?)?.map((e) => e.toString()).toList() ?? [],
    chatHistory: (json['chatHistory'] as List?)
            ?.map((m) => DocChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        [],
    uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    isPdf: json['isPdf'] ?? false,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'charactersUsed': charactersUsed,
  };

  factory DocChatMessage.fromJson(Map<String, dynamic> json) => DocChatMessage(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    charactersUsed: (json['charactersUsed'] as num?)?.toInt() ?? 0,
  );
}

class DocumentService extends ChangeNotifier {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal() {
    _initializeSampleDocuments();
  }

  static const String _storageKey = 'uploaded_documents';
  final List<UploadedDoc> _documents = [];
  List<UploadedDoc> get documents => List.unmodifiable(_documents);

  Future<void> loadFromStorage() async {
    final raw = await StorageService().loadJson(_storageKey);
    if (raw is List && raw.isNotEmpty) {
      _documents
        ..clear()
        ..addAll(raw.map((d) => UploadedDoc.fromJson(Map<String, dynamic>.from(d))));
      notifyListeners();
    }
  }

  void _persist() {
    StorageService().saveJson(
      _storageKey,
      _documents.map((d) => d.toJson()).toList(),
    );
  }

  /// Extracts text locally from PDF bytes using Syncfusion PDF.
  String extractTextFromPdfBytes(Uint8List pdfBytes) {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final extractor = PdfTextExtractor(document);
      final extracted = extractor.extractText().trim();
      document.dispose();
      return extracted;
    } catch (e) {
      debugPrint('PDF text extraction error: $e');
      return '';
    }
  }

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

  /// Summarizes document text or PDF file using Gemini
  Future<Map<String, dynamic>> summarizeDocument({
    required String docName,
    String docText = '',
    required int byteSize,
    Uint8List? pdfBytes,
  }) async {
    // 5MB limit check (FR-03)
    if (byteSize > 5 * 1024 * 1024) {
      throw Exception('File size exceeds 5 MB limit. Please upload a smaller document.');
    }

    if (!QuotaService().canUploadDocument()) {
      throw Exception('Daily document upload quota reached (3/3). Please try again tomorrow.');
    }

    final isPdf = pdfBytes != null || docName.toLowerCase().endsWith('.pdf');
    final base64Pdf = pdfBytes != null ? base64Encode(pdfBytes) : null;

    var resolvedText = docText.trim();
    if (resolvedText.isEmpty && pdfBytes != null) {
      resolvedText = extractTextFromPdfBytes(pdfBytes);
    }

    String summary = 'Document summary generated successfully.';
    List<String> keyPoints = ['Key point extracted from document.'];

    final List<Map<String, dynamic>> parts = [];
    if (base64Pdf != null && resolvedText.isEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': 'application/pdf',
          'data': base64Pdf,
        }
      });
      parts.add({
        'text': '''
Summarize this academic PDF document ("$docName") and extract 4-6 high-yield key revision points.
Return ONLY valid JSON matching this structure:
{
  "summary": "2-3 concise summary sentences",
  "key_points": ["Point 1", "Point 2", "Point 3", "Point 4"]
}
'''
      });
    } else if (resolvedText.isNotEmpty) {
      final excerpt = resolvedText.length > 12000
          ? resolvedText.substring(0, 12000)
          : resolvedText;
      parts.add({
        'text': '''
Summarize this academic document ("$docName") and extract 4-6 high-yield key revision points.
Return ONLY valid JSON matching this structure:
{
  "summary": "2-3 concise summary sentences",
  "key_points": ["Point 1", "Point 2", "Point 3", "Point 4"]
}

Document:
"""
$excerpt
"""
'''
      });
    }

    bool aiSummarized = false;
    if (parts.isNotEmpty) {
      try {
        final rawText = await GeminiClient.generateContent(
          contents: [
            {'role': 'user', 'parts': parts}
          ],
          temperature: 0.3,
          jsonMode: true,
          timeout: const Duration(seconds: 35),
        );
        if (rawText != null && rawText.isNotEmpty) {
          final parsed = jsonDecode(GeminiClient.stripMarkdownFences(rawText));
          summary = parsed['summary'] ?? summary;
          keyPoints = (parsed['key_points'] as List?)?.map((e) => e.toString()).toList() ?? keyPoints;
          aiSummarized = true;
        }
      } catch (e) {
        debugPrint('Gemini summary parsing error: $e');
      }

      // Tier 2 Free AI Summary if Gemini unavailable & we have text
      if (!aiSummarized && resolvedText.isNotEmpty) {
        try {
          final excerpt = resolvedText.length > 3500
              ? resolvedText.substring(0, 3500)
              : resolvedText;
          final freeText = await GeminiClient.callFreeOpenAi(
            messages: [
              {
                'role': 'system',
                'content': 'Return ONLY valid JSON with "summary" and "key_points" (list of 4 strings).'
              },
              {
                'role': 'user',
                'content': 'Summarize "$docName":\n$excerpt',
              },
            ],
            jsonMode: true,
          );
          if (freeText != null && freeText.isNotEmpty) {
            final parsed = jsonDecode(freeText);
            summary = parsed['summary'] ?? summary;
            keyPoints = (parsed['key_points'] as List?)?.map((e) => e.toString()).toList() ?? keyPoints;
            aiSummarized = true;
          }
        } catch (e) {
          debugPrint('Free AI summary error: $e');
        }
      }
    }

    if (!aiSummarized) {
      summary = 'Document processed and indexed for exam preparation.';
      if (resolvedText.isNotEmpty) {
        keyPoints = resolvedText
            .split('\n')
            .where((l) => l.trim().length > 10)
            .take(5)
            .toList();
      } else {
        keyPoints = [
          'Document: $docName (${(byteSize / 1024).toStringAsFixed(1)} KB)',
          'Ready for study and review',
        ];
      }
    }

    final doc = UploadedDoc(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: docName,
      content: resolvedText.isNotEmpty
          ? resolvedText
          : 'PDF Document ($docName, ${(byteSize / 1024).toStringAsFixed(1)} KB)',
      byteSize: byteSize,
      summary: summary,
      keyPoints: keyPoints,
      chatHistory: [],
      uploadedAt: DateTime.now(),
      base64Pdf: base64Pdf,
      isPdf: isPdf,
    );

    _documents.insert(0, doc);
    QuotaService().consumeDocUpload();
    _persist();
    notifyListeners();

    return {
      'document': doc,
      'summary': summary,
      'keyPoints': keyPoints,
    };
  }

  /// Selects the most relevant chunks from a long document using keyword overlap.
  String _selectRelevantExcerpt(String content, String question, {int maxChars = 3500}) {
    if (content.length <= maxChars) return content;

    final tokens = question
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toSet();

    final paragraphs = content.split(RegExp(r'\n\s*\n|\n'));
    final scored = <MapEntry<int, String>>[];
    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      int score = 0;
      for (final t in tokens) {
        if (lower.contains(t)) score++;
      }
      scored.add(MapEntry(score, trimmed));
    }

    scored.sort((a, b) => b.key.compareTo(a.key));
    final buffer = StringBuffer();
    for (final entry in scored) {
      if (buffer.length + entry.value.length + 2 > maxChars) break;
      buffer.writeln(entry.value);
      buffer.writeln();
    }

    final result = buffer.toString().trim();
    return result.isNotEmpty ? result : content.substring(0, maxChars);
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

    final relevantExcerpt = _selectRelevantExcerpt(doc.content, question, maxChars: 6000);

    // Tier 1: Gemini
    if (GeminiClient.cleanApiKey.isNotEmpty) {
      final List<Map<String, dynamic>> parts = [];
      if (doc.isPdf && doc.base64Pdf != null && doc.content.startsWith('PDF Document (')) {
        parts.add({
          'inline_data': {
            'mime_type': 'application/pdf',
            'data': doc.base64Pdf,
          }
        });
        parts.add({
          'text': '''
You are an academic document tutor. Answer the student's question ONLY using the attached PDF document.
If the answer is NOT present or cannot be inferred from this PDF, reply:
"This topic is not covered in your uploaded document."
Language: $language.
Question: $question
'''
        });
      } else {
        parts.add({
          'text': '''
You are an academic document tutor. Answer the student's question ONLY using the document excerpt below.
If the answer is NOT present or cannot be inferred from the document text, reply:
"This topic is not covered in your uploaded document."
Language: $language.

Document ("${doc.name}"):
"""
$relevantExcerpt
"""

Question: $question
'''
        });
      }

      final answer = await GeminiClient.generateContent(
        contents: [
          {'role': 'user', 'parts': parts}
        ],
        temperature: 0.4,
        maxOutputTokens: 1000,
        timeout: const Duration(seconds: 30),
      );
      if (answer != null && answer.isNotEmpty) {
        QuotaService().consumeAiRequest();
        _appendChatMessage(docIndex, question, answer, relevantExcerpt.length);
        return answer;
      }
    }

    // Tier 2: Free Open AI Engine Grounded Q&A Fallback
    if (doc.content.trim().isNotEmpty) {
      final snippet = _selectRelevantExcerpt(doc.content, question, maxChars: 2800);
      final liveAnswer = await GeminiClient.callFreeOpenAi(
        messages: [
          {
            'role': 'system',
            'content':
                'You are an academic document tutor. Answer ONLY using the provided document excerpt. If not covered, say "This topic is not covered in your uploaded document." Language: $language.'
          },
          {
            'role': 'user',
            'content': 'Document ("${doc.name}"):\n"""\n$snippet\n"""\n\nQuestion: $question',
          },
        ],
      );
      if (liveAnswer != null && liveAnswer.isNotEmpty) {
        QuotaService().consumeAiRequest();
        _appendChatMessage(docIndex, question, liveAnswer, snippet.length);
        return liveAnswer;
      }
    }

    // Tier 3: Grounded Document Q&A Fallback (FR-03: answers ONLY from doc context)
    final answer = _extractGroundedDocAnswer(doc: doc, question: question);
    QuotaService().consumeAiRequest();
    _appendChatMessage(docIndex, question, answer['text'] as String, answer['charactersUsed'] as int);
    return answer['text'] as String;
  }

  Map<String, dynamic> _extractGroundedDocAnswer({
    required UploadedDoc doc,
    required String question,
  }) {
    final lowerQ = question.toLowerCase();
    final stopWords = {'what', 'is', 'the', 'of', 'and', 'in', 'to', 'a', 'an', 'are', 'for', 'with', 'on', 'how', 'why', 'describe', 'explain', 'tell', 'me', 'about'};
    final tokens = lowerQ
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !stopWords.contains(t))
        .toList();

    final lines = doc.content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final matchedLines = <String>[];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      for (final t in tokens) {
        if (lowerLine.contains(t)) {
          if (!matchedLines.contains(line.trim())) {
            matchedLines.add(line.trim());
          }
          break;
        }
      }
    }

    if (matchedLines.isEmpty) {
      return {
        'text': 'This topic is not covered in your uploaded document.',
        'charactersUsed': 0,
      };
    }

    final matchedSection = matchedLines.join('\n\n');
    final responseText = '''
Based on your uploaded document "${doc.name}":

$matchedSection

(Grounded extraction: Referenced ${matchedSection.length} characters of your total ${doc.totalCharacters} document characters).
''';

    return {
      'text': responseText.trim(),
      'charactersUsed': matchedSection.length,
    };
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
    _persist();
    notifyListeners();
  }
}
