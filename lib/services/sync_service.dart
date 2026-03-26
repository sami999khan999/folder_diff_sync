import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import '../models/sync_item.dart';
import 'native_file_transfer.dart';

class SyncService {
  static const int _largeFileThreshold = 50 * 1024 * 1024; // 50MB
  static const int _bufferSize = 1024 * 1024; // 1MB buffer

  /// Copies files with optimized concurrency and buffer management.
  static Future<void> syncItems(
    List<SyncItem> items, {
    Function(SyncItem item, int count, int total, int bytesCopied, int totalBytes, int itemBytesCopied)? onProgress,
    bool Function()? shouldAbort,
    bool Function()? shouldPause,
    int concurrency = 4,
  }) async {
    final selectedItems = items.where((e) => (e.isSelected && e.type == SyncType.file)).toList();
    if (selectedItems.isEmpty) return;

    // Calculate total bytes
    int totalBytes = 0;
    for (final item in selectedItems) {
      totalBytes += item.fileSize;
    }

    int completedCount = 0;
    int copiedBytes = 0;

    // ── Phase 1: File Transfer (Smallest First) ──
    // Note: Directories are created on-demand when a file needs to be copied.
    
    final files = selectedItems; // We only have files now
    files.sort((a, b) => a.fileSize.compareTo(b.fileSize));

    final smallFiles = files.where((e) => e.fileSize <= _largeFileThreshold).toList();
    final largeFiles = files.where((e) => e.fileSize > _largeFileThreshold).toList();

    // 1a. Process Small Files in Chunks
    if (smallFiles.isNotEmpty) {
      const int chunkSize = 50; 
      for (int i = 0; i < smallFiles.length; i += chunkSize) {
        if (shouldAbort != null && shouldAbort()) break;
        while (shouldPause != null && shouldPause()) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final end = (i + chunkSize > smallFiles.length) ? smallFiles.length : i + chunkSize;
        final chunk = smallFiles.sublist(i, end);

        // Ensure directories exist for all files in chunk
        for (final item in chunk) {
          final String toPath = item.status == FileStatus.missingInSource ? item.sourcePath : item.targetPath;
          await Directory(File(toPath).parent.path).create(recursive: true);
        }

        if (NativeFileTransfer.isAvailable) {
          final batchItems = chunk.map((item) {
            final bool isToSource = item.status == FileStatus.missingInSource;
            return {
              'src': isToSource ? item.targetPath : item.sourcePath,
              'dst': isToSource ? item.sourcePath : item.targetPath,
            };
          }).toList();

          // Use static helper to avoid Isolate scope capture issues
          await _runBatchInIsolate(batchItems, concurrency);

          for (final item in chunk) {
            completedCount++;
            copiedBytes += item.fileSize;
            onProgress?.call(item, completedCount, selectedItems.length, copiedBytes, totalBytes, 0);
          }
        } else {
          await Future.wait(chunk.map((item) async {
            await _copyItem(item);
            completedCount++;
            copiedBytes += item.fileSize;
            onProgress?.call(item, completedCount, selectedItems.length, copiedBytes, totalBytes, 0);
          }));
        }
      }
    }

    // 1b. Process Large Files (Sequential)
    for (final item in largeFiles) {
      if (shouldAbort != null && shouldAbort()) break;
      while (shouldPause != null && shouldPause()) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (shouldAbort != null && shouldAbort()) break;
      }

      int lastItemBytes = 0;
      await _copyItem(item, onByteProgress: (b) {
        final delta = b - lastItemBytes;
        copiedBytes += delta;
        lastItemBytes = b;
        onProgress?.call(item, completedCount, selectedItems.length, copiedBytes, totalBytes, b);
      });

      completedCount++;
      onProgress?.call(item, completedCount, selectedItems.length, copiedBytes, totalBytes, 0);
    }
  }

  /// Static helper to avoid closure capture of non-sendable fields like SyncNotifier in Isolate.run
  static Future<int> _runBatchInIsolate(List<Map<String, String>> items, int concurrency) {
    return Isolate.run(() => NativeFileTransfer.copyBatch(items, concurrency: concurrency));
  }

  /// Static helper for individual file copy to avoid scope capture
  static Future<int> _runCopyFileInIsolate(String from, String to) {
    return Isolate.run(() => NativeFileTransfer.copyFile(from, to));
  }

  static Future<void> _copyItem(SyncItem item, {Function(int bytesRead)? onByteProgress}) async {
    final bool isToSource = item.status == FileStatus.missingInSource;
    final String fromPath = isToSource ? item.targetPath : item.sourcePath;
    final String toPath = isToSource ? item.sourcePath : item.targetPath;

    if (item.type == SyncType.directory) {
      // Directories are created on-demand by files.
      // If we directly sync a directory item (uncommon now), we can create it.
      await Directory(toPath).create(recursive: true);
    } else {
      await Directory(File(toPath).parent.path).create(recursive: true);
      
      if (NativeFileTransfer.isAvailable) {
        if (item.fileSize > _largeFileThreshold) {
          final receivePort = ReceivePort();
          await Isolate.spawn(_nativeCopyWorker, {
            'src': fromPath,
            'dst': toPath,
            'port': receivePort.sendPort,
            'isLarge': true,
          });

          await for (final message in receivePort) {
            if (message is int) {
              onByteProgress?.call(message);
            } else if (message == 'done') {
              break;
            } else if (message is String && message.startsWith('error')) {
              break;
            }
          }
          receivePort.close();
        } else {
          // Wrap in static helper to avoid closure capture issues
           final result = await _runCopyFileInIsolate(fromPath, toPath);
           if (result == 0) {
             onByteProgress?.call(item.fileSize);
           }
        }
      } else {
        // Fallback
        if (item.fileSize > _largeFileThreshold) {
          await _copyFileOptimized(fromPath, toPath, onByteProgress: onByteProgress);
        } else {
          await File(fromPath).copy(toPath);
          onByteProgress?.call(item.fileSize);
        }
      }
    }
  }

  static void _nativeCopyWorker(Map<String, dynamic> args) async {
    final String src = args['src'];
    final String dst = args['dst'];
    final SendPort port = args['port'];
    final bool isLarge = args['isLarge'];

    try {
      final result = await NativeFileTransfer.copyFile(
        src,
        dst,
        onProgress: isLarge ? (bytes) => port.send(bytes) : null,
      );
      if (result == 0) {
        port.send('done');
      } else {
        port.send('error: $result');
      }
    } catch (e) {
      port.send('error: $e');
    }
  }

  static Future<void> _copyFileOptimized(String from, String to, {Function(int bytesRead)? onByteProgress}) async {
    final sourceFile = await File(from).open(mode: FileMode.read);
    final targetFile = await File(to).open(mode: FileMode.write);
    
    try {
      final buffer = Uint8List(_bufferSize);
      int totalRead = 0;
      int bytesRead;
      while ((bytesRead = await sourceFile.readInto(buffer)) > 0) {
        await targetFile.writeFrom(buffer, 0, bytesRead);
        totalRead += bytesRead;
        onByteProgress?.call(totalRead);
      }
    } finally {
      await sourceFile.close();
      await targetFile.close();
    }
  }
}
