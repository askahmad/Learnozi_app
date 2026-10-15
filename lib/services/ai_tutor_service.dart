import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageBase64;
  int feedback; // 0 = none, 1 = thumbs up, -1 = thumbs down

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBase64,
    this.feedback = 0,
  });
}

class AiTutorService {
  // Free Google AI Studio API Key placeholder.
  // Students can paste their free key or configure it in Settings.
  static String apiKey = '';

  static const String _model = 'gemini-1.5-flash';

  Future<String> askTutor({
    required String question,
    required String studentLevel, // e.g. "FSc Part 1 / Medical"
    required String language, // "English" or "Urdu"
    String? imageBase64,
  }) async {
    if (apiKey.isEmpty) {
      return '⚠️ Please enter your free Gemini API Key in the top-right settings (or AI Tutor header) to start chatting for free!';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    final systemInstruction = '''
You are a patient, expert, and encouraging AI study tutor for Pakistani students (Matric, FSc, MDCAT, CSS, University).
Target Student Level: $studentLevel.
Answer Language: $language.
Formatting rules:
1. Explain the topic clearly, step-by-step.
2. Provide ONE practical, worked example.
3. Conclude with a crisp "3-Point Revision Summary" for exam prep.
If the question is in Urdu, or language is Urdu, respond in clear, easy-to-read Urdu (or Roman Urdu if specified).
''';

    final contents = <Map<String, dynamic>>[];

    final parts = <Map<String, dynamic>>[];
    parts.add({'text': '$systemInstruction\n\nStudent Question: $question'});

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': imageBase64,
        }
      });
    }

    contents.add({'parts': parts});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1500,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final partsList = content['parts'] as List?;
          if (partsList != null && partsList.isNotEmpty) {
            return partsList[0]['text'] ?? 'No response generated.';
          }
        }
        return 'Empty response from Gemini.';
      } else {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['error']?['message'] ?? response.body;
        debugPrint('Gemini Error: $message');
        return 'AI Error (${response.statusCode}): $message';
      }
    } catch (e) {
      debugPrint('Exception in askTutor: $e');
      return 'Network/Connection error. Please check your internet connection.';
    }
  }
}
