import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/models/app_config.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';
import 'package:prompt_set_client/services/database_service.dart';

final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  return ConfigNotifier(ref.watch(databaseServiceProvider));
});

class ConfigNotifier extends StateNotifier<AppConfig> {
  final DatabaseService _dbService;

  ConfigNotifier(this._dbService) : super(AppConfig()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    state = await _dbService.getConfig();
  }

  Future<void> updateConfig(AppConfig config) async {
    await _dbService.updateConfig(config);
    state = config;
  }
}
