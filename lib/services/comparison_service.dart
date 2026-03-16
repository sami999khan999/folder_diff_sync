import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../models/sync_item.dart';

class FolderComparisonService {
  /// Full recursive comparison (kept for sync purposes).
  static Future<List<SyncItem>> compareFolders(
      String sourcePath, String targetPath, {bool isTwoWay = true}) async {
    final List<SyncItem> items = [];
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await sourceDir.exists() || !await targetDir.exists()) {
      return [];
    }

    final sourceEntities = await sourceDir.list(recursive: true).toList();
    final Set<String> processedRelativePaths = {};

    for (var entity in sourceEntities) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final targetEntityPath = p.join(targetPath, relativePath);
      processedRelativePaths.add(relativePath);

      if (entity is File) {
        final targetFile = File(targetEntityPath);
        if (!await targetFile.exists()) {
          final stat = await entity.stat();
          items.add(SyncItem(
            relativePath: relativePath,
            sourcePath: entity.path,
            targetPath: targetEntityPath,
            type: SyncType.file,
            status: FileStatus.missingInTarget,
            fileSize: stat.size,
          ));
        } else {
          final sourceStat = await entity.stat();
          final targetStat = await targetFile.stat();
          if (sourceStat.size != targetStat.size) {
            items.add(SyncItem(
              relativePath: relativePath,
              sourcePath: entity.path,
              targetPath: targetEntityPath,
              type: SyncType.file,
              status: FileStatus.different,
              fileSize: sourceStat.size,
            ));
          } else {
            items.add(SyncItem(
              relativePath: relativePath,
              sourcePath: entity.path,
              targetPath: targetEntityPath,
              type: SyncType.file,
              status: FileStatus.identical,
              fileSize: sourceStat.size,
              isSelected: false,
            ));
          }
        }
      } else if (entity is Directory) {
        final targetSubDir = Directory(targetEntityPath);
        if (!await targetSubDir.exists()) {
          items.add(SyncItem(
            relativePath: relativePath,
            sourcePath: entity.path,
            targetPath: targetEntityPath,
            type: SyncType.directory,
            status: FileStatus.missingInTarget,
          ));
        } else {
          items.add(SyncItem(
            relativePath: relativePath,
            sourcePath: entity.path,
            targetPath: targetEntityPath,
            type: SyncType.directory,
            status: FileStatus.identical,
            isSelected: false,
          ));
        }
      }
    }

    final targetEntities = await targetDir.list(recursive: true).toList();
    for (var entity in targetEntities) {
      final relativePath = p.relative(entity.path, from: targetPath);
      if (processedRelativePaths.contains(relativePath)) continue;

      final sourceEntityPath = p.join(sourcePath, relativePath);

      if (entity is File) {
        int size = 0;
        try { size = (await entity.stat()).size; } catch (_) {}
        items.add(SyncItem(
          relativePath: relativePath,
          sourcePath: sourceEntityPath,
          targetPath: entity.path,
          type: SyncType.file,
          status: FileStatus.missingInSource,
          fileSize: size,
        ));
      } else if (entity is Directory) {
        items.add(SyncItem(
          relativePath: relativePath,
          sourcePath: sourceEntityPath,
          targetPath: entity.path,
          type: SyncType.directory,
          status: FileStatus.missingInSource,
        ));
      }
    }

    return items;
  }

  /// Recursive comparison with progressive updates.
  /// Uses a separate Isolate to stream results back in batches.
  static Future<void> compareFoldersProgressive(
      String sourcePath, String targetPath,
      {required Function(List<SyncItem> items) onBatch, bool isTwoWay = true}) async {
    final receivePort = ReceivePort();
    
    final isolate = await Isolate.spawn(_scanIsolateEntry, {
      'sendPort': receivePort.sendPort,
      'sourcePath': sourcePath,
      'targetPath': targetPath,
      'isTwoWay': isTwoWay,
    });

    try {
      await for (var message in receivePort) {
        if (message is List<SyncItem>) {
          onBatch(message);
        } else if (message == 'done') {
          break;
        } else if (message is String && message.startsWith('error:')) {
          break;
        }
      }
    } finally {
      receivePort.close();
      isolate.kill();
    }
  }

  static void _scanIsolateEntry(Map<String, dynamic> args) async {
    final SendPort sendPort = args['sendPort'];
    final String sourcePath = args['sourcePath'];
    final String targetPath = args['targetPath'];
    final bool isTwoWay = args['isTwoWay'];

    try {
      final Set<String> processedRelativePaths = {};
      
      // 1. Scan Source
      await _scanWork(
        rootPath: sourcePath,
        otherRootPath: targetPath,
        isSourceScan: true,
        sendPort: sendPort,
        processedPaths: processedRelativePaths,
      );

      // 2. Scan Target for missing items (if Two-Way)
      if (isTwoWay) {
        await _scanWork(
          rootPath: targetPath,
          otherRootPath: sourcePath,
          isSourceScan: false,
          sendPort: sendPort,
          processedPaths: processedRelativePaths,
        );
      }
      
      sendPort.send('done');
    } catch (e) {
      sendPort.send('error: $e');
    }
  }

  static Future<void> _scanWork({
    required String rootPath,
    required String otherRootPath,
    required bool isSourceScan,
    required SendPort sendPort,
    required Set<String> processedPaths,
  }) async {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return;

    final List<SyncItem> currentBatch = [];
    const int batchSize = 100;

    // We use BFS/Manual recursion instead of recursive: true to catch errors per folder
    final queue = <Directory>[dir];

    while (queue.isNotEmpty) {
      final currentDir = queue.removeAt(0);
      
      try {
        final List<FileSystemEntity> entities = currentDir.listSync(recursive: false);
        for (final entity in entities) {
          final relativePath = p.relative(entity.path, from: rootPath);
          
          if (!isSourceScan && processedPaths.contains(relativePath)) {
            // If scanning target, skip if already processed in source scan
            if (entity is Directory) queue.add(entity); // But still explore subdirs
            continue;
          }

          if (isSourceScan) processedPaths.add(relativePath);

          final otherEntityPath = p.join(otherRootPath, relativePath);

          if (entity is File) {
            if (isSourceScan) {
              final otherFile = File(otherEntityPath);
              final stat = entity.statSync();
              if (!otherFile.existsSync()) {
                currentBatch.add(SyncItem(
                  relativePath: relativePath,
                  sourcePath: entity.path,
                  targetPath: otherEntityPath,
                  type: SyncType.file,
                  status: FileStatus.missingInTarget,
                  fileSize: stat.size,
                ));
              } else {
                final targetStat = otherFile.statSync();
                if (stat.size != targetStat.size) {
                  currentBatch.add(SyncItem(
                    relativePath: relativePath,
                    sourcePath: entity.path,
                    targetPath: otherEntityPath,
                    type: SyncType.file,
                    status: FileStatus.different,
                    fileSize: stat.size,
                  ));
                } else {
                  currentBatch.add(SyncItem(
                    relativePath: relativePath,
                    sourcePath: entity.path,
                    targetPath: otherEntityPath,
                    type: SyncType.file,
                    status: FileStatus.identical,
                    fileSize: stat.size,
                    isSelected: false,
                  ));
                }
              }
            } else {
              int size = 0;
              try { size = entity.statSync().size; } catch (_) {}
              currentBatch.add(SyncItem(
                relativePath: relativePath,
                sourcePath: otherEntityPath,
                targetPath: entity.path,
                type: SyncType.file,
                status: FileStatus.missingInSource,
                fileSize: size,
              ));
            }
          } else if (entity is Directory) {
            if (isSourceScan) {
              final otherDir = Directory(otherEntityPath);
              currentBatch.add(SyncItem(
                relativePath: relativePath,
                sourcePath: entity.path,
                targetPath: otherEntityPath,
                type: SyncType.directory,
                status: otherDir.existsSync() ? FileStatus.identical : FileStatus.missingInTarget,
                isSelected: false,
              ));
            } else {
              currentBatch.add(SyncItem(
                relativePath: relativePath,
                sourcePath: otherEntityPath,
                targetPath: entity.path,
                type: SyncType.directory,
                status: FileStatus.missingInSource,
                isSelected: false,
              ));
            }
            queue.add(entity);
          }

          if (currentBatch.length >= batchSize) {
            sendPort.send(List<SyncItem>.from(currentBatch));
            currentBatch.clear();
          }
        }
      } catch (e) {
        // Skip restricted / error folders
      }
    }

    if (currentBatch.isNotEmpty) {
      sendPort.send(List<SyncItem>.from(currentBatch));
      currentBatch.clear();
    }
  }

  /// Shallow comparison — only scans up to [maxDepth] levels deep.
  /// Used for the initial tree load to avoid scanning huge directory trees.
  static Future<List<SyncItem>> compareFoldersShallow(
      String sourcePath, String targetPath, {int maxDepth = 2, bool isTwoWay = true}) async {
    final List<SyncItem> items = [];
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await sourceDir.exists() || !await targetDir.exists()) {
      return [];
    }

    final Set<String> processedRelativePaths = {};

    // BFS from source with depth limit
    await _scanDirectoryBFS(
      sourceDir, sourcePath, targetPath, items, processedRelativePaths,
      maxDepth: maxDepth, isSource: true,
    );

    // BFS from target for items missing in source (if Two-Way)
    if (isTwoWay) {
      await _scanDirectoryBFS(
        targetDir, targetPath, sourcePath, items, processedRelativePaths,
        maxDepth: maxDepth, isSource: false,
      );
    }

    return items;
  }

  /// Compares a single subfolder's immediate children (1 level).
  /// [relativeBase] is the relative path of the folder being expanded.
  static Future<List<SyncItem>> compareSubfolder(
      String sourcePath, String targetPath, String relativeBase, {bool isTwoWay = true}) async {
    final List<SyncItem> items = [];
    final sourceSubDir = Directory(p.join(sourcePath, relativeBase));
    final targetSubDir = Directory(p.join(targetPath, relativeBase));

    final Set<String> processedRelativePaths = {};

    // Scan source subfolder (non-recursive)
    if (await sourceSubDir.exists()) {
      try {
        final entities = await sourceSubDir.list(recursive: false).toList();
        for (var entity in entities) {
          final relativePath = p.relative(entity.path, from: sourcePath);
          final targetEntityPath = p.join(targetPath, relativePath);
          processedRelativePaths.add(relativePath);

          if (entity is File) {
            items.add(await _compareFileEntity(
                entity, relativePath, targetEntityPath));
          } else if (entity is Directory) {
            items.add(await _compareDirEntity(
                entity, relativePath, targetEntityPath));
          }
        }
      } catch (_) {}
    }

    // Scan target subfolder for items missing in source (if Two-Way)
    if (isTwoWay) {
      if (await targetSubDir.exists()) {
        try {
          final entities = await targetSubDir.list(recursive: false).toList();
          for (var entity in entities) {
            final relativePath = p.relative(entity.path, from: targetPath);
            if (processedRelativePaths.contains(relativePath)) continue;

            final sourceEntityPath = p.join(sourcePath, relativePath);

            if (entity is File) {
              items.add(SyncItem(
                relativePath: relativePath,
                sourcePath: sourceEntityPath,
                targetPath: entity.path,
                type: SyncType.file,
                status: FileStatus.missingInSource,
              ));
            } else if (entity is Directory) {
              items.add(SyncItem(
                relativePath: relativePath,
                sourcePath: sourceEntityPath,
                targetPath: entity.path,
                type: SyncType.directory,
                status: FileStatus.missingInSource,
              ));
            }
          }
        } catch (_) {}
      }
    }

    return items;
  }

  // ── Private helpers ──

  static Future<void> _scanDirectoryBFS(
    Directory rootDir,
    String rootPath,
    String otherRootPath,
    List<SyncItem> items,
    Set<String> processedRelativePaths, {
    required int maxDepth,
    required bool isSource,
  }) async {
    // Queue holds (directory, currentDepth)
    final queue = <(Directory, int)>[(rootDir, 0)];

    while (queue.isNotEmpty) {
      final (dir, depth) = queue.removeAt(0);
      if (depth >= maxDepth) continue;

      try {
        final entities = await dir.list(recursive: false).toList();
        for (var entity in entities) {
          final relativePath = p.relative(entity.path, from: rootPath);

          if (isSource) {
            final otherEntityPath = p.join(otherRootPath, relativePath);
            processedRelativePaths.add(relativePath);

            if (entity is File) {
              items.add(await _compareFileEntity(
                  entity, relativePath, otherEntityPath));
            } else if (entity is Directory) {
              items.add(await _compareDirEntity(
                  entity, relativePath, otherEntityPath));
              queue.add((entity, depth + 1));
            }
          } else {
            // Target scan — only add items not already processed
            if (processedRelativePaths.contains(relativePath)) {
              if (entity is Directory) {
                queue.add((entity, depth + 1));
              }
              continue;
            }

            final otherEntityPath = p.join(otherRootPath, relativePath);

            if (entity is File) {
              int size = 0;
              try { size = entity.statSync().size; } catch (_) {}
              items.add(SyncItem(
                relativePath: relativePath,
                sourcePath: otherEntityPath,
                targetPath: entity.path,
                type: SyncType.file,
                status: FileStatus.missingInSource,
                fileSize: size,
              ));
            } else if (entity is Directory) {
              items.add(SyncItem(
                relativePath: relativePath,
                sourcePath: otherEntityPath,
                targetPath: entity.path,
                type: SyncType.directory,
                status: FileStatus.missingInSource,
              ));
              queue.add((entity, depth + 1));
            }
          }
        }
      } catch (_) {
        // Skip directories we can't access
      }
    }
  }

  static Future<SyncItem> _compareFileEntity(
      File entity, String relativePath, String targetEntityPath) async {
    final targetFile = File(targetEntityPath);
    if (!await targetFile.exists()) {
      final stat = await entity.stat();
      return SyncItem(
        relativePath: relativePath,
        sourcePath: entity.path,
        targetPath: targetEntityPath,
        type: SyncType.file,
        status: FileStatus.missingInTarget,
        fileSize: stat.size,
      );
    }
    final sourceStat = await entity.stat();
    final targetStat = await targetFile.stat();
    if (sourceStat.size != targetStat.size) {
      return SyncItem(
        relativePath: relativePath,
        sourcePath: entity.path,
        targetPath: targetEntityPath,
        type: SyncType.file,
        status: FileStatus.different,
        fileSize: sourceStat.size,
      );
    }
    return SyncItem(
      relativePath: relativePath,
      sourcePath: entity.path,
      targetPath: targetEntityPath,
      type: SyncType.file,
      status: FileStatus.identical,
      fileSize: sourceStat.size,
      isSelected: false,
    );
  }

  static Future<SyncItem> _compareDirEntity(
      FileSystemEntity entity, String relativePath, String targetEntityPath) async {
    final targetSubDir = Directory(targetEntityPath);
    if (!await targetSubDir.exists()) {
      return SyncItem(
        relativePath: relativePath,
        sourcePath: entity.path,
        targetPath: targetEntityPath,
        type: SyncType.directory,
        status: FileStatus.missingInTarget,
      );
    }
    return SyncItem(
      relativePath: relativePath,
      sourcePath: entity.path,
      targetPath: targetEntityPath,
      type: SyncType.directory,
      status: FileStatus.identical,
      isSelected: false,
    );
  }
}
