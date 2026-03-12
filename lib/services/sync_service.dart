import 'dart:io';
import '../models/sync_item.dart';

class SyncService {
  static Future<void> syncItems(List<SyncItem> items, {Function(int, int)? onProgress}) async {
    int count = 0;
    for (var item in items) {
      if (!item.isSelected) continue;

      final bool isToSource = item.status == FileStatus.missingInSource;
      final String fromPath = isToSource ? item.targetPath : item.sourcePath;
      final String toPath = isToSource ? item.sourcePath : item.targetPath;

      if (item.type == SyncType.directory) {
        await Directory(toPath).create(recursive: true);
      } else {
        // Ensure parent directory exists
        final parentDir = Directory(toPath).parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        await File(fromPath).copy(toPath);
      }
      
      count++;
      if (onProgress != null) {
        onProgress(count, items.length);
      }
    }
  }
}
