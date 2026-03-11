import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/sync_provider.dart';

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
            onTap: () async {
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != null) notifier.setSourcePath(result);
            },
          ),
        ),
        const SizedBox(width: 16),
        const Icon(LucideIcons.arrowRight, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: FolderCard(
            title: 'Target Folder',
            path: state.targetPath,
            icon: LucideIcons.folderOutput,
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
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.title,
    this.path,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                path ?? 'Select folder...',
                style: TextStyle(
                  fontSize: 13,
                  color: path != null ? Colors.white : Colors.grey.withValues(alpha: 0.5),
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
