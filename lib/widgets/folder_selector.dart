import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/sync_provider.dart';
import 'glass_card.dart';

class FolderSelectorRow extends ConsumerWidget {
  const FolderSelectorRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    return Column(
      children: [
        PathSelectorCard(
          title: 'Source Folder',
          path: state.sourcePath,
          icon: LucideIcons.folderInput,
          color: Colors.blueAccent,
          onManualPath: (path) => notifier.setSourcePath(path),
          onTap: () async {
            String? result = await FilePicker.platform.getDirectoryPath();
            if (result != null) notifier.setSourcePath(result);
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(LucideIcons.chevronDown, color: Colors.blueAccent, size: 16),
          ),
        ),
        const SizedBox(height: 12),
        PathSelectorCard(
          title: 'Target Folder',
          path: state.targetPath,
          icon: LucideIcons.folderOutput,
          color: Colors.purpleAccent,
          onManualPath: (path) => notifier.setTargetPath(path),
          onTap: () async {
            String? result = await FilePicker.platform.getDirectoryPath();
            if (result != null) notifier.setTargetPath(result);
          },
        ),
      ],
    );
  }
}

class PathSelectorCard extends StatefulWidget {
  final String title;
  final String? path;
  final IconData icon;
  final Color color;
  final String hintText;
  final Function(String) onManualPath;
  final VoidCallback onTap;

  const PathSelectorCard({
    super.key,
    required this.title,
    this.path,
    required this.icon,
    required this.color,
    this.hintText = 'Enter folder path...',
    required this.onManualPath,
    required this.onTap,
  });

  @override
  State<PathSelectorCard> createState() => _PathSelectorCardState();
}

class _PathSelectorCardState extends State<PathSelectorCard> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.path);
  }

  @override
  void didUpdateWidget(PathSelectorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused && widget.path != oldWidget.path) {
      _controller.text = widget.path ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.color),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (focused) {
                      setState(() => _isFocused = focused);
                      if (!focused) {
                        widget.onManualPath(_controller.text);
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(fontFamily: 'Fredoka', color: Colors.white.withValues(alpha: 0.3)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.color.withValues(alpha: 0.3), width: 1.5),
                        ),
                      ),
                      onSubmitted: (val) {
                        widget.onManualPath(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(12),
                    hoverColor: widget.color.withValues(alpha: 0.1),
                    highlightColor: widget.color.withValues(alpha: 0.05),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(LucideIcons.folderSearch, size: 18, color: widget.color),
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
}
