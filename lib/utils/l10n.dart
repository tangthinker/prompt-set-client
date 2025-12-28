import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/providers/config_provider.dart';

class S {
  final String locale;
  S(this.locale);

  static const _en = {
    'home': 'Home',
    'settings': 'Settings',
    'prompts': 'Prompts',
    'new_prompt': 'New Prompt',
    'name': 'Name',
    'description_optional': 'Description (optional)',
    'cancel': 'Cancel',
    'create': 'Create',
    'select_prompt': 'Please create a prompt to begin',
    'delete_prompt_title': 'Delete Prompt?',
    'delete_prompt_content': 'This will delete all snapshots for this prompt.',
    'delete': 'Delete',
    'run_prompt': 'Run Prompt',
    'save_snapshot': 'Save Snapshot',
    'new_snapshot': 'New Snapshot',
    'snapshot_saved': 'Snapshot saved',
    'api_config': 'API Configuration',
    'api_key': 'OpenAI API Key',
    'base_url': 'Base URL',
    'default_model': 'Default Model',
    'save_settings': 'Save Settings',
    'data_mgmt': 'Data Management',
    'export_backup': 'Export Backup',
    'import_backup': 'Import Backup',
    'language': 'Language',
    'english': 'English',
    'chinese': 'Chinese',
    'success': 'Success',
    'settings_saved': 'Settings saved successfully.',
    'parameters': 'Parameters',
    'enter_prompt_hint': 'Enter your prompt here... Use {{variable}} for parameters.',
    'running': 'Running...',
    'exported': 'Exported',
    'backup_saved_to': 'Backup saved to: ',
    'import_success': 'Backup imported successfully.',
    'error': 'Error',
    'failed': 'Failed',
    'back_to_main': 'Back to Main',
    'snapshot': 'Snapshot',
    'rename': 'Rename',
    'confirm': 'Confirm',
    'edit': 'Edit',
    'cancelled': 'Cancelled',
    'result': 'Result',
    'thinking': 'Thinking',
    'models_config': 'Models Configuration',
    'add_model': 'Add Model',
    'model_name': 'Model Name',
  };

  static const _zh = {
    'home': '首页',
    'settings': '设置',
    'prompts': 'Prompts',
    'new_prompt': '新建提示词',
    'name': '名称',
    'description_optional': '描述 (可选)',
    'cancel': '取消',
    'create': '创建',
    'select_prompt': '请创建一个Prompt开始',
    'delete_prompt_title': '删除提示词？',
    'delete_prompt_content': '这将删除该提示词下的所有快照。',
    'delete': '删除',
    'run_prompt': '运行',
    'save_snapshot': '保存快照',
    'new_snapshot': '新快照',
    'snapshot_saved': '快照已保存',
    'api_config': 'API 配置',
    'api_key': 'OpenAI API 密钥',
    'base_url': '接口地址',
    'default_model': '默认模型',
    'save_settings': '保存设置',
    'data_mgmt': '数据管理',
    'export_backup': '导出备份',
    'import_backup': '导入备份',
    'language': '语言',
    'english': '英文',
    'chinese': '中文',
    'success': '成功',
    'settings_saved': '设置保存成功。',
    'parameters': '参数',
    'enter_prompt_hint': '在此输入您的 Prompt... 使用 {{变量名}} 定义参数。',
    'running': '运行中...',
    'exported': '导出成功',
    'backup_saved_to': '备份已保存至：',
    'import_success': '备份导入成功。',
    'error': '错误',
    'failed': '失败',
    'back_to_main': '返回主界面',
    'snapshot': '快照',
    'rename': '重命名',
    'confirm': '确定',
    'edit': '编辑',
    'cancelled': '已终止',
    'result': '运行结果',
    'thinking': '思考过程',
    'models_config': '模型配置',
    'add_model': '添加模型',
    'model_name': '模型名称',
  };

  String get(String key) {
    final map = locale == 'zh' ? _zh : _en;
    return map[key] ?? key;
  }
}

final l10nProvider = Provider<S>((ref) {
  final config = ref.watch(configProvider);
  return S(config.locale);
});

