import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SyncTreeView extends ConsumerWidget {
  const SyncTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeNodes = ref.watch(syncProvider.select((s) => s.treeNodes));
    ref.watch(syncProvider.select((s) => s.itemsRevision)); // Force rebuild on any selection change
    final isSyncing = ref.watch(syncProvider.select((s) => s.isSyncing));

    if (treeNodes.isEmpty) {
      final syncState = ref.watch(syncProvider);
      final hasFoldersSelected = syncState.sourcePath != null && syncState.targetPath != null;
      
      return Center(
        child: Text(
          hasFoldersSelected
              ? 'No items to sync.\n${syncState.isTwoWaySync ? "Both folders are identical." : "Source folder is empty or matches target."}'
              : 'No items to display.\nSelect source and target folders.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Fredoka', color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: treeNodes.length,
      itemBuilder: (context, index) {
        final node = treeNodes[index];
        return _TreeNodeWidget(
          node: node,
          disabled: isSyncing,
          key: ValueKey(node.relativePath),
        );
      },
    );
  }
}

class _TreeNodeWidget extends ConsumerStatefulWidget {
  final SyncTreeNode node;
  final bool disabled;

  const _TreeNodeWidget({
    required this.node,
    this.disabled = false,
    super.key,
  });

  @override
  ConsumerState<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends ConsumerState<_TreeNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(syncProvider.notifier);
    final statusColor = _getStatusColor(widget.node.item?.status);
    final isTargetOnly = widget.node.item?.status == FileStatus.missingInSource;

    Color hoverTint = Colors.blueAccent;
    if (isTargetOnly) hoverTint = Colors.purpleAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            onTap: widget.node.isDirectory
                ? () => notifier.expandAndLoadNode(widget.node)
                : (widget.disabled ? null : () => notifier.toggleNodeSelection(widget.node, !widget.node.isSelected)),
            hoverColor: Colors.transparent,
            splashColor: hoverTint.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: _isHovered
                    ? hoverTint.withValues(alpha: 0.08)
                    : (widget.node.needsSync ? Colors.blueAccent.withValues(alpha: 0.03) : Colors.transparent),
                border: Border(
                  left: widget.node.needsSync && widget.node.isSelected
                      ? BorderSide(color: statusColor, width: 2)
                      : const BorderSide(color: Colors.transparent, width: 2),
                ),
              ),
              padding: EdgeInsets.only(
                left: 12.0 + (widget.node.depth * 28.0),
                right: 20.0,
                top: 10.0,
                bottom: 10.0,
              ),
              child: Stack(
                children: [
                  // Indentation Guide Line
                  if (widget.node.depth > 0)
                    Positioned(
                      left: -14,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1.5,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  Row(
                    children: [
                      if (widget.node.isDirectory)
                        Icon(
                          widget.node.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                          size: 14,
                          color: (widget.node.needsSync ? statusColor : Colors.grey).withValues(alpha: 0.6),
                        )
                      else
                        const SizedBox(width: 14),
                      const SizedBox(width: 10),
                      _CustomCheckbox(
                        value: widget.node.isSelected,
                        disabled: widget.disabled,
                        onChanged: (val) => notifier.toggleNodeSelection(widget.node, val),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        widget.node.isDirectory ? LucideIcons.folder : LucideIcons.file,
                        size: 18,
                        color: statusColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.node.name,
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 14,
                                  fontWeight: widget.node.needsSync ? FontWeight.w600 : FontWeight.normal,
                                  color: widget.node.needsSync ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.node.item != null) ...[
                              const SizedBox(width: 10),
                              _buildOwnershipLine(widget.node.item!.status),
                            ],
                          ],
                        ),
                      ),
                      if (widget.node.item != null) _buildStatusBadge(widget.node.item!.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.node.isDirectory && widget.node.isExpanded) ...[
          if (widget.node.isLoading)
            Padding(
              padding: EdgeInsets.only(left: 56.0 + (widget.node.depth * 24.0), top: 8, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          // Render child nodes
          ...widget.node.children
              .take(widget.node.childLimit)
              .map((child) => _TreeNodeWidget(
                    node: child,
                    disabled: widget.disabled,
                    key: ValueKey(child.relativePath),
                  )),
          if (widget.node.children.length > widget.node.childLimit)
            _buildLoadMoreNodes(context, notifier, widget.node),
        ],
      ],
    );
  }

  Widget _buildLoadMoreNodes(BuildContext context, SyncNotifier notifier, SyncTreeNode node) {
    return InkWell(
      onTap: () => notifier.loadMoreChildren(node),
      child: Padding(
        padding: EdgeInsets.only(left: 56.0 + (node.depth * 24.0), top: 8, bottom: 8),
        child: Row(
          children: [
            const Icon(LucideIcons.plusCircle, size: 14, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text(
              'Load ${node.children.length - node.childLimit} more...',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool value;
  final bool disabled;
  final Function(bool) onChanged;

  const _CustomCheckbox({
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onChanged(!value),
      hoverColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.02),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value 
              ? (disabled ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.blueAccent) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value 
                ? (disabled ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.blueAccent) 
                : Colors.white.withValues(alpha: disabled ? 0.05 : 0.2),
            width: 1.5,
          ),
        ),
        child: value
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }
}

Widget _buildOwnershipLine(FileStatus status) {
  bool inSource = status != FileStatus.missingInSource;
  bool inTarget = status != FileStatus.missingInTarget;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildOwnershipIndicator("S", inSource ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05)),
      const SizedBox(width: 2),
      _buildOwnershipIndicator("T", inTarget ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.05)),
    ],
  );
}

Widget _buildOwnershipIndicator(String label, Color color) {
  return Container(
    width: 14,
    height: 14,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: 'Fredoka', fontSize: 8, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

Color _getStatusColor(FileStatus? status) {
  if (status == null) return Colors.blueAccent;
  switch (status) {
    case FileStatus.missingInTarget:
      return Colors.blueAccent;
    case FileStatus.missingInSource:
      return Colors.purpleAccent;
    case FileStatus.different:
      return Colors.orangeAccent;
    case FileStatus.identical:
      return Colors.grey;
  }
}

Widget _buildStatusBadge(FileStatus status) {
  if (status == FileStatus.identical) return const SizedBox.shrink();

  String label = "";
  Color color = Colors.grey;

  switch (status) {
    case FileStatus.missingInTarget:
      label = "Source Only";
      color = Colors.blueAccent;
      break;
    case FileStatus.missingInSource:
      label = "Target Only";
      color = Colors.purpleAccent;
      break;
    case FileStatus.different:
      label = "Different";
      color = Colors.orangeAccent;
      break;
    case FileStatus.identical:
      break;
  }

  return Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Fredoka',
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}
