import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/providers/config_provider.dart';
import 'package:prompt_set_client/services/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';
import 'package:prompt_set_client/models/app_config.dart';
import 'package:prompt_set_client/widgets/common.dart';
import 'package:prompt_set_client/utils/l10n.dart';
import 'dart:ui';

final backupServiceProvider = Provider((ref) => BackupService());

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _modelNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  late String _currentLocale;
  late List<ModelConfig> _models;
  String? _defaultModelName;
  int _selectedSubPageIndex = 0;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _currentLocale = config.locale;
    _models = List.from(config.models);
    _defaultModelName = config.defaultModel;
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(l10nProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2);
    final contentColor = isDark ? const Color(0xFF1E1E1E) : CupertinoColors.white;

    // Listen for initial config load if models are currently empty
    ref.listen(configProvider, (previous, next) {
      if (_models.isEmpty && next.models.isNotEmpty) {
        setState(() {
          _currentLocale = next.locale;
          _models = List.from(next.models);
          _defaultModelName = next.defaultModel;
        });
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: contentColor,
      child: Column(
        children: [
          // Desktop-style Header
          Container(
            height: 40,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: Border(bottom: BorderSide(color: isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.06))),
            ),
            child: Text(
              s.get('settings'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Settings Sidebar
                Container(
                  width: 200,
                  color: sidebarColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildSidebarItem(
                        icon: CupertinoIcons.list_bullet,
                        label: s.get('models_config'),
                        index: 0,
                        isSelected: _selectedSubPageIndex == 0,
                      ),
                      _buildSidebarItem(
                        icon: CupertinoIcons.globe,
                        label: s.get('language'),
                        index: 1,
                        isSelected: _selectedSubPageIndex == 1,
                      ),
                      _buildSidebarItem(
                        icon: CupertinoIcons.tray_arrow_down,
                        label: s.get('data_mgmt'),
                        index: 2,
                        isSelected: _selectedSubPageIndex == 2,
                      ),
                    ],
                  ),
                ),
                // Settings Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: IndexedStack(
                            index: _selectedSubPageIndex,
                            children: [
                              _buildModelsSettings(s, isDark),
                              _buildLanguageSettings(s, isDark),
                              _buildDataSettings(s, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            MacosButton(
                              text: s.get('back_to_main'),
                              onPressed: () => ref.read(navigationIndexProvider.notifier).state = 0,
                            ),
                            const SizedBox(width: 12),
                            MacosButton(
                              text: s.get('save_settings'),
                              isPrimary: true,
                              onPressed: _saveSettings,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubPageIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue
              : (isDark ? CupertinoColors.white.withOpacity(0.04) : CupertinoColors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings(S s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(s.get('language')),
        const SizedBox(height: 32),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                s.get('language').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                ),
              ),
            ),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _currentLocale,
              backgroundColor: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.03),
              thumbColor: isDark ? const Color(0xFF636366) : CupertinoColors.white,
              children: {
                'en': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(s.get('english'), style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                ),
                'zh': Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(s.get('chinese'), style: TextStyle(fontSize: 13, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _currentLocale = value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataSettings(S s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(s.get('data_mgmt')),
        const SizedBox(height: 24),
        _buildDesktopActionItem(
          label: s.get('export_backup'),
          description: 'Export all prompts and snapshots to a JSON file',
          icon: CupertinoIcons.cloud_download,
          onTap: _exportBackup,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildDesktopActionItem(
          label: s.get('import_backup'),
          description: 'Import prompts and snapshots from a JSON file',
          icon: CupertinoIcons.cloud_upload,
          onTap: _importBackup,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildContentHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    );
  }

  Widget _buildDesktopTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? placeholder,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDesktopActionItem({
    required String label,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? CupertinoColors.white.withOpacity(0.04) : CupertinoColors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.08) : CupertinoColors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(icon, size: 20, color: CupertinoColors.activeBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 12, color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2)),
                  ],
                ),
              ),
              Icon(CupertinoIcons.right_chevron, size: 14, color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelsSettings(S s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildContentHeader(s.get('models_config')),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: const Icon(CupertinoIcons.plus_circle_fill, size: 28),
              onPressed: () => _showModelDialog(s),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _models.length,
            itemBuilder: (context, index) {
              final model = _models[index];
              final isDefault = model.name == _defaultModelName;
              
              return GestureDetector(
                onSecondaryTapUp: (details) => _showModelContextMenu(context, index, s, details.globalPosition),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? CupertinoColors.white.withOpacity(0.04) : CupertinoColors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDefault 
                          ? CupertinoColors.activeBlue.withOpacity(0.5)
                          : (isDark ? CupertinoColors.white.withOpacity(0.08) : CupertinoColors.black.withOpacity(0.08)),
                      width: isDefault ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDefault ? CupertinoColors.activeBlue : CupertinoColors.activeBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.cube, 
                          size: 20, 
                          color: isDefault ? CupertinoColors.white : CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(model.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                if (isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: CupertinoColors.activeBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              model.baseUrl ?? 'No Base URL',
                              style: TextStyle(fontSize: 12, color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: Icon(
                          isDefault ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 16,
                          color: isDefault ? CupertinoColors.systemYellow : CupertinoColors.systemGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _defaultModelName = model.name;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: const Icon(CupertinoIcons.pencil, size: 16, color: CupertinoColors.activeBlue),
                        onPressed: () => _showModelDialog(s, model: model, index: index),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: const Icon(CupertinoIcons.trash, size: 16, color: CupertinoColors.destructiveRed),
                        onPressed: () => _deleteModel(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showModelContextMenu(BuildContext context, int index, S s, Offset position) async {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: CupertinoColors.transparent),
            ),
            Positioned(
              left: position.dx,
              top: position.dy,
              child: FadeTransition(
                opacity: animation,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xCC2D2D2D) : const Color(0xCCF2F2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            context,
                            s.get('rename'),
                            onTap: () => Navigator.pop(context, 'edit'),
                          ),
                          Container(
                            height: 0.5,
                            color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
                          ),
                          _buildMenuItem(
                            context,
                            s.get('delete'),
                            isDestructive: true,
                            onTap: () => Navigator.pop(context, 'delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 100),
      ),
    );

    if (result == 'edit') {
      _showModelDialog(s, model: _models[index], index: index);
    } else if (result == 'delete') {
      _deleteModel(index);
    }
  }

  Widget _buildMenuItem(BuildContext context, String text, {required VoidCallback onTap, bool isDestructive = false}) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: CupertinoColors.transparent,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
              color: isDestructive
                  ? CupertinoColors.destructiveRed
                  : (isDark ? CupertinoColors.white : CupertinoColors.black),
            ),
          ),
        ),
      ),
    );
  }

  void _showModelDialog(S s, {ModelConfig? model, int? index}) {
    final nameController = TextEditingController(text: model?.name ?? '');
    final keyController = TextEditingController(text: model?.apiKey ?? '');
    final urlController = TextEditingController(text: model?.baseUrl ?? '');
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showMacosDialog(
      context: context,
      title: model == null ? s.get('add_model') : s.get('rename'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDesktopTextField(
            label: s.get('model_name'),
            controller: nameController,
            placeholder: 'gpt-4',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildDesktopTextField(
            label: s.get('api_key'),
            controller: keyController,
            placeholder: 'sk-...',
            obscureText: true,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildDesktopTextField(
            label: s.get('base_url'),
            controller: urlController,
            placeholder: 'https://api.openai.com/v1',
            isDark: isDark,
          ),
        ],
      ),
      actions: [
        MacosButton(
          text: s.get('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        MacosButton(
          text: s.get('confirm'),
          isPrimary: true,
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              setState(() {
                final newModel = ModelConfig(
                  name: nameController.text,
                  apiKey: keyController.text,
                  baseUrl: urlController.text,
                );
                if (index != null) {
                  _models[index] = newModel;
                } else {
                  _models.add(newModel);
                }
              });
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  void _deleteModel(int index) {
    setState(() {
      final deletedModel = _models.removeAt(index);
      if (_defaultModelName == deletedModel.name) {
        _defaultModelName = _models.isNotEmpty ? _models.first.name : null;
      }
    });
  }

  void _saveSettings() async {
    final s = ref.read(l10nProvider);
    final config = ref.read(configProvider).copyWith(
      locale: _currentLocale,
      models: _models,
      defaultModel: _defaultModelName,
    );
    await ref.read(configProvider.notifier).updateConfig(config);
    _showAlert(s.get('success'), s.get('settings_saved'));
  }

  void _exportBackup() async {
    final s = ref.read(l10nProvider);
    try {
      final path = await ref.read(backupServiceProvider).exportData();
      _showAlert(s.get('exported'), '${s.get('backup_saved_to')}$path');
    } catch (e) {
      _showAlert(s.get('error'), '${s.get('failed')}: $e');
    }
  }

  void _importBackup() async {
    final s = ref.read(l10nProvider);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        await ref.read(backupServiceProvider).importData(result.files.single.path!);
        await ref.read(promptListProvider.notifier).loadPrompts();
        _showAlert(s.get('success'), s.get('import_success'));
      }
    } catch (e) {
      _showAlert(s.get('error'), '${s.get('failed')}: $e');
    }
  }

  void _showAlert(String title, String message) {
    final s = ref.read(l10nProvider);
    showMacosDialog(
      context: context,
      title: title,
      content: Text(message),
      actions: [
        MacosButton(
          text: s.get('confirm'),
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
