import 'package:flutter/cupertino.dart';
import 'dart:ui';

class CupertinoSeparator extends StatelessWidget {
  const CupertinoSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.06),
    );
  }
}

class CupertinoVerticalSeparator extends StatelessWidget {
  const CupertinoVerticalSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      color: isDark ? CupertinoColors.white.withOpacity(0.06) : CupertinoColors.black.withOpacity(0.06),
    );
  }
}

class MacosButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const MacosButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  State<MacosButton> createState() => _MacosButtonState();
}

class _MacosButtonState extends State<MacosButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color textColor;
    Border? border;

    if (widget.isPrimary) {
      bgColor = widget.isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.activeBlue;
      textColor = CupertinoColors.white;
      if (_isPressed) bgColor = bgColor.withOpacity(0.7);
      else if (_isHovered) bgColor = bgColor.withOpacity(0.85);
    } else {
      bgColor = isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.white;
      textColor = widget.isDestructive ? CupertinoColors.destructiveRed : (isDark ? CupertinoColors.white : CupertinoColors.black);
      border = Border.all(
        color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.15),
        width: 0.5,
      );
      if (_isPressed) bgColor = isDark ? CupertinoColors.white.withOpacity(0.05) : CupertinoColors.black.withOpacity(0.05);
      else if (_isHovered) bgColor = isDark ? CupertinoColors.white.withOpacity(0.15) : CupertinoColors.black.withOpacity(0.02);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 28,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 70),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: border,
            boxShadow: widget.isPrimary && !isDark ? [
              BoxShadow(
                color: bgColor.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              )
            ] : null,
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
              decoration: TextDecoration.none,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class MacosDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const MacosDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? CupertinoColors.white.withOpacity(0.1) : CupertinoColors.black.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.normal,
                      color: isDark ? CupertinoColors.white.withOpacity(0.8) : CupertinoColors.black.withOpacity(0.8),
                    ),
                    child: content,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showMacosDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withOpacity(0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return MacosDialog(
        title: title,
        content: content,
        actions: actions,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))),
          child: child,
        ),
      );
    },
  );
}
