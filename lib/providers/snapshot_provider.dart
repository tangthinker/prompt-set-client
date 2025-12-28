import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/models/snapshot.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';
import 'package:prompt_set_client/services/database_service.dart';

final snapshotListProvider = StateNotifierProvider.family<SnapshotListNotifier, List<PromptSnapshot>, String>((ref, promptId) {
  return SnapshotListNotifier(ref.watch(databaseServiceProvider), promptId);
});

class SnapshotListNotifier extends StateNotifier<List<PromptSnapshot>> {
  final DatabaseService _db;
  final String promptId;

  SnapshotListNotifier(this._db, this.promptId) : super([]) {
    loadSnapshots();
  }

  Future<void> loadSnapshots() async {
    state = await _db.getSnapshotsForPrompt(promptId);
  }

  Future<void> addSnapshot(String name, String content, Map<String, dynamic> params) async {
    final snapshot = PromptSnapshot.create(
      promptId: promptId,
      name: name,
      content: content,
      params: params,
    );
    await _db.insertSnapshot(snapshot);
    await loadSnapshots();
  }

  Future<void> deleteSnapshot(String id) async {
    await _db.deleteSnapshot(id);
    await loadSnapshots();
  }

  Future<void> updateSnapshot(PromptSnapshot snapshot) async {
    await _db.updateSnapshot(snapshot);
    await loadSnapshots();
  }
}

