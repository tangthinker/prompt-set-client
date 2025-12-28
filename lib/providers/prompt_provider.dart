import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/models/prompt.dart';
import 'package:prompt_set_client/services/database_service.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

final promptListProvider = StateNotifierProvider<PromptListNotifier, List<Prompt>>((ref) {
  return PromptListNotifier(ref.watch(databaseServiceProvider));
});

final selectedPromptIdProvider = StateProvider<String?>((ref) => null);

final navigationIndexProvider = StateProvider<int>((ref) => 0);

final selectedPromptProvider = Provider<Prompt?>((ref) {
  final prompts = ref.watch(promptListProvider);
  final selectedId = ref.watch(selectedPromptIdProvider);
  if (selectedId == null) return null;
  return prompts.firstWhere((p) => p.id == selectedId);
});

class PromptListNotifier extends StateNotifier<List<Prompt>> {
  final DatabaseService _db;

  PromptListNotifier(this._db) : super([]) {
    loadPrompts();
  }

  Future<void> loadPrompts() async {
    state = await _db.getAllPrompts();
  }

  Future<void> addPrompt(String name, {String? description, String? category}) async {
    final prompt = Prompt.create(name: name, description: description, category: category);
    await _db.insertPrompt(prompt);
    await loadPrompts();
  }

  Future<void> deletePrompt(String id) async {
    await _db.deletePrompt(id);
    await loadPrompts();
  }

  Future<void> updatePrompt(Prompt prompt) async {
    await _db.updatePrompt(prompt);
    await loadPrompts();
  }
}
