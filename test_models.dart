import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final models = ['openai', 'mistral', 'qwen', 'llama'];
  for (final m in models) {
    try {
      final res = await http.post(
        Uri.parse('https://text.pollinations.ai/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': 'what is ai in one sentence?'}
          ],
          'model': m,
        }),
      ).timeout(const Duration(seconds: 10));
      print('Model $m -> Status: ${res.statusCode}, Body: ${res.body.trim().replaceAll('\n', ' ').substring(0, res.body.trim().length > 60 ? 60 : res.body.trim().length)}');
    } catch (e) {
      print('Model $m -> Error: $e');
    }
  }
}
