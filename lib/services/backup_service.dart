import 'dart:convert';
import 'dart:io';
import 'package:prompt_set_client/models/prompt.dart';
import 'package:prompt_set_client/models/snapshot.dart';
import 'package:prompt_set_client/services/database_service.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  final DatabaseService _db = DatabaseService();

  Future<String> exportData() async {
    final prompts = await _db.getAllPrompts();
    final allSnapshots = <String, List<PromptSnapshot>>{};

    for (final prompt in prompts) {
      final snapshots = await _db.getSnapshotsForPrompt(prompt.id);
      allSnapshots[prompt.id] = snapshots;
    }

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'prompts': prompts.map((p) => p.toMap()).toList(),
      'snapshots': allSnapshots.map((key, list) => MapEntry(key, list.map((s) => s.toMap()).toList())),
    };

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/prompt_set_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  Future<void> importData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found');

    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    if (data['version'] != 1) throw Exception('Unsupported backup version');

    final promptsData = data['prompts'] as List;
    final snapshotsData = data['snapshots'] as Map<String, dynamic>;

    for (final pMap in promptsData) {
      final prompt = Prompt.fromMap(pMap as Map<String, dynamic>);
      await _db.insertPrompt(prompt);

      final sList = snapshotsData[prompt.id] as List?;
      if (sList != null) {
        for (final sMap in sList) {
          final snapshot = PromptSnapshot.fromMap(sMap as Map<String, dynamic>);
          await _db.insertSnapshot(snapshot);
        }
      }
    }
  }
}

