import 'dart:convert';
import 'package:uuid/uuid.dart';

class PromptSnapshot {
  final String id;
  final String promptId;
  final String name;
  final String content;
  final Map<String, dynamic> params;
  final String? lastResult;
  final String? lastReasoning;
  final DateTime createdAt;

  PromptSnapshot({
    required this.id,
    required this.promptId,
    required this.name,
    required this.content,
    required this.params,
    this.lastResult,
    this.lastReasoning,
    required this.createdAt,
  });

  factory PromptSnapshot.create({
    required String promptId,
    required String name,
    required String content,
    Map<String, dynamic>? params,
  }) {
    return PromptSnapshot(
      id: const Uuid().v4(),
      promptId: promptId,
      name: name,
      content: content,
      params: params ?? {},
      lastResult: null,
      lastReasoning: null,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt_id': promptId,
      'name': name,
      'content': content,
      'params': jsonEncode(params),
      'last_result': lastResult,
      'last_reasoning': lastReasoning,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PromptSnapshot.fromMap(Map<String, dynamic> map) {
    return PromptSnapshot(
      id: map['id'],
      promptId: map['prompt_id'],
      name: map['name'],
      content: map['content'],
      params: jsonDecode(map['params'] as String) as Map<String, dynamic>,
      lastResult: map['last_result'],
      lastReasoning: map['last_reasoning'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  PromptSnapshot copyWith({
    String? name,
    String? content,
    Map<String, dynamic>? params,
    String? lastResult,
    String? lastReasoning,
  }) {
    return PromptSnapshot(
      id: id,
      promptId: promptId,
      name: name ?? this.name,
      content: content ?? this.content,
      params: params ?? this.params,
      lastResult: lastResult ?? this.lastResult,
      lastReasoning: lastReasoning ?? this.lastReasoning,
      createdAt: createdAt,
    );
  }
}

