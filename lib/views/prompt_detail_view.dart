import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prompt_set_client/models/app_config.dart';
import 'package:prompt_set_client/models/snapshot.dart';
import 'package:prompt_set_client/providers/config_provider.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';
import 'package:prompt_set_client/providers/snapshot_provider.dart';
import 'package:prompt_set_client/services/openai_service.dart';
import 'package:prompt_set_client/widgets/common.dart';
import 'dart:ui';

import 'package:prompt_set_client/utils/l10n.dart';

class PromptDetailView extends ConsumerStatefulWidget {
  const PromptDetailView({super.key});

  @override
  ConsumerState<PromptDetailView> createState() => _PromptDetailViewState();
}

class _PromptDetailViewState extends ConsumerState<PromptDetailView> {
  final _contentController = TextEditingController();
  final _resultController = TextEditingController();
  final _reasoningController = TextEditingController(); // Added for reasoning
  final _resultScrollController = ScrollController(); // Added for auto-scroll
  final _reasoningScrollController = ScrollController(); // Added for reasoning auto-scroll
  final _focusNode = FocusNode();
  final _modelSelectorKey = GlobalKey(); // Added for positioning
  final Map<String, TextEditingController> _varControllers = {};
  final Map<String, FocusNode> _varFocusNodes = {};
  bool _isLoading = false;
  bool _showResult = false;
  bool _isReasoningCollapsed = false; // Added for UI control
  String? _selectedSnapshotId;
  String? _selectedModel; // Added for model selection
  CancelToken? _cancelToken; // Added for termination

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _focusNode.addListener(_onFocusChanged);

