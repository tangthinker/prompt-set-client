import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/models/prompt.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';
import 'package:prompt_set_client/views/prompt_detail_view.dart';
import 'package:prompt_set_client/widgets/common.dart';
import 'dart:ui';

import 'package:prompt_set_client/utils/l10n.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _hoveredPromptId;

  @override
  Widget build(BuildContext context) {
    final prompts = ref.watch(promptListProvider);
    final selectedId = ref.watch(selectedPromptIdProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final s = ref.watch(l10nProvider);

    // Auto-select first prompt if none selected and prompts exist
    if (selectedId == null && prompts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(selectedPromptIdProvider) == null && prompts.isNotEmpty) {
          ref.read(selectedPromptIdProvider.notifier).state = prompts.first.id;
        }
      });
    }

    return Row(
      children: [
        // Prompt List Sidebar
        Container(
          width: 250,
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.get('prompts'),
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
                      child: Icon(
                        CupertinoIcons.plus,
                        size: 16,
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                      ),
                      onPressed: () => _showAddPromptDialog(context, ref, s),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    final isSelected = selectedId == prompt.id;
                    final isHovered = _hoveredPromptId == prompt.id;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredPromptId = prompt.id),
                      onExit: (_) => setState(() => _hoveredPromptId = null),
                      child: GestureDetector(
                        onSecondaryTapUp: (details) => _showPromptContextMenu(context, ref, prompt, s, details.globalPosition),
                        onTap: () => ref.read(selectedPromptIdProvider.notifier).state = prompt.id,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : (isHovered ? (isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.04)) : null),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prompt.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 13,
                                        color: isSelected ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
                                      ),
                                    ),
                                    if (prompt.description != null && prompt.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          prompt.description!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.inactiveGray,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isHovered)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minSize: 0,
                                  child: Icon(
                                    CupertinoIcons.trash,
                                    size: 14,
                                    color: isSelected ? CupertinoColors.white.withOpacity(0.8) : CupertinoColors.destructiveRed,
                                  ),
                                  onPressed: () => _confirmDeletePrompt(context, ref, prompt.id, s),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Settings Icon at bottom left
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minSize: 0,
                      borderRadius: BorderRadius.circular(6),
                      child: Icon(
                        CupertinoIcons.settings,
                        color: isDark ? CupertinoColors.activeBlue : CupertinoColors.activeBlue,
                        size: 18,
                      ),
                      onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Vertical Divider
        Container(
          width: 1,
          color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
        ),
        // Main Detail View
        Expanded(
          child: selectedId == null
              ? Center(child: Text(s.get('select_prompt'), style: const TextStyle(color: CupertinoColors.inactiveGray)))
              : PromptDetailView(key: ValueKey(selectedId)),
        ),
      ],
    );
  }

  void _showAddPromptDialog(BuildContext context, WidgetRef ref, S s) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showMacosDialog(
      context: context,
      title: s.get('new_prompt'),
      content: Column(
        children: [
          CupertinoTextField(
            controller: nameController,
            placeholder: s.get('name'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: descController,
            placeholder: s.get('description_optional'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
            ),
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
          text: s.get('create'),
          isPrimary: true,
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              ref.read(promptListProvider.notifier).addPrompt(
                    nameController.text,
                    description: descController.text,
                  );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  void _showPromptContextMenu(BuildContext context, WidgetRef ref, Prompt prompt, S s, Offset position) async {
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
                            s.get('edit'),
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
      _showEditPromptDialog(context, ref, prompt, s);
    } else if (result == 'delete') {
      _confirmDeletePrompt(context, ref, prompt.id, s);
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

  void _showEditPromptDialog(BuildContext context, WidgetRef ref, Prompt prompt, S s) {
    final nameController = TextEditingController(text: prompt.name);
    final descController = TextEditingController(text: prompt.description ?? '');
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    showMacosDialog(
      context: context,
      title: s.get('edit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: nameController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: descController,
            placeholder: s.get('description_optional'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1)),
            ),
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
              ref.read(promptListProvider.notifier).updatePrompt(
                    prompt.copyWith(
                      name: nameController.text,
                      description: descController.text,
                    ),
                  );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  void _confirmDeletePrompt(BuildContext context, WidgetRef ref, String id, S s) {
    showMacosDialog(
      context: context,
      title: s.get('delete_prompt_title'),
      content: Text(s.get('delete_prompt_content')),
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
            ref.read(promptListProvider.notifier).deletePrompt(id);
            if (ref.read(selectedPromptIdProvider) == id) {
              ref.read(selectedPromptIdProvider.notifier).state = null;
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

