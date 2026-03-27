import '../models/sync_item.dart';

/// A data class holding file and folder counts.
class ItemCounts {
  final int fileCount;
  final int folderCount;

  const ItemCounts({this.fileCount = 0, this.folderCount = 0});

  int get totalCount => fileCount + folderCount;

  /// e.g. "3 files"
  String get summary => '$fileCount files';

  /// e.g. "3 files synced"
  String get syncedSummary => '$fileCount files synced';
}

/// Utility class for counting files and folders from a list of [SyncItem]s.
/// Can be used anywhere counts are needed (sync button, headers, reports, etc.).
class ItemCounter {
  /// Count all files and folders in the given list.
  static ItemCounts count(List<SyncItem> items) {
    int files = 0;
    int folders = 0;
    for (final item in items) {
      if (item.type == SyncType.file) {
        files++;
      } else if (item.type == SyncType.directory) {
        folders++;
      }
    }
    return ItemCounts(fileCount: files, folderCount: folders);
  }

  /// Count only selected files and folders.
  static ItemCounts countSelected(List<SyncItem> items) {
    int files = 0;
    int folders = 0;
    for (final item in items) {
      if (item.isSelected) {
        if (item.type == SyncType.file) {
          files++;
        } else if (item.type == SyncType.directory) {
          folders++;
        }
      }
    }
    return ItemCounts(fileCount: files, folderCount: folders);
  }

  /// Count files and folders that need syncing (non-identical status).
  static ItemCounts countSyncable(List<SyncItem> items, {required bool isTwoWay}) {
    int files = 0;
    int folders = 0;
    for (final item in items) {
      final bool syncable = isTwoWay
          ? item.status != FileStatus.identical
          : (item.status == FileStatus.missingInTarget ||
              item.status == FileStatus.different);
      if (syncable) {
        if (item.type == SyncType.file) {
          files++;
        } else if (item.type == SyncType.directory) {
          folders++;
        }
      }
    }
    return ItemCounts(fileCount: files, folderCount: folders);
  }

  /// Create [ItemCounts] from pre-computed values.
  static ItemCounts fromValues(int fileCount, int folderCount) {
    return ItemCounts(fileCount: fileCount, folderCount: folderCount);
  }
}
