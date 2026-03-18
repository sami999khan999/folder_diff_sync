import 'package:flutter_test/flutter_test.dart';
import 'package:folder_diff_sync/models/sync_item.dart';
import 'package:folder_diff_sync/providers/sync_provider.dart';

void main() {
  group('SyncState updateWithCounts', () {
    test('One-way sync (Source -> Target) correctly filters diffCount', () {
      final state = SyncState(isTwoWaySync: false);
      
      final allItems = [
        SyncItem(
          relativePath: 'source_only.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.missingInTarget,
          fileSize: 100,
        ),
        SyncItem(
          relativePath: 'different.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.different,
          fileSize: 200,
        ),
        SyncItem(
          relativePath: 'target_only.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.missingInSource,
          fileSize: 300,
        ),
        SyncItem(
          relativePath: 'identical.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.identical,
          fileSize: 400,
        ),
        SyncItem(
          relativePath: 'folder',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.directory,
          status: FileStatus.missingInTarget,
          fileSize: 0,
        ),
      ];

      final updated = state.updateWithCounts(allItems);

      // In one-way sync (Source -> Target), only missingInTarget and different are syncable
      // diffCount should be 2 (source_only, different)
      expect(updated.diffCount, 2);
    });

    test('Two-way sync correctly counts all differences', () {
      final state = SyncState(isTwoWaySync: true);
      
      final allItems = [
        SyncItem(
          relativePath: 'source_only.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.missingInTarget,
          fileSize: 100,
        ),
        SyncItem(
          relativePath: 'target_only.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.missingInSource,
          fileSize: 200,
        ),
        SyncItem(
          relativePath: 'different.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.different,
          fileSize: 300,
        ),
        SyncItem(
          relativePath: 'identical.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.identical,
          fileSize: 400,
        ),
      ];

      final updated = state.updateWithCounts(allItems);

      // In two-way sync, all non-identical items are syncable
      // diffCount should be 3 (source_only, target_only, different)
      expect(updated.diffCount, 3);
    });

    test('selectedCount only counts files', () {
      final state = SyncState(isTwoWaySync: true);
      
      final allItems = [
        SyncItem(
          relativePath: 'file1.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.different,
          fileSize: 100,
          isSelected: true,
        ),
        SyncItem(
          relativePath: 'file2.txt',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.file,
          status: FileStatus.different,
          fileSize: 100,
          isSelected: true,
        ),
        SyncItem(
          relativePath: 'folder',
          sourcePath: 'src',
          targetPath: 'dst',
          type: SyncType.directory,
          status: FileStatus.different,
          fileSize: 0,
          isSelected: true,
        ),
      ];

      final updated = state.updateWithCounts(allItems);

      // selectedCount should be 2 (only files)
      expect(updated.selectedCount, 2);
      expect(updated.totalSelectedSize, 200);
    });
  });
}
