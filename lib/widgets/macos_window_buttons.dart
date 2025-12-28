import 'package:flutter/cupertino.dart';
import 'package:window_manager/window_manager.dart';

class MacosWindowButtons extends StatelessWidget {
  const MacosWindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 10),
        _TrafficLightButton(
          color: const Color(0xFFFF5F56),
          onPressed: () => windowManager.close(),
          icon: CupertinoIcons.multiply,
        ),
        const SizedBox(width: 10),
        _TrafficLightButton(
          color: const Color(0xFFFFBD2E),
          onPressed: () => windowManager.minimize(),
          icon: CupertinoIcons.minus,
        ),
        const SizedBox(width: 10),
        _TrafficLightButton(
          color: const Color(0xFF27C93F),
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          icon: CupertinoIcons.plus,
        ),
      ],
    );
  }
}

class _TrafficLightButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;
  final IconData icon;

  const _TrafficLightButton({
    required this.color,
    required this.onPressed,
    required this.icon,
  });

  @override
  State<_TrafficLightButton> createState() => _TrafficLightButtonState();
}

class _TrafficLightButtonState extends State<_TrafficLightButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _isHovering
                ? Icon(
                    widget.icon,
                    size: 8,
                    color: CupertinoColors.black,
                    shadows: const [
                      Shadow(
                        color: CupertinoColors.black,
                        offset: Offset(0.5, 0.5),
                      ),
                      Shadow(
                        color: CupertinoColors.black,
                        offset: Offset(-0.5, -0.5),
                      ),
                      Shadow(
                        color: CupertinoColors.black,
                        offset: Offset(0.5, -0.5),
                      ),
                      Shadow(
                        color: CupertinoColors.black,
                        offset: Offset(-0.5, 0.5),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
