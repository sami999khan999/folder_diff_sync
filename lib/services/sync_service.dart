import 'dart:io';
import '../models/sync_item.dart';

class SyncService {
  static Future<void> syncItems(List<SyncItem> items, {Function(int, int)? onProgress}) async {
    int count = 0;
    for (var item in items) {
      if (!item.isSelected) continue;

      if (item.type == SyncType.directory) {
        await Directory(item.targetPath).create(recursive: true);
      } else {
        // Ensure parent directory exists
        final parentDir = Directory(item.targetPath).parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        await File(item.sourcePath).copy(item.targetPath);
      }
      
      count++;
      if (onProgress != null) {
        onProgress(count, items.length);
      }
    }
  }
}
