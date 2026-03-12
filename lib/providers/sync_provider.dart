import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_item.dart';
import '../services/comparison_service.dart';
import '../services/sync_service.dart';

class SyncState {
  final String? sourcePath;
  final String? targetPath;
  final List<SyncItem> items;
  final bool isComparing;
  final bool isSyncing;
  final bool isTwoWaySync;
  final AppMode currentMode;
  final double syncProgress;

  SyncState({
    this.sourcePath,
    this.targetPath,
    this.items = const [],
    this.isComparing = false,
    this.isSyncing = false,
    this.isTwoWaySync = false,
    this.currentMode = AppMode.selection,
    this.syncProgress = 0.0,
  });

  SyncState copyWith({
    String? sourcePath,
    String? targetPath,
    List<SyncItem>? items,
    bool? isComparing,
    bool? isSyncing,
    bool? isTwoWaySync,
    AppMode? currentMode,
    double? syncProgress,
  }) {
    return SyncState(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      items: items ?? this.items,
      isComparing: isComparing ?? this.isComparing,
      isSyncing: isSyncing ?? this.isSyncing,
      isTwoWaySync: isTwoWaySync ?? this.isTwoWaySync,
      currentMode: currentMode ?? this.currentMode,
      syncProgress: syncProgress ?? this.syncProgress,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    return SyncState();
  }

  void setMode(AppMode mode) {
    state = state.copyWith(currentMode: mode);
  }

  void setSourcePath(String path) {
    state = state.copyWith(sourcePath: path);
    _compare();
  }

  void setTargetPath(String path) {
    state = state.copyWith(targetPath: path);
    _compare();
  }

  void toggleTwoWaySync(bool value) {
    state = state.copyWith(isTwoWaySync: value);
    _compare();
  }

  Future<void> _compare() async {
    if (state.sourcePath == null || state.targetPath == null) return;
    
    state = state.copyWith(isComparing: true);
    final items = await FolderComparisonService.compareFolders(
      state.sourcePath!,
      state.targetPath!,
      isTwoWaySync: state.isTwoWaySync,
    );
    state = state.copyWith(items: items, isComparing: false);
  }

  void toggleItemSelection(int index) {
    final newItems = List<SyncItem>.from(state.items);
    newItems[index].isSelected = !newItems[index].isSelected;
    state = state.copyWith(items: newItems);
  }

  void toggleAll(bool selected) {
    final newItems = state.items.map((item) {
      final newItem = SyncItem(
        relativePath: item.relativePath,
        sourcePath: item.sourcePath,
        targetPath: item.targetPath,
        type: item.type,
        status: item.status,
        isSelected: selected,
      );
      return newItem;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  Future<void> sync() async {
    if (state.items.isEmpty) return;
    
    state = state.copyWith(isSyncing: true, syncProgress: 0.0);
    
    await SyncService.syncItems(
      state.items,
      onProgress: (count, total) {
        state = state.copyWith(syncProgress: count / total);
      },
    );
    
    state = state.copyWith(isSyncing: false, syncProgress: 1.0);
    // Re-compare after sync to update list
    await _compare();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
