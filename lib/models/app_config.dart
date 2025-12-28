import 'dart:convert';

class ModelConfig {
  final String name;
  final String? apiKey;
  final String? baseUrl;

  ModelConfig({
    required this.name,
    this.apiKey,
    this.baseUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'api_key': apiKey,
      'base_url': baseUrl,
    };
  }

  factory ModelConfig.fromMap(Map<String, dynamic> map) {
    return ModelConfig(
      name: map['name'],
      apiKey: map['api_key'],
      baseUrl: map['base_url'],
    );
  }

  ModelConfig copyWith({
    String? name,
    String? apiKey,
    String? baseUrl,
  }) {
    return ModelConfig(
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class AppConfig {
  final String? defaultModel;
  final List<ModelConfig> models;
  final String locale; // 'en' or 'zh'

  AppConfig({
    this.defaultModel,
    this.models = const [],
    this.locale = 'zh',
  });

  Map<String, dynamic> toMap() {
    return {
      'default_model': defaultModel,
      'models': jsonEncode(models.map((m) => m.toMap()).toList()),
      'locale': locale,
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    List<ModelConfig> modelsList = [];
    if (map['models'] != null) {
      try {
        final decoded = jsonDecode(map['models']) as List;
        modelsList = decoded.map((m) => ModelConfig.fromMap(m as Map<String, dynamic>)).toList();
      } catch (e) {
        // use default
      }
    }
    
    // If empty, provide some defaults
    if (modelsList.isEmpty) {
      modelsList = [
        ModelConfig(name: 'gpt-3.5-turbo', baseUrl: 'https://api.openai.com/v1'),
        ModelConfig(name: 'gpt-4', baseUrl: 'https://api.openai.com/v1'),
        ModelConfig(name: 'deepseek-chat', baseUrl: 'https://api.deepseek.com'),
        ModelConfig(name: 'deepseek-reasoner', baseUrl: 'https://api.deepseek.com'),
      ];
    }

    return AppConfig(
      defaultModel: map['default_model'],
      models: modelsList,
      locale: map['locale'] ?? 'en',
    );
  }

  AppConfig copyWith({
    String? defaultModel,
    List<ModelConfig>? models,
    String? locale,
  }) {
    return AppConfig(
      defaultModel: defaultModel ?? this.defaultModel,
      models: models ?? this.models,
      locale: locale ?? this.locale,
    );
  }
}

