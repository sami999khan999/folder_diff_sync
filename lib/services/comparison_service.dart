import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/sync_item.dart';

class FolderComparisonService {
  static Future<List<SyncItem>> compareFolders(
      String sourcePath, String targetPath) async {
    final List<SyncItem> items = [];
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await sourceDir.exists() || !await targetDir.exists()) {
      return [];
    }

    final sourceEntities = await sourceDir.list(recursive: true).toList();

    for (var entity in sourceEntities) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final targetEntityPath = p.join(targetPath, relativePath);
      
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
          // Optional: Check if different (size comparison for speed)
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
        }
      }
    }

    return items;
  }
}
