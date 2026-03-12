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

    return Row(
      children: [
        Expanded(
          child: FolderCard(
            title: 'Source Folder',
            path: state.sourcePath,
            icon: LucideIcons.folderInput,
            color: Colors.blueAccent,
            onTap: () async {
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != null) notifier.setSourcePath(result);
            },
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowRight, color: Colors.grey, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FolderCard(
            title: 'Target Folder',
            path: state.targetPath,
            icon: LucideIcons.folderOutput,
            color: Colors.purpleAccent,
            onTap: () async {
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != null) notifier.setTargetPath(result);
            },
          ),
        ),
      ],
    );
  }
}

class FolderCard extends StatelessWidget {
  final String title;
  final String? path;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.title,
    this.path,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                path ?? 'Select folder...',
                style: TextStyle(
                  fontSize: 13,
                  color: path != null ? Colors.white.withValues(alpha: 0.9) : Colors.grey.withValues(alpha: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
