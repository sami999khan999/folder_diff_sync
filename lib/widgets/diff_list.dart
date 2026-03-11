import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class DiffList extends ConsumerWidget {
  const DiffList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    if (state.sourcePath == null || state.targetPath == null) {
      return _buildPlaceholder('Select both folders to see differences');
    }

    if (state.items.isEmpty && !state.isComparing) {
      return _buildPlaceholder('Folders are in sync! No missing files found.');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'Differences Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => notifier.toggleAll(true),
                icon: const Icon(LucideIcons.checkSquare, size: 16),
                label: const Text('Select All'),
              ),
              TextButton.icon(
                onPressed: () => notifier.toggleAll(false),
                icon: const Icon(LucideIcons.square, size: 16),
                label: const Text('Deselect All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _DiffItemTile(
                item: item,
                onChanged: (_) => notifier.toggleItemSelection(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.search, size: 48, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DiffItemTile extends StatelessWidget {
  final SyncItem item;
  final ValueChanged<bool?> onChanged;

  const _DiffItemTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: CheckboxListTile(
        value: item.isSelected,
        onChanged: onChanged,
        activeColor: Colors.blueAccent,
        checkColor: Colors.white,
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item.relativePath,
          style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.7)),
        ),
        secondary: Icon(
          item.type == SyncType.directory ? LucideIcons.folder : LucideIcons.file,
          color: item.status == FileStatus.missingInTarget ? Colors.amber : Colors.blueAccent,
          size: 20,
        ),
      ),
    );
  }
}
