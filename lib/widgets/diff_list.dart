import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class DiffList extends ConsumerWidget {
  const DiffList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    if (state.sourcePath == null || state.targetPath == null) {
      return _buildPlaceholder('Select both folders to see differences', LucideIcons.search);
    }

    if (state.items.isEmpty && !state.isComparing) {
      return _buildPlaceholder('Folders are in sync! No missing files found.', LucideIcons.checkCircle);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Differences Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${state.items.length} items to reconcile',
                    style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const Spacer(),
              _ActionButton(
                onPressed: () => notifier.toggleAll(true),
                icon: LucideIcons.checkSquare,
                label: 'All',
              ),
              const SizedBox(width: 8),
              _ActionButton(
                onPressed: () => notifier.toggleAll(false),
                icon: LucideIcons.square,
                label: 'None',
              ),
            ],
          ),
        ),
        const Divider(indent: 24, endIndent: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _DiffItemTile(
                item: item,
                onChanged: (_) => notifier.toggleItemSelection(index),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _ActionButton({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white.withValues(alpha: 0.03),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _DiffItemTile extends StatelessWidget {
  final SyncItem item;
  final ValueChanged<bool?> onChanged;

  const _DiffItemTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isMissingInSource = item.status == FileStatus.missingInSource;
    final bool isDifferent = item.status == FileStatus.different;

    Color statusColor = Colors.blueAccent;
    IconData statusIcon = LucideIcons.filePlus;
    String statusText = 'Add to Target';

    if (isMissingInSource) {
      statusColor = Colors.purpleAccent;
      statusIcon = LucideIcons.arrowLeft;
      statusText = 'Add to Source';
    } else if (isDifferent) {
      statusColor = Colors.amber;
      statusIcon = LucideIcons.refreshCcw;
      statusText = 'Update Target';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isSelected ? statusColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!item.isSelected),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item.type == SyncType.directory ? Colors.grey : statusColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.type == SyncType.directory ? LucideIcons.folder : LucideIcons.file,
                  color: item.type == SyncType.directory ? Colors.grey : statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.relativePath,
                      style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: item.isSelected,
                      onChanged: onChanged,
                      activeColor: statusColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
