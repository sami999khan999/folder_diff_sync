import 'dart:io';
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
          items.add(SyncItem(
            relativePath: relativePath,
            sourcePath: entity.path,
            targetPath: targetEntityPath,
            type: SyncType.file,
            status: FileStatus.missingInTarget,
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
            ));
          } else {
            items.add(SyncItem(
              relativePath: relativePath,
              sourcePath: entity.path,
              targetPath: targetEntityPath,
              type: SyncType.file,
              status: FileStatus.identical,
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

    return items;
  }

  /// Recursive comparison with progressive updates.
  static Future<void> compareFoldersProgressive(
      String sourcePath, String targetPath,
      {required Function(List<SyncItem> items) onBatch, bool isTwoWay = true}) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await sourceDir.exists() || !await targetDir.exists()) {
      return;
    }

    final List<SyncItem> currentBatch = [];
    const int batchSize = 10; // Smaller batch size for more immediate updates
    final Set<String> processedRelativePaths = {};

    void flush() {
      if (currentBatch.isNotEmpty) {
        onBatch(List.from(currentBatch));
        currentBatch.clear();
      }
    }

    // 1. Scan Source for items
    try {
      await for (var entity in sourceDir.list(recursive: true, followLinks: false)) {
        final relativePath = p.relative(entity.path, from: sourcePath);
        final targetEntityPath = p.join(targetPath, relativePath);
        processedRelativePaths.add(relativePath);

        if (entity is File) {
          currentBatch.add(await _compareFileEntity(
              entity, relativePath, targetEntityPath));
        } else if (entity is Directory) {
          currentBatch.add(await _compareDirEntity(
              entity, relativePath, targetEntityPath));
        }

        if (currentBatch.length >= batchSize) flush();
      }
    } catch (_) {}

    flush();

    // 2. Scan Target for items missing in Source (if Two-Way)
    if (isTwoWay) {
      try {
        await for (var entity in targetDir.list(recursive: true, followLinks: false)) {
          final relativePath = p.relative(entity.path, from: targetPath);
          if (processedRelativePaths.contains(relativePath)) continue;

          final sourceEntityPath = p.join(sourcePath, relativePath);

          if (entity is File) {
            currentBatch.add(SyncItem(
              relativePath: relativePath,
              sourcePath: sourceEntityPath,
              targetPath: entity.path,
              type: SyncType.file,
              status: FileStatus.missingInSource,
            ));
          } else if (entity is Directory) {
            currentBatch.add(SyncItem(
              relativePath: relativePath,
              sourcePath: sourceEntityPath,
              targetPath: entity.path,
              type: SyncType.directory,
              status: FileStatus.missingInSource,
            ));
          }

          if (currentBatch.length >= batchSize) flush();
        }
      } catch (_) {}
    }

    flush();
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
              items.add(SyncItem(
                relativePath: relativePath,
                sourcePath: otherEntityPath,
                targetPath: entity.path,
                type: SyncType.file,
                status: FileStatus.missingInSource,
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
      return SyncItem(
        relativePath: relativePath,
        sourcePath: entity.path,
        targetPath: targetEntityPath,
        type: SyncType.file,
        status: FileStatus.missingInTarget,
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
      );
    }
    return SyncItem(
      relativePath: relativePath,
      sourcePath: entity.path,
      targetPath: targetEntityPath,
      type: SyncType.file,
      status: FileStatus.identical,
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
