import 'dart:io';
import '../models/sync_item.dart';

class SyncService {
  /// Copies files in parallel batches for maximum throughput.
  static Future<void> syncItems(
    List<SyncItem> items, {
    Function(SyncItem item, int count, int total, int bytesCopied, int totalBytes)? onProgress,
    bool Function()? shouldAbort,
    bool Function()? shouldPause,
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
      if (shouldAbort != null && shouldAbort()) break;

      while (shouldPause != null && shouldPause()) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (shouldAbort != null && shouldAbort()) break;
      }
      if (shouldAbort != null && shouldAbort()) break;

      final end = (i + concurrency > selectedItems.length)
          ? selectedItems.length
          : i + concurrency;
      final batch = selectedItems.sublist(i, end);

      await Future.wait(batch.map((item) async {
        if (shouldAbort != null && shouldAbort()) return;
        try {
          await _copyItem(item);
        } catch (_) {
          // Skip failed items silently
        }
        completedCount++;
        copiedBytes += item.fileSize;
        if (onProgress != null) {
          onProgress(
            item,
            completedCount,
            selectedItems.length,
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
