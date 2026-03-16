import 'dart:io';
import '../models/sync_item.dart';

class SyncService {
  /// Copies files in parallel batches for maximum throughput.
  static Future<void> syncItems(
    List<SyncItem> items, {
    Function(int count, int total, String fileName, int bytesCopied, int totalBytes)? onProgress,
    int concurrency = 10,
  }) async {
    final selectedItems = items.where((e) => e.isSelected).toList();
    if (selectedItems.isEmpty) return;

    // Calculate total bytes
    int totalBytes = 0;
    for (final item in selectedItems) {
      totalBytes += item.fileSize;
    }

    int completedCount = 0;
    int copiedBytes = 0;

    // Process in parallel batches
    for (int i = 0; i < selectedItems.length; i += concurrency) {
      final end = (i + concurrency > selectedItems.length)
          ? selectedItems.length
          : i + concurrency;
      final batch = selectedItems.sublist(i, end);

      await Future.wait(batch.map((item) async {
        try {
          await _copyItem(item);
        } catch (_) {
          // Skip failed items silently
        }
        completedCount++;
        copiedBytes += item.fileSize;
        if (onProgress != null) {
          onProgress(
            completedCount,
            selectedItems.length,
            item.relativePath,
            copiedBytes,
            totalBytes,
          );
        }
      }));
    }
  }

  static Future<void> _copyItem(SyncItem item) async {
    final bool isToSource = item.status == FileStatus.missingInSource;
    final String fromPath = isToSource ? item.targetPath : item.sourcePath;
    final String toPath = isToSource ? item.sourcePath : item.targetPath;

    if (item.type == SyncType.directory) {
      await Directory(toPath).create(recursive: true);
    } else {
      final parentDir = Directory(toPath).parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      await File(fromPath).copy(toPath);
    }
  }
}
