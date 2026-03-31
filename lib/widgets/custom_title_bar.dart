import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomTitleBar extends StatelessWidget {
  final String title;

  const CustomTitleBar({super.key, this.title = 'Folder Diff Sync'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          // Drag Region (Flexible)
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                bool isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.transparent, // Required for hit testing
                child: Row(
                  children: [
                    Image.asset('assets/logo.png', width: 20, height: 20),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Window Controls
          _WindowControl(
            icon: LucideIcons.minus,
            onPressed: () => windowManager.minimize(),
          ),
          _WindowControl(
            icon: LucideIcons.square,
            onPressed: () async {
              bool isMaximized = await windowManager.isMaximized();
              if (isMaximized) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _WindowControl(
            icon: LucideIcons.x,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowControl extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowControl({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowControl> createState() => _WindowControlState();
}

class _WindowControlState extends State<_WindowControl> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        hoverColor: widget.isClose 
            ? const Color(0xFFE81123) 
            : Colors.white.withValues(alpha: 0.1),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 48,
          height: double.infinity,
          alignment: Alignment.center,
          color: _isHovered 
              ? (widget.isClose ? const Color(0xFFE81123) : Colors.white.withValues(alpha: 0.1))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered && widget.isClose 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