    // Initialize content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prompt = ref.read(selectedPromptProvider);
      if (prompt != null) {
        final snapshots = ref.read(snapshotListProvider(prompt.id));
        if (snapshots.isNotEmpty) {
          setState(() {
            _selectedSnapshotId = snapshots.first.id;
            _contentController.text = snapshots.first.content;
            _resultController.text = snapshots.first.lastResult ?? '';
            _reasoningController.text = snapshots.first.lastReasoning ?? '';
            _showResult = _resultController.text.isNotEmpty || _reasoningController.text.isNotEmpty;
            _updateVariables(params: snapshots.first.params);
          });
        } else {
          setState(() {
            _contentController.text = prompt.content ?? '';
            _resultController.text = prompt.lastResult ?? '';
            _reasoningController.text = prompt.lastReasoning ?? '';
            _showResult = _resultController.text.isNotEmpty || _reasoningController.text.isNotEmpty;
            _updateVariables(params: prompt.params);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _contentController.dispose();
    _resultController.dispose();
    _reasoningController.dispose(); // Added
    _resultScrollController.dispose(); // Added
    _reasoningScrollController.dispose(); // Added
    for (var controller in _varControllers.values) {
      controller.dispose();
    }
    for (var node in _varFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _autoSave();
    }
  }

  void _autoSave() async {
    final prompt = ref.read(selectedPromptProvider);
    if (prompt == null) return;

    final params = <String, dynamic>{};
    _varControllers.forEach((key, controller) {
      params[key] = controller.text;
    });

    if (_selectedSnapshotId != null) {
      final snapshots = ref.read(snapshotListProvider(prompt.id));
      final snapshot = snapshots.firstWhere((s) => s.id == _selectedSnapshotId);
      await ref.read(snapshotListProvider(prompt.id).notifier).updateSnapshot(
            snapshot.copyWith(
              content: _contentController.text,
              params: params,
              lastResult: _resultController.text,
              lastReasoning: _reasoningController.text,
            ),
          );
    } else {
      await ref.read(promptListProvider.notifier).updatePrompt(
            prompt.copyWith(
              content: _contentController.text,
              params: params,
              lastResult: _resultController.text,
              lastReasoning: _reasoningController.text,
            ),
          );
    }
  }

  void _onContentChanged() {
    _updateVariables();
  }

  void _updateVariables({Map<String, dynamic>? params}) {
    final content = _contentController.text;
    final regExp = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}');
    final matches = regExp.allMatches(content);
    final variables = matches.map((m) => m.group(1)!).toSet();

    bool changed = false;
    for (var v in variables) {
      if (!_varControllers.containsKey(v)) {
        final controller = TextEditingController(text: params?[v]?.toString() ?? '');
        _varControllers[v] = controller;
        
        final focusNode = FocusNode();
        focusNode.addListener(() {
          if (!focusNode.hasFocus) {
            _autoSave();
          }
        });
        _varFocusNodes[v] = focusNode;
        
        changed = true;
      } else if (params != null && params.containsKey(v)) {
        // Update existing controller if params are provided
        if (_varControllers[v]!.text != params[v]?.toString()) {
          _varControllers[v]!.text = params[v]?.toString() ?? '';
        }
      }
    }
    final toRemove = _varControllers.keys.where((k) => !variables.contains(k)).toList();
    for (var k in toRemove) {
      _varControllers[k]?.dispose();
      _varControllers.remove(k);
      _varFocusNodes[k]?.dispose();
      _varFocusNodes.remove(k);
      changed = true;
    }

    if (changed) setState(() {});
  }

  String _renderPrompt() {
    String content = _contentController.text;
    _varControllers.forEach((variable, controller) {
      content = content.replaceAll('{{$variable}}', controller.text);
    });
    return content;
  }

  void _runPrompt(S s) async {
    final config = ref.read(configProvider);
    final openAI = ref.read(openAIServiceProvider);
    final renderedPrompt = _renderPrompt();

    setState(() {
      _isLoading = true;
      _showResult = true;
      _resultController.clear();
      _reasoningController.clear();
      _isReasoningCollapsed = false;
      _cancelToken = CancelToken();
    });

    try {
      final stream = openAI.streamChatCompletion(
        config: config,
        prompt: renderedPrompt,
        modelName: _selectedModel,
        cancelToken: _cancelToken,
        params: {
          // Additional params could be added here if needed
        },
      );

      await for (final chunk in stream) {
        setState(() {
          if (chunk['reasoning']!.isNotEmpty) {
            _reasoningController.text += chunk['reasoning']!;
          }
          if (chunk['content']!.isNotEmpty) {
            _resultController.text += chunk['content']!;
          }
        });
        
        // Auto-scroll result area
        if (_resultScrollController.hasClients) {
          _resultScrollController.animateTo(
            _resultScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
        
        // Auto-scroll reasoning area if it's active
        if (_reasoningScrollController.hasClients) {
          _reasoningScrollController.animateTo(
            _reasoningScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      
      // Save result after successful stream completion
      _autoSave();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        setState(() => _resultController.text += '\n\n[${s.get('cancelled')}]');
        _autoSave();
      } else {
        setState(() => _resultController.text = '${s.get('error')}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _cancelToken = null;
        });
      }
    }
  }

  void _stopPrompt() {
    _cancelToken?.cancel();
    setState(() {
      _isLoading = false;
      _cancelToken = null;
    });
  }

  void _copyPrompt() {
    bool hasAnyValue = _varControllers.values.any((c) => c.text.isNotEmpty);
    String textToCopy;
    if (hasAnyValue) {
      textToCopy = _renderPrompt();
    } else {
      textToCopy = _contentController.text;
    }
    Clipboard.setData(ClipboardData(text: textToCopy));
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(selectedPromptProvider);
    if (prompt == null) return const SizedBox.shrink();

    final snapshots = ref.watch(snapshotListProvider(prompt.id));
    final config = ref.watch(configProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final s = ref.watch(l10nProvider);

    // Initialize or validate selected model
    if (config.models.isNotEmpty) {
      if (_selectedModel == null || !config.models.any((m) => m.name == _selectedModel)) {
        _selectedModel = config.defaultModel ?? config.models.first.name;
        // If default model is not in the list, fallback to first one
        if (!config.models.any((m) => m.name == _selectedModel)) {
          _selectedModel = config.models.first.name;
        }
      }
    } else {
      _selectedModel = null;
    }

    // Auto-select first snapshot if none selected and snapshots exist
    if (_selectedSnapshotId == null && snapshots.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedSnapshotId == null && snapshots.isNotEmpty) {
          setState(() {
            _selectedSnapshotId = snapshots.first.id;
            _contentController.text = snapshots.first.content;
            _updateVariables();
          });
        }
      });
    }

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.white,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prompt.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildModelSelector(config, isDark),
              const SizedBox(width: 12),
              _buildHeaderIcon(
                _isLoading ? CupertinoIcons.stop_fill : CupertinoIcons.play_fill,
                _isLoading ? _stopPrompt : () => _runPrompt(s),
                color: _isLoading ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen,
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(
                CupertinoIcons.doc_on_doc,
                _copyPrompt,
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(
                CupertinoIcons.plus,
                () => _showAddSnapshotDialog(context, ref, prompt.id, s),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (snapshots.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: snapshots.map((snapshot) {
                final isSelected = _selectedSnapshotId == snapshot.id;
                return GestureDetector(
                  onSecondaryTapUp: (details) => _showSnapshotContextMenu(context, ref, snapshot, s, details.globalPosition),
                  onTap: () {
                    setState(() {
                      _selectedSnapshotId = snapshot.id;
                      _contentController.text = snapshot.content;
                      _resultController.text = snapshot.lastResult ?? '';
                      _reasoningController.text = snapshot.lastReasoning ?? '';
                      _showResult = _resultController.text.isNotEmpty || _reasoningController.text.isNotEmpty;
                      _updateVariables(params: snapshot.params);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? CupertinoColors.white.withOpacity(0.12) : CupertinoColors.black.withOpacity(0.08))
                          : CupertinoColors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1))
                            : CupertinoColors.transparent,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      snapshot.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF252525) : const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? CupertinoColors.white.withOpacity(0.08) : CupertinoColors.black.withOpacity(0.08),
                            ),
                          ),
                          child: CupertinoTextField(
                            controller: _contentController,
                            focusNode: _focusNode,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            placeholder: s.get('enter_prompt_hint'),
                            placeholderStyle: const TextStyle(
                              color: CupertinoColors.placeholderText,
                              fontSize: 14,
                            ),
                            decoration: null,
                            padding: const EdgeInsets.all(16),
                            style: TextStyle(
                              fontFamily: 'SF Mono',
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        ),
                      ),
                      if (_showResult) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.get('result').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                                letterSpacing: 0.5,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: () => setState(() => _showResult = !_showResult),
                              child: Icon(
                                _showResult ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_up,
                                size: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF151515) : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
                              ),
                            ),
                            child: SingleChildScrollView(
                              controller: _resultScrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_reasoningController.text.isNotEmpty) ...[
                                    GestureDetector(
                                      onTap: () => setState(() => _isReasoningCollapsed = !_isReasoningCollapsed),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isReasoningCollapsed ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_down,
                                            size: 12,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.get('thinking'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_isReasoningCollapsed) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        constraints: const BoxConstraints(maxHeight: 12 * 1.5 * 4 + 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border(left: BorderSide(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1), width: 2)),
                                        ),
                                        child: SingleChildScrollView(
                                          controller: _reasoningScrollController,
                                          child: Text(
                                            _reasoningController.text,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.5,
                                              color: isDark ? CupertinoColors.white.withOpacity(0.5) : CupertinoColors.black.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                  SelectableText(
                                    _resultController.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      fontFamily: 'SF Mono',
                                      color: isDark ? CupertinoColors.white.withOpacity(0.9) : CupertinoColors.black.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: () => setState(() => _showResult = true),
                              child: const Icon(
                                CupertinoIcons.chevron_up,
                                size: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (_varControllers.isNotEmpty) const SizedBox(width: 24),
                if (_varControllers.isNotEmpty)
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.get('parameters'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                                letterSpacing: 0.5,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: () {
                                setState(() {
                                  for (var controller in _varControllers.values) {
                                    controller.clear();
                                  }
                                  _autoSave();
                                });
                              },
                              child: Icon(
                                CupertinoIcons.trash,
                                size: 14,
                                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: _varControllers.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CupertinoTextField(
                                      controller: entry.value,
                                      focusNode: _varFocusNodes[entry.key],
                                      placeholder: '${entry.key}',
                                      minLines: 1,
                                      maxLines: 3,
                                      textAlignVertical: TextAlignVertical.top,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(AppConfig config, bool isDark) {
    return GestureDetector(
      key: _modelSelectorKey,
      onTap: () => _showModelPicker(config),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedModel ?? config.defaultModel ?? 'Select Model',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 10,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(AppConfig config) async {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final RenderBox? button = _modelSelectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;
    
    final Offset buttonPosition = button.localToGlobal(Offset.zero);

    final selected = await Navigator.of(context).push<String>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: CupertinoColors.transparent),
            ),
            Positioned(
              left: buttonPosition.dx,
              top: buttonPosition.dy + button.size.height + 4,
              child: FadeTransition(
                opacity: animation,
                child: Container(
                  width: 200,
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
                        children: config.models.map((m) {
                          return _buildMenuItem(
                            context,
                            m.name,
                            onTap: () => Navigator.pop(context, m.name),
                          );
                        }).toList(),
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

    if (selected != null) {
      setState(() {
        _selectedModel = selected;
      });
    }
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2),
        ),
      ),
    );
  }

  void _showAddSnapshotDialog(BuildContext context, WidgetRef ref, String promptId, S s) {
    final now = DateTime.now();
    final format = DateFormat('yyyyMMddHHmmss');
    final defaultName = '${s.get('snapshot')}_${format.format(now)}';
    final nameController = TextEditingController(text: defaultName);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showMacosDialog(
      context: context,
      title: s.get('new_snapshot'),
      content: CupertinoTextField(
        controller: nameController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
        ),
      ),
      actions: [
        MacosButton(
          text: s.get('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        MacosButton(
          text: s.get('create'),
          isPrimary: true,
          onPressed: () {
            final params = <String, dynamic>{};
            _varControllers.forEach((key, controller) {
              params[key] = controller.text;
            });
            ref.read(snapshotListProvider(promptId).notifier).addSnapshot(
                  nameController.text,
                  _contentController.text,
                  params,
                );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showSnapshotContextMenu(BuildContext context, WidgetRef ref, PromptSnapshot snapshot, S s, Offset position) async {
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
                            onTap: () => Navigator.pop(context, 'rename'),
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

    if (result == 'rename') {
      _showRenameSnapshotDialog(context, ref, snapshot, s);
    } else if (result == 'delete') {
      _confirmDeleteSnapshot(context, ref, snapshot, s);
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  void _showRenameSnapshotDialog(BuildContext context, WidgetRef ref, PromptSnapshot snapshot, S s) {
    final nameController = TextEditingController(text: snapshot.name);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    showMacosDialog(
      context: context,
      title: s.get('rename'),
      content: CupertinoTextField(
        controller: nameController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
        ),
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
            ref.read(snapshotListProvider(snapshot.promptId).notifier).updateSnapshot(
                  snapshot.copyWith(name: nameController.text),
                );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _confirmDeleteSnapshot(BuildContext context, WidgetRef ref, PromptSnapshot snapshot, S s) {
    showMacosDialog(
      context: context,
      title: s.get('delete'),
      content: Text('${s.get('delete')} ${snapshot.name}?'),
      actions: [
        MacosButton(
          text: s.get('cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        MacosButton(
          text: s.get('delete'),
          isPrimary: true,
          isDestructive: true,
          onPressed: () {
            ref.read(snapshotListProvider(snapshot.promptId).notifier).deleteSnapshot(snapshot.id);
            if (_selectedSnapshotId == snapshot.id) {
              setState(() {
                _selectedSnapshotId = null;
                _contentController.clear();
                _resultController.clear();
                _varControllers.clear();
              });
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
