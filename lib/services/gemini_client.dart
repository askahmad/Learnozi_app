import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';

/// Shared AI client that unifies Gemini API calls (with model fallback &
/// multi-turn conversation support) and Tier-2 free OpenAI-compatible fallback.
class GeminiClient {
  static String apiKey = GeminiConfig.apiKey.trim().isNotEmpty
      ? GeminiConfig.apiKey.trim()
      : const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String activeModel = 'gemini-3-flash-preview';
  static String? lastApiError;
  static int? lastStatusCode;

  static const List<String> _candidateModels = [
    'gemini-3-flash-preview',
    'gemini-flash-latest',
  ];

  static String get cleanApiKey =>
      apiKey.trim().replaceAll('"', '').replaceAll("'", "");

  /// Calls Gemini generateContent with multi-turn contents or single prompt.
  static Future<String?> generateContent({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 4096,
    bool jsonMode = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final key = cleanApiKey;
    if (key.isEmpty) {
      lastApiError = 'No Gemini API key configured';
      return null;
    }

    final modelsToTry = <String>[
      activeModel,
      ..._candidateModels.where((m) => m != activeModel),
    ];

    final Map<String, dynamic> payload = {
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        if (jsonMode) 'response_mime_type': 'application/json',
      },
    };

    if (systemInstruction != null && systemInstruction.trim().isNotEmpty) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ],
      };
    }

    final encodedBody = jsonEncode(payload);

    for (final modelName in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: encodedBody,
            )
            .timeout(timeout);

        lastStatusCode = response.statusCode;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                lastApiError = null;
                activeModel = modelName;
                return text.trim();
              }
            }
          }
        } else {
          lastApiError = 'Model $modelName HTTP ${response.statusCode}';
          debugPrint('Gemini API ($modelName): HTTP ${response.statusCode}');
          if (response.statusCode == 404 || response.statusCode == 400) {
            continue;
          }
        }
      } catch (e) {
        lastApiError = 'Model $modelName Exception: $e';
        debugPrint('Gemini API Exception ($modelName): $e');
      }
    }
    return null;
  }

  /// Tier-2 free OpenAI-compatible fallback with multi-turn message support.
  static Future<String?> callFreeOpenAi({
    required List<Map<String, String>> messages,
    bool jsonMode = false,
    Duration timeout = const Duration(seconds: 14),
  }) async {
    for (final model in const ['openai-fast', 'openai']) {
      try {
        final response = await http
            .post(
              Uri.parse('https://text.pollinations.ai/'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': jsonMode
                    ? 'application/json, text/plain, */*'
                    : 'text/plain, */*',
              },
              body: jsonEncode({
                'messages': messages,
                'model': model,
                'jsonMode': jsonMode,
                if (model == 'openai') 'seed': 42,
              }),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          var text = response.body.trim();
          if (_isValidFreeResponse(text)) {
            if (jsonMode) {
              text = stripMarkdownFences(text);
            }
            return text;
          }
        }
      } catch (e) {
        debugPrint('Free AI ($model) failed: $e');
      }
    }
    return null;
  }

  static bool _isValidFreeResponse(String text) {
    return text.isNotEmpty &&
        !text.contains('<!DOCTYPE html>') &&
        !text.startsWith('Error:') &&
        !text.contains('FREE_LIMIT') &&
        !text.startsWith('{"status":400') &&
        !text.startsWith('{"status":402');
  }

  static String stripMarkdownFences(String raw) {
    var clean = raw.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    return clean.trim();
  }
}
