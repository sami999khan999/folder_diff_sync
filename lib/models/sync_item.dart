import 'dart:io';

enum FileStatus {
  missingInTarget, // Exists in Source, missing in Target
  missingInSource, // Exists in Target, missing in Source
  different,       // Exists in both, but different (e.g. size or date)
  identical,       // Exists in both, same
}

enum SyncType {
  file,
  directory,
}

class SyncItem {
  final String relativePath;
  final String sourcePath;
  final String targetPath;
  final SyncType type;
  final FileStatus status;
  bool isSelected;

  SyncItem({
    required this.relativePath,
    required this.sourcePath,
    required this.targetPath,
    required this.type,
    required this.status,
    this.isSelected = true,
  });

  String get name => relativePath.split(Platform.pathSeparator).last;
}
