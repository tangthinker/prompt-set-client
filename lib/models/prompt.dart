import 'dart:convert';
import 'package:uuid/uuid.dart';

class Prompt {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? content;
  final Map<String, dynamic>? params;
  final String? lastResult;
  final String? lastReasoning;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prompt({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.content,
    this.params,
    this.lastResult,
    this.lastReasoning,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prompt.create({
    required String name,
    String? description,
    String? category,
  }) {
    final now = DateTime.now();
    return Prompt(
      id: const Uuid().v4(),
      name: name,
      description: description,
      category: category,
      content: '',
      params: {},
      lastResult: null,
      lastReasoning: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'content': content,
      'params': params != null ? jsonEncode(params) : null,
      'last_result': lastResult,
      'last_reasoning': lastReasoning,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Prompt.fromMap(Map<String, dynamic> map) {
    return Prompt(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      content: map['content'],
      params: map['params'] != null ? jsonDecode(map['params'] as String) as Map<String, dynamic> : null,
      lastResult: map['last_result'],
      lastReasoning: map['last_reasoning'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Prompt copyWith({
    String? name,
    String? description,
    String? category,
    String? content,
    Map<String, dynamic>? params,
    String? lastResult,
    String? lastReasoning,
    DateTime? updatedAt,
  }) {
    return Prompt(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      content: content ?? this.content,
      params: params ?? this.params,
      lastResult: lastResult ?? this.lastResult,
      lastReasoning: lastReasoning ?? this.lastReasoning,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
