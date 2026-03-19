import 'dart:io';
import 'dart:typed_data';
import '../models/sync_item.dart';

class SyncService {
  static const int _largeFileThreshold = 50 * 1024 * 1024; // 50MB
  static const int _bufferSize = 1024 * 1024; // 1MB buffer

  /// Copies files with optimized concurrency and buffer management.
  static Future<void> syncItems(
    List<SyncItem> items, {
    Function(SyncItem item, int count, int total, int bytesCopied, int totalBytes)? onProgress,
    bool Function()? shouldAbort,
    bool Function()? shouldPause,
    int concurrency = 2, // Reduced from 10 to 2 for better HDD performance
  }) async {
    final selectedItems = items.where((e) => e.isSelected).toList();
    if (selectedItems.isEmpty) return;

    // Calculate total bytes
    int totalBytes = 0;
    for (final item in selectedItems) {
      totalBytes += item.fileSize;
    }

    // Sort all selected items by size (smallest first)
    selectedItems.sort((a, b) => a.fileSize.compareTo(b.fileSize));

    int completedCount = 0;
    int copiedBytes = 0;

    // Separate items into large files and others (small files and directories)
    final largeFiles = selectedItems.where((e) => e.type == SyncType.file && e.fileSize > _largeFileThreshold).toList();
    final otherItems = selectedItems.where((e) => e.type == SyncType.directory || e.fileSize <= _largeFileThreshold).toList();

    // 1. Process other items in parallel batches (smallest first)
    for (int i = 0; i < otherItems.length; i += concurrency) {
      if (shouldAbort != null && shouldAbort()) break;
      while (shouldPause != null && shouldPause()) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (shouldAbort != null && shouldAbort()) break;
      }
      if (shouldAbort != null && shouldAbort()) break;

      final end = (i + concurrency > otherItems.length) ? otherItems.length : i + concurrency;
      final batch = otherItems.sublist(i, end);

      await Future.wait(batch.map((item) async {
        if (shouldAbort != null && shouldAbort()) return;
        try {
          await _copyItem(item, onByteProgress: (b) {
            copiedBytes += b;
            if (onProgress != null) {
              onProgress(item, completedCount, selectedItems.length, copiedBytes, totalBytes);
            }
          });
        } catch (_) {
          // If a file copy fails, we should still account for its size to avoid progress bar calculation errors later, 
          // or just accept that it will never reach 100% total bytes.
        }
        completedCount++;
        if (onProgress != null) {
          onProgress(item, completedCount, selectedItems.length, copiedBytes, totalBytes);
        }
      }));
    }

    // 2. Process large files sequentially (concurrency 1) to minimize disk head movement
    for (final item in largeFiles) {
      if (shouldAbort != null && shouldAbort()) break;
      while (shouldPause != null && shouldPause()) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (shouldAbort != null && shouldAbort()) break;
      }
      if (shouldAbort != null && shouldAbort()) break;

      try {
        await _copyItem(item, onByteProgress: (b) {
          copiedBytes += b;
          if (onProgress != null) {
            onProgress(item, completedCount, selectedItems.length, copiedBytes, totalBytes);
          }
        });
      } catch (_) {
        // Skip failed items
      }

      completedCount++;
      if (onProgress != null) {
        onProgress(item, completedCount, selectedItems.length, copiedBytes, totalBytes);
      }
    }
  }

  static Future<void> _copyItem(SyncItem item, {Function(int bytesRead)? onByteProgress}) async {
    final bool isToSource = item.status == FileStatus.missingInSource;
    final String fromPath = isToSource ? item.targetPath : item.sourcePath;
    final String toPath = isToSource ? item.sourcePath : item.targetPath;

    if (item.type == SyncType.directory) {
      await Directory(toPath).create(recursive: true);
      onByteProgress?.call(item.fileSize); // Usually 0 for directories
    } else {
      final parentDir = Directory(toPath).parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      // Use optimized copy for large files, standard copy for small ones
      if (item.fileSize > _largeFileThreshold) {
        await _copyFileOptimized(fromPath, toPath, onByteProgress: onByteProgress);
      } else {
        await File(fromPath).copy(toPath);
        onByteProgress?.call(item.fileSize);
      }
    }
  }

  /// Custom chunked copy using a large buffer to improve throughput on large files.
  static Future<void> _copyFileOptimized(String from, String to, {Function(int bytesRead)? onByteProgress}) async {
    final sourceFile = await File(from).open(mode: FileMode.read);
    final targetFile = await File(to).open(mode: FileMode.write);
    
    try {
      final buffer = Uint8List(_bufferSize);
      int bytesRead;
      while ((bytesRead = await sourceFile.readInto(buffer)) > 0) {
        await targetFile.writeFrom(buffer, 0, bytesRead);
        onByteProgress?.call(bytesRead);
      }
    } finally {
      await sourceFile.close();
      await targetFile.close();
    }
  }
}
