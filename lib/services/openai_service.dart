import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/models/app_config.dart';

final openAIServiceProvider = Provider((ref) => OpenAIService());

class OpenAIService {
  final Dio _dio = Dio();

  Stream<Map<String, String>> streamChatCompletion({
    required AppConfig config,
    required String prompt,
    String? modelName,
    Map<String, dynamic>? params,
    CancelToken? cancelToken,
  }) async* {
    final modelConfig = config.models.firstWhere(
      (m) => m.name == (modelName ?? config.defaultModel),
      orElse: () => throw Exception('Model configuration not found: ${modelName ?? config.defaultModel}'),
    );

    final baseUrl = modelConfig.baseUrl ?? 'https://api.openai.com/v1';

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        cancelToken: cancelToken,
        options: Options(
          headers: {
            if (modelConfig.apiKey != null && modelConfig.apiKey!.isNotEmpty)
              'Authorization': 'Bearer ${modelConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': modelConfig.name,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': true,
          if (params != null) ...params,
        },
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      bool isInsideThinkTag = false;

      await for (final chunk in stream) {
        final decoded = utf8.decode(chunk);
        buffer += decoded;

        final lines = buffer.split('\n');
        buffer = lines.last; // Keep the last incomplete line in buffer

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (line == 'data: [DONE]') return;

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            try {
              final json = jsonDecode(jsonStr);
              final delta = json['choices'][0]['delta'];

              String content = delta['content'] ?? '';
              // Support multiple common reasoning field names
              String reasoning = delta['reasoning_content'] ?? delta['reasoning'] ?? delta['thought'] ?? '';

              // Handle <think> tags often used by Ollama/DeepSeek-R1
              if (content.contains('<think>')) {
                isInsideThinkTag = true;
                content = content.replaceFirst('<think>', '');
              }

              if (isInsideThinkTag) {
                if (content.contains('</think>')) {
                  isInsideThinkTag = false;
                  final parts = content.split('</think>');
                  reasoning += parts[0];
                  content = parts.length > 1 ? parts[1] : '';
                } else {
                  reasoning += content;
                  content = '';
                }
              }

              if (content.isNotEmpty || reasoning.isNotEmpty) {
                yield {'content': content, 'reasoning': reasoning};
              }
            } catch (e) {
              // Ignore parse errors for incomplete JSON
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('OpenAI Error: $errorMessage');
    } catch (e) {
      throw Exception('Unexpected Error: $e');
    }
  }
}
