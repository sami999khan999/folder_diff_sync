import 'dart:io';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/sync_item.dart';
import '../services/comparison_service.dart';
import '../services/sync_service.dart';

class SyncTreeNode {
  SyncItem? item;
  final String name;
  final String relativePath;
  final bool isDirectory;
  final List<SyncTreeNode> children;
  final int depth;
  bool isExpanded;
  bool isSelected;
  bool isLoaded;
  bool isLoading;
  int childLimit;

  SyncTreeNode({
    this.item,
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    required this.depth,
    this.children = const [],
    this.isExpanded = false,
    this.isSelected = false,
    this.isLoaded = true,
    this.isLoading = false,
    this.childLimit = 100,
  });

  bool get needsSync {
    if (item != null && item!.status != FileStatus.identical) return true;
    return children.any((child) => child.needsSync);
  }
}

class SyncState {
  final String? sourcePath;
  final String? targetPath;
  final List<SyncTreeNode> treeNodes;
  final bool isComparing;
  final bool isSyncing;
  final bool isTwoWaySync;
  final AppMode currentMode;
  final bool isBackgroundScanning;
  final int scannedItemsCount;
  final int selectedCount;
  final int totalSelectedSize;
  final int sidebarItemLimit;
  final double syncProgress;
  final String? syncingFileName;
  final int syncedCount;
  final int syncTotalCount;
  final int syncedBytes;
  final int syncTotalBytes;
  final int syncedFilesCount;
  final int syncedFoldersCount;
  final int totalFilesToSync;
  final int totalFoldersToSync;
  final int itemsRevision;
  final bool isScanPaused;
  final bool isSyncPaused;
  final bool isSyncStopped;
  final bool isBackgroundScanComplete;
  final int diffCount;
  final int diffFoldersCount;
  final int selectedFoldersCount;
  final String sidebarSearchQuery;
  final SidebarSortOrder sidebarSortOrder;
  final int syncingFileBytes;
  final int syncingFileTotalBytes;
  final double syncSpeed; // Bytes per second
  final Duration? remainingTime;
  final int speedLimit; // MB/s, 0 = unlimited
  final bool isSpeedLimitEnabled;
  final List<SyncItem> sidebarItems;

  SyncState({
    this.sourcePath,
    this.targetPath,
    this.treeNodes = const [],
    this.isComparing = false,
    this.isSyncing = false,
    this.isTwoWaySync = false,
    this.currentMode = AppMode.selection,
    this.isBackgroundScanning = false,
    this.scannedItemsCount = 0,
    this.selectedCount = 0,
    this.totalSelectedSize = 0,
    this.sidebarItemLimit = 50,
    this.syncProgress = 0.0,
    this.syncingFileName,
    this.syncedCount = 0,
    this.syncTotalCount = 0,
    this.syncedBytes = 0,
    this.syncTotalBytes = 0,
    this.syncedFilesCount = 0,
    this.syncedFoldersCount = 0,
    this.totalFilesToSync = 0,
    this.totalFoldersToSync = 0,
    this.itemsRevision = 0,
    this.isScanPaused = false,
    this.isSyncPaused = false,
    this.isSyncStopped = false,
    this.isBackgroundScanComplete = false,
    this.diffCount = 0,
    this.diffFoldersCount = 0,
    this.selectedFoldersCount = 0,
    this.sidebarSearchQuery = '',
    this.sidebarSortOrder = SidebarSortOrder.name,
    this.syncingFileBytes = 0,
    this.syncingFileTotalBytes = 0,
    this.syncSpeed = 0.0,
    this.remainingTime,
    this.speedLimit = 0,
    this.isSpeedLimitEnabled = false,
    this.sidebarItems = const [],
  });

  SyncState copyWith({
    String? sourcePath,
    String? targetPath,
    List<SyncTreeNode>? treeNodes,
    bool? isComparing,
    bool? isSyncing,
    bool? isTwoWaySync,
    AppMode? currentMode,
    bool? isBackgroundScanning,
    int? scannedItemsCount,
    int? selectedCount,
    int? totalSelectedSize,
    int? sidebarItemLimit,
    double? syncProgress,
    String? syncingFileName,
    int? syncedCount,
    int? syncTotalCount,
    int? syncedBytes,
    int? syncTotalBytes,
    int? syncedFilesCount,
    int? syncedFoldersCount,
    int? totalFilesToSync,
    int? totalFoldersToSync,
    int? itemsRevision,
    bool? isScanPaused,
    bool? isSyncPaused,
    bool? isSyncStopped,
    bool? isBackgroundScanComplete,
    int? diffCount,
    int? diffFoldersCount,
    int? selectedFoldersCount,
    String? sidebarSearchQuery,
    SidebarSortOrder? sidebarSortOrder,
    int? syncingFileBytes,
    int? syncingFileTotalBytes,
    double? syncSpeed,
    Duration? remainingTime,
    int? speedLimit,
    bool? isSpeedLimitEnabled,
    List<SyncItem>? sidebarItems,
  }) {
    return SyncState(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      treeNodes: treeNodes ?? this.treeNodes,
      isComparing: isComparing ?? this.isComparing,
      isSyncing: isSyncing ?? this.isSyncing,
      isTwoWaySync: isTwoWaySync ?? this.isTwoWaySync,
      currentMode: currentMode ?? this.currentMode,
      isBackgroundScanning: isBackgroundScanning ?? this.isBackgroundScanning,
      scannedItemsCount: scannedItemsCount ?? this.scannedItemsCount,
      selectedCount: selectedCount ?? this.selectedCount,
      totalSelectedSize: totalSelectedSize ?? this.totalSelectedSize,
      sidebarItemLimit: sidebarItemLimit ?? this.sidebarItemLimit,
      syncProgress: syncProgress ?? this.syncProgress,
      syncingFileName: syncingFileName ?? this.syncingFileName,
      syncedCount: syncedCount ?? this.syncedCount,
      syncTotalCount: syncTotalCount ?? this.syncTotalCount,
      syncedBytes: syncedBytes ?? this.syncedBytes,
      syncTotalBytes: syncTotalBytes ?? this.syncTotalBytes,
      syncedFilesCount: syncedFilesCount ?? this.syncedFilesCount,
      syncedFoldersCount: syncedFoldersCount ?? this.syncedFoldersCount,
      totalFilesToSync: totalFilesToSync ?? this.totalFilesToSync,
      totalFoldersToSync: totalFoldersToSync ?? this.totalFoldersToSync,
      itemsRevision: itemsRevision ?? this.itemsRevision,
      isScanPaused: isScanPaused ?? this.isScanPaused,
      isSyncPaused: isSyncPaused ?? this.isSyncPaused,
      isSyncStopped: isSyncStopped ?? this.isSyncStopped,
      isBackgroundScanComplete: isBackgroundScanComplete ?? this.isBackgroundScanComplete,
      diffCount: diffCount ?? this.diffCount,
      diffFoldersCount: diffFoldersCount ?? this.diffFoldersCount,
      selectedFoldersCount: selectedFoldersCount ?? this.selectedFoldersCount,
      sidebarSearchQuery: sidebarSearchQuery ?? this.sidebarSearchQuery,
      sidebarSortOrder: sidebarSortOrder ?? this.sidebarSortOrder,
      syncingFileBytes: syncingFileBytes ?? this.syncingFileBytes,
      syncingFileTotalBytes: syncingFileTotalBytes ?? this.syncingFileTotalBytes,
      syncSpeed: syncSpeed ?? this.syncSpeed,
      remainingTime: remainingTime ?? this.remainingTime,
      speedLimit: speedLimit ?? this.speedLimit,
      isSpeedLimitEnabled: isSpeedLimitEnabled ?? this.isSpeedLimitEnabled,
      sidebarItems: sidebarItems ?? this.sidebarItems,
    );
  }

  SyncState updateWithCounts(List<SyncItem> allItems) {
    final diffFiles = allItems.where((e) => e.type == SyncType.file && _isItemSyncable(e, isTwoWay: isTwoWaySync)).toList();
    final diffFolders = allItems.where((e) => e.type == SyncType.directory && _isItemSyncable(e, isTwoWay: isTwoWaySync)).toList();
    final selectedFiles = allItems.where((e) => e.isSelected && e.type == SyncType.file).toList();
    final selectedFolders = allItems.where((e) => e.isSelected && e.type == SyncType.directory).toList();
    
    return copyWith(
      diffCount: diffFiles.length,
      diffFoldersCount: diffFolders.length,
      selectedCount: selectedFiles.length,
      selectedFoldersCount: selectedFolders.length,
      totalSelectedSize: selectedFiles.fold<int>(0, (sum, item) => sum + item.fileSize),
    );
  }

  bool _isItemSyncable(SyncItem item, {required bool isTwoWay}) {
    if (isTwoWay) {
      return item.status != FileStatus.identical;
    } else {
      return item.status == FileStatus.missingInTarget ||
          item.status == FileStatus.different;
    }
  }
}

class SyncNotifier extends Notifier<SyncState> {
  // ── Mutable internal storage (NOT in immutable state) ──
  final List<SyncItem> _allItems = [];
  final Set<String> _scannedPaths = {};
  // Persistent hierarchical tree for O(1) updates and instant expansion
  final List<SyncTreeNode> _rootNodes = [];
  final Map<String, SyncTreeNode> _nodesMap = {};
  Isolate? _activeScanIsolate;
  Capability? _scanPauseCapability;

  // For selection inheritance during background scan
  final Set<String> _selectedPrefixes = {};

  // Scan generation counter to prevent stale callbacks
  int _scanGeneration = 0;

  @override
  SyncState build() {
    return SyncState();
  }

  // ── Public accessors for widgets that need the items list ──
  List<SyncItem> get allItems => _allItems;

  void setSidebarSearchQuery(String query) {
    state = state.copyWith(sidebarSearchQuery: query);
    _rebuildSidebarCache();
  }

  void setSpeedLimit(int limit) {
    state = state.copyWith(speedLimit: limit);
  }

  void toggleSpeedLimit(bool enabled) {
    state = state.copyWith(isSpeedLimitEnabled: enabled);
  }

  void setSidebarSortOrder(SidebarSortOrder order) {
    state = state.copyWith(sidebarSortOrder: order);
    _rebuildSidebarCache();
  }

  void _rebuildSidebarCache() {
    final query = state.sidebarSearchQuery.toLowerCase();
    
    // O(N) but only happens when search/select/scan changes, not every frame
    final filtered = _allItems.where((item) {
      final isSelected = item.isSelected;
      if (query.isEmpty) return isSelected;
      
      final matchesSearch = item.relativePath.toLowerCase().contains(query);
      return matchesSearch; // Show all matches during search as per previous "Add/Remove" requirement
    }).toList();

    // Apply Sorting
    switch (state.sidebarSortOrder) {
      case SidebarSortOrder.name:
        filtered.sort((a, b) => a.relativePath.compareTo(b.relativePath));
        break;
      case SidebarSortOrder.size:
        filtered.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case SidebarSortOrder.status:
        filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
    }

    state = state.copyWith(
      sidebarItems: filtered,
      selectedCount: _allItems.where((e) => e.isSelected && e.type == SyncType.file).length,
      selectedFoldersCount: _allItems.where((e) => e.isSelected && e.type == SyncType.directory).length,
      totalSelectedSize: _allItems.where((e) => e.isSelected && e.type == SyncType.file).fold<int>(0, (sum, item) => sum + item.fileSize),
      itemsRevision: state.itemsRevision + 1,
    );
  }

  void toggleItemSelectionByPath(String relativePath, bool selected) {
    if (state.isSyncing) return;
    final node = _nodesMap[relativePath];
    if (node != null) {
      // Use existing recursive selection logic
      toggleNodeSelection(node, selected);
    } else {
      final prefix = '$relativePath${Platform.pathSeparator}';
      for (final item in _allItems) {
        if (item.relativePath == relativePath || item.relativePath.startsWith(prefix)) {
          item.isSelected = selected;
        }
      }
      
      if (selected) {
        _selectedPrefixes.add(relativePath);
      } else {
        _selectedPrefixes.removeWhere((p) => p == relativePath || p.startsWith(prefix));
      }

      state = state.copyWith(
        selectedCount: _allItems.where((e) => e.isSelected && e.type == SyncType.file).length,
        selectedFoldersCount: _allItems.where((e) => e.isSelected && e.type == SyncType.directory).length,
        totalSelectedSize: _allItems.where((e) => e.isSelected && e.type == SyncType.file).fold<int>(0, (sum, item) => sum + (item.fileSize)),
        itemsRevision: state.itemsRevision + 1,
      );
      _rebuildSidebarCache();
    }
  }

  void toggleAll(bool selected) {
    if (state.isSyncing) return;
    final query = state.sidebarSearchQuery.toLowerCase();
    int totalCount = state.selectedCount;
    int totalSize = state.totalSelectedSize;

    if (query.isEmpty) {
      // 1. Update all items in the flat list
      for (var item in _allItems) {
        item.isSelected = selected;
      }

      // 2. Clear prefixes if deselecting, or mark root if selecting
      if (selected) {
        _selectedPrefixes.clear();
        _selectedPrefixes.add('');
        totalCount = _allItems.where((e) => e.isSelected && e.type == SyncType.file).length;
        totalSize = _allItems.where((e) => e.type == SyncType.file && e.isSelected).fold(0, (sum, item) => sum + item.fileSize);
      } else {
        _selectedPrefixes.clear();
        totalCount = 0;
        totalSize = 0;
      }

      // 3. Update the persistent tree nodes to keep UI in sync
      _updateSelectionRecursive(_rootNodes, selected);
    } else {
      // 1. Only affect items matching the search
      final filtered = _allItems.where((item) => 
        item.relativePath.toLowerCase().contains(query)).toList();
      
      for (var item in filtered) {
        if (item.isSelected != selected) {
          item.isSelected = selected;
          totalCount += selected ? 1 : -1;
          totalSize += selected ? item.fileSize : -item.fileSize;
        }
        
        final node = _nodesMap[item.relativePath];
        if (node != null) {
          _setSelectionRecursive(node, selected);
          // If it's a folder, we need to update children in the flat list too
          if (item.type == SyncType.directory) {
            final prefix = '${item.relativePath}${Platform.pathSeparator}';
            for (final child in _allItems) {
              if (child.relativePath.startsWith(prefix)) {
                if (child.isSelected != selected) {
                  child.isSelected = selected;
                  if (child.type == SyncType.file) {
                    totalCount += selected ? 1 : -1;
                    totalSize += selected ? child.fileSize : -child.fileSize;
                  }
                }
              }
            }
          } else {
            // It's a file
            totalCount += selected ? 1 : -1;
            totalSize += selected ? item.fileSize : -item.fileSize;
          }
        }
        
        if (selected) {
          _selectedPrefixes.add(item.relativePath);
        } else {
          final prefix = '${item.relativePath}${Platform.pathSeparator}';
          _selectedPrefixes.removeWhere((p) => p == item.relativePath || p.startsWith(prefix));
        }
      }
      
      // Update parent states in the tree
      _updateParentSelection(_rootNodes);
    }

    state = state.copyWith(
      selectedCount: totalCount,
      totalSelectedSize: totalSize,
    );
    _rebuildSidebarCache();
  }

  void _updateSelectionRecursive(List<SyncTreeNode> nodes, bool selected) {
    for (var node in nodes) {
      node.isSelected = selected;
      if (node.item != null) {
        node.item!.isSelected = selected;
      }
      if (node.children.isNotEmpty) {
        _updateSelectionRecursive(node.children, selected);
      }
    }
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
    if (state.isSyncing) return;
    final expandedPaths = _getExpandedPaths(state.treeNodes);

    for (var item in _allItems) {
      if (item.status == FileStatus.missingInSource) {
        item.isSelected = value;
      }
    }

    state = state.copyWith(
      isTwoWaySync: value,
      sidebarItemLimit: 50,
      itemsRevision: state.itemsRevision + 1,
    ).updateWithCounts(_allItems);

    _rebuildTreeFromAllItems(expandedPaths);

    if (value) {
      _compare();
    }
  }

  void _rebuildTreeFromAllItems(Set<String> expandedPaths) {
    // With persistent _rootNodes, expansion state is already in the nodes.
    // We just need to re-flatten the tree to update the visible list.
    final flatNodes = <SyncTreeNode>[];
    _flattenTreeRecursive(_rootNodes, flatNodes);
    state = state.copyWith(treeNodes: flatNodes);
  }

  /// Incrementally adds an item to the persistent hierarchical tree.
  /// This is O(depth) instead of O(N log N) rebuilding.
  void _upsertItemToPersistentTree(SyncItem item) {
    final effectiveTwoWay = state.isTwoWaySync;
    if (!effectiveTwoWay && item.status == FileStatus.missingInSource) return;

    // Use p.split for robust platform-independent splitting
    final parts = p.split(p.normalize(item.relativePath));
    String currentPath = "";

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part == "." || part == "..") continue; // Skip root/relative dots

      final isLast = i == parts.length - 1;
      final parentPath = currentPath;
      currentPath = currentPath.isEmpty ? part : p.join(currentPath, part);

      if (!_nodesMap.containsKey(currentPath)) {
        final isDir = !isLast || item.type == SyncType.directory;
        final node = SyncTreeNode(
          item: isLast ? item : null,
          name: part,
          relativePath: currentPath,
          isDirectory: isDir,
          depth: i,
          children: [],
          isSelected: isLast ? item.isSelected : false,
          isLoaded: isDir && isLast ? false : true,
        );
        _nodesMap[currentPath] = node;

        if (parentPath.isEmpty) {
          _rootNodes.add(node);
        } else {
          final parent = _nodesMap[parentPath];
          if (parent != null) {
            parent.children.add(node);
          }
        }
      } else if (isLast) {
        final existing = _nodesMap[currentPath]!;
        existing.item = item;
        existing.isSelected = item.isSelected;
      }
    }
  }

  void _flattenTreeRecursive(
    List<SyncTreeNode> nodes,
    List<SyncTreeNode> result,
  ) {
    for (final node in nodes) {
      result.add(node);
      if (node.isExpanded && node.isDirectory) {
        final children = node.children;
        final limit = node.childLimit;
        for (int i = 0; i < children.length && i < limit; i++) {
          _flattenTreeRecursiveNode(children[i], result);
        }
      }
    }
  }

  void _flattenTreeRecursiveNode(SyncTreeNode node, List<SyncTreeNode> result) {
    result.add(node);
    if (node.isExpanded && node.isDirectory) {
      final children = node.children;
      final limit = node.childLimit;
      for (int i = 0; i < children.length && i < limit; i++) {
        _flattenTreeRecursiveNode(children[i], result);
      }
    }
  }

  void reload() {
    if (state.isSyncing) return;
    _compare();
  }

  static const int _initialDepth = 1;

  Future<void> _compare({bool keepSyncStats = false}) async {
    if (state.sourcePath == null || state.targetPath == null) return;

    stopScanning();

    _allItems.clear();
    _scannedPaths.clear();
    _selectedPrefixes.clear();
    _rootNodes.clear();
    _nodesMap.clear();

    state = state.copyWith(
      isComparing: true,
      scannedItemsCount: 0,
      selectedCount: 0,
      totalSelectedSize: 0,
      treeNodes: [],
      itemsRevision: state.itemsRevision + 1,
      syncProgress: keepSyncStats ? state.syncProgress : 0.0,
      syncedCount: keepSyncStats ? state.syncedCount : 0,
      syncedBytes: keepSyncStats ? state.syncedBytes : 0,
      syncingFileName: keepSyncStats ? state.syncingFileName : null,
      syncedFilesCount: keepSyncStats ? state.syncedFilesCount : 0,
      syncedFoldersCount: keepSyncStats ? state.syncedFoldersCount : 0,
      syncTotalCount: keepSyncStats ? state.syncTotalCount : 0,
      syncTotalBytes: keepSyncStats ? state.syncTotalBytes : 0,
      isBackgroundScanComplete: false,
      diffCount: 0,
    );

    // 1. Shallow scan for immediate 1-layer display
    final shallowItems = await FolderComparisonService.compareFoldersShallow(
      state.sourcePath!,
      state.targetPath!,
      maxDepth: _initialDepth,
      isTwoWay: state.isTwoWaySync,
    );

    _allItems.addAll(shallowItems);
    final bool isWindows = Platform.isWindows;
    _scannedPaths.addAll(shallowItems.map((e) => isWindows ? e.relativePath.toLowerCase() : e.relativePath));

    for (final item in shallowItems) {
      _upsertItemToPersistentTree(item);
    }

    final flatNodes = <SyncTreeNode>[];
    _flattenTreeRecursive(_rootNodes, flatNodes);

    state = state.copyWith(
      treeNodes: flatNodes,
      isComparing: false,
      scannedItemsCount: _allItems.length,
      itemsRevision: state.itemsRevision + 1,
    ).updateWithCounts(_allItems);

    // 2. Progressive background scan
    state = state.copyWith(isBackgroundScanning: true);

    int pendingNewCount = 0;
    DateTime lastUpdateTime = DateTime.now();
    final int currentGeneration = ++_scanGeneration;

    // We don't await here directly to allow immediate control via the UI
    FolderComparisonService.compareFoldersProgressive(
      state.sourcePath!,
      state.targetPath!,
      isTwoWay: state.isTwoWaySync,
      onBatch: (batch) async {
        // Check cancellation or stale generation
        if (!state.isBackgroundScanning || currentGeneration != _scanGeneration) return;

        final bool isWindows = Platform.isWindows;
        int processedInThisBatch = 0;

        for (final item in batch) {
          // Yield to the event loop every 50 items so UI events (button presses) can fire
          processedInThisBatch++;
          if (processedInThisBatch % 50 == 0) {
            await Future.delayed(Duration.zero);
            // Re-check flags after yielding
            if (!state.isBackgroundScanning || currentGeneration != _scanGeneration) return;
          }

          final normalizedPath = p.normalize(item.relativePath);
          final lookupPath = isWindows ? normalizedPath.toLowerCase() : normalizedPath;

          if (_scannedPaths.contains(lookupPath)) continue;
          _scannedPaths.add(lookupPath);

          // Selection inheritance: check if any ancestor is selected and item is syncable
          if (_shouldAutoSelect(item.relativePath) && _isItemSyncable(item)) {
            item.isSelected = true;
          }

          _allItems.add(item);
          _upsertItemToPersistentTree(item);
          pendingNewCount++;
        }

        // Throttle state updates to every 1.5 seconds — only update COUNTER, not tree
        final now = DateTime.now();
        if (now.difference(lastUpdateTime) > const Duration(milliseconds: 1500)) {
          if (pendingNewCount > 0) {
            state = state.copyWith(
              scannedItemsCount: state.scannedItemsCount + pendingNewCount,
              itemsRevision: state.itemsRevision + 1,
            ).updateWithCounts(_allItems);
            _rebuildSidebarCache();
            pendingNewCount = 0;
          }
          lastUpdateTime = now;
        }
      },
      onDone: () {
        // Skip if this is a stale scan from a previous generation
        if (currentGeneration != _scanGeneration) return;
        
        // Final update
        state = state.copyWith(
          scannedItemsCount: state.scannedItemsCount + pendingNewCount,
          isBackgroundScanning: false,
          isScanPaused: false,
          isBackgroundScanComplete: true,
          itemsRevision: state.itemsRevision + 1,
        ).updateWithCounts(_allItems);
        _rebuildSidebarCache();

        _activeScanIsolate = null;
        _scanPauseCapability = null;
      },
    ).then((isolate) {
      // Store the isolate only if we are still scanning this generation
      if (state.isBackgroundScanning && currentGeneration == _scanGeneration) {
        _activeScanIsolate = isolate;
        // If the user requested pause while the isolate was starting, apply it now
        if (state.isScanPaused && _scanPauseCapability == null) {
          _scanPauseCapability = _activeScanIsolate!.pause();
        }
      } else {
        isolate.kill();
      }
    });
  }

  void stopScanning() {
    if (_activeScanIsolate != null) {
      _activeScanIsolate!.kill();
      _activeScanIsolate = null;
    }
    _scanPauseCapability = null;
    state = state.copyWith(
      isBackgroundScanning: false,
      isScanPaused: false,
    );
  }

  void togglePauseScanning() {
    if (!state.isBackgroundScanning) return;

    if (state.isScanPaused) {
      // Resume
      if (_activeScanIsolate != null && _scanPauseCapability != null) {
        _activeScanIsolate!.resume(_scanPauseCapability!);
        _scanPauseCapability = null;
      }
      state = state.copyWith(isScanPaused: false);
    } else {
      // Pause
      if (_activeScanIsolate != null) {
        _scanPauseCapability = _activeScanIsolate!.pause();
      }
      // We set the state even if the isolate is null to show UI change immediately
      state = state.copyWith(isScanPaused: true);
    }
  }

  bool _shouldAutoSelect(String relativePath) {
    // Check if any prefix in _selectedPrefixes matches this path
    for (final prefix in _selectedPrefixes) {
      if (relativePath.startsWith('$prefix${Platform.pathSeparator}')) {
        return true;
      }
    }
    return false;
  }

  bool _isItemSyncable(SyncItem item) {
    return state._isItemSyncable(item, isTwoWay: state.isTwoWaySync);
  }



  void toggleNodeExpansion(SyncTreeNode node) {
    node.isExpanded = !node.isExpanded;
    final expandedPaths = _getExpandedPaths(state.treeNodes);
    _rebuildTreeFromAllItems(expandedPaths);
  }

  /// Expand a directory node, lazily loading its children if needed.
  Future<void> expandAndLoadNode(SyncTreeNode node) async {
    if (!node.isDirectory) return;

    if (node.isLoaded) {
      toggleNodeExpansion(node);
      return;
    }

    // Check if background scan already found children
    final childrenFromBackground = _allItems.where((item) {
      final parentPath = p.dirname(item.relativePath);
      return parentPath == node.relativePath;
    }).toList();

    if (childrenFromBackground.isNotEmpty) {
      _populateNode(node, childrenFromBackground);
      node.isLoaded = true;
      node.isExpanded = true;
      _rebuildTreeFromAllItems(_getExpandedPaths(state.treeNodes));
      return;
    }

    // Fallback: fetch manually
    if (state.sourcePath == null || state.targetPath == null) return;

    node.isLoading = true;
    node.isExpanded = true;
    state = state.copyWith(treeNodes: List.from(state.treeNodes));

    try {
      final childItems = await FolderComparisonService.compareSubfolder(
        state.sourcePath!,
        state.targetPath!,
        node.relativePath,
        isTwoWay: state.isTwoWaySync,
      );

      // Add new items to internal storage
      for (final item in childItems) {
        if (!_scannedPaths.contains(item.relativePath)) {
          _scannedPaths.add(item.relativePath);
          _allItems.add(item);
        }
      }

      _populateNode(node, childItems);

      node.isLoaded = true;
      node.isLoading = false;

      state = state.copyWith(
        scannedItemsCount: _allItems.length,
        itemsRevision: state.itemsRevision + 1,
      ).updateWithCounts(_allItems);
      _rebuildTreeFromAllItems(_getExpandedPaths(state.treeNodes));
      _rebuildSidebarCache();
    } catch (e) {
      node.isLoading = false;
      state = state.copyWith(treeNodes: List.from(state.treeNodes));
    }
  }

  void _populateNode(SyncTreeNode node, List<SyncItem> childItems) {
    node.children.clear();
    for (var item in childItems) {
      if (!state.isTwoWaySync && item.status == FileStatus.missingInSource) {
        continue;
      }

      final name = item.relativePath.split(Platform.pathSeparator).last;

      final parentPath = p.dirname(item.relativePath);
      if (parentPath != node.relativePath) continue;

      final isSyncNeeded = state.isTwoWaySync
          ? item.status != FileStatus.identical
          : (item.status == FileStatus.missingInTarget ||
                item.status == FileStatus.different);

      final childNode = SyncTreeNode(
        item: item,
        name: name,
        relativePath: item.relativePath,
        isDirectory: item.type == SyncType.directory,
        depth: node.depth + 1,
        children: [],
        isSelected: isSyncNeeded,
        isLoaded: item.type == SyncType.directory ? false : true,
      );
      node.children.add(childNode);
    }
  }

  void toggleItemSelection(int index) {
    if (state.isSyncing) return;
    if (index >= 0 && index < _allItems.length) {
      final item = _allItems[index];
      if (!item.isSelected && !_isItemSyncable(item)) return; // Prevent selection of identicals
      item.isSelected = !item.isSelected;

      state = state.copyWith(
        selectedCount: _allItems.where((e) => e.isSelected && e.type == SyncType.file).length,
        selectedFoldersCount: _allItems.where((e) => e.isSelected && e.type == SyncType.directory).length,
        totalSelectedSize: _allItems.where((e) => e.isSelected && e.type == SyncType.file).fold<int>(0, (sum, item) => sum + item.fileSize),
        itemsRevision: state.itemsRevision + 1,
      );
      _rebuildSidebarCache();
    }
  }

  Set<String> _getExpandedPaths(List<SyncTreeNode> nodes) {
    final Set<String> paths = {};
    for (var node in nodes) {
      if (node.isExpanded) {
        paths.add(node.relativePath);
      }
      if (node.children.isNotEmpty) {
        paths.addAll(_getExpandedPaths(node.children));
      }
    }
    return paths;
  }



  void loadMoreChildren(SyncTreeNode node) {
    node.childLimit += 100;
    _rebuildTreeFromAllItems(_getExpandedPaths(state.treeNodes));
  }

  void toggleNodeSelection(SyncTreeNode node, bool selected) {
    if (state.isSyncing) return;

    final prefix = '${node.relativePath}${Platform.pathSeparator}';

    // 1. Update ALL items in the flat list that match this node or are descendants
    for (final item in _allItems) {
      if (item.relativePath == node.relativePath || item.relativePath.startsWith(prefix)) {
        item.isSelected = selected;
      }
    }

    // 2. Recursively update all tree nodes
    void updateTreeRecursive(SyncTreeNode n) {
      n.isSelected = selected;
      if (n.item != null) {
        n.item!.isSelected = selected;
      }
      for (var child in n.children) {
        updateTreeRecursive(child);
      }
    }
    updateTreeRecursive(node);

    // 3. Update parent selection states
    _updateParentSelection(state.treeNodes);

    // 4. Track prefix for future background scan items
    if (selected) {
      _selectedPrefixes.add(node.relativePath);
    } else {
      _selectedPrefixes.remove(node.relativePath);
    }

    // 5. Recalculate counts from scratch to avoid drift
    final selectedFiles = _allItems.where((e) => e.isSelected && e.type == SyncType.file);
    final newSelectedCount = selectedFiles.length;
    final newTotalSize = selectedFiles.fold<int>(0, (sum, item) => sum + item.fileSize);

    state = state.copyWith(
      selectedCount: newSelectedCount,
      selectedFoldersCount: _allItems.where((e) => e.isSelected && e.type == SyncType.directory).length,
      totalSelectedSize: newTotalSize,
      itemsRevision: state.itemsRevision + 1,
    );
    _rebuildSidebarCache();
  }

  void _setSelectionRecursive(SyncTreeNode node, bool selected) {
    node.isSelected = selected;
    if (node.item != null) {
      node.item!.isSelected = selected;
    }
    for (var child in node.children) {
      _setSelectionRecursive(child, selected);
    }
  }

  void _updateParentSelection(List<SyncTreeNode> nodes) {
    for (var node in nodes) {
      if (node.children.isNotEmpty) {
        _updateParentSelection(node.children);
        node.isSelected = node.children.every((child) => child.isSelected);
      }
    }
  }

  void loadMoreSidebarItems() {
    state = state.copyWith(sidebarItemLimit: state.sidebarItemLimit + 100);
  }



  Future<void> sync() async {
    if (_allItems.isEmpty) return;

    final itemsToSync = _allItems.where((e) => e.isSelected).toList();
    if (itemsToSync.isEmpty) return;

    int totalBytes = 0;
    for (final item in itemsToSync) {
      if (item.type == SyncType.file) {
        totalBytes += item.fileSize;
      }
    }

    final filesToSyncCount = itemsToSync.where((e) => e.type == SyncType.file).length;
    final foldersToSyncCount = itemsToSync.where((e) => e.type == SyncType.directory).length;

    state = state.copyWith(
      isSyncing: true,
      syncProgress: 0.0,
      syncingFileName: '',
      syncedCount: 0,
      syncTotalCount: itemsToSync.length,
      syncedBytes: 0,
      syncTotalBytes: totalBytes,
      syncedFilesCount: 0,
      syncedFoldersCount: 0,
      totalFilesToSync: filesToSyncCount,
      totalFoldersToSync: foldersToSyncCount,
      isSyncStopped: false,
      isSyncPaused: false,
    );

    DateTime lastUpdate = DateTime.now();

    final Set<String> processedFiles = {};
    final Set<String> processedFolders = {};
    int filesDone = 0;
    int foldersDone = 0;

    await SyncService.syncItems(
      itemsToSync,
      shouldAbort: () => state.isSyncStopped,
      shouldPause: () => state.isSyncPaused,
      getSpeedLimit: () => state.isSpeedLimitEnabled ? state.speedLimit : 0,
      onProgress: (item, count, total, bytesCopied, totalB, itemBytesCopied) {
        if (item.type == SyncType.file) {
          if (!processedFiles.contains(item.relativePath)) {
            processedFiles.add(item.relativePath);
            filesDone++;
          }
        } else if (item.type == SyncType.directory) {
          if (!processedFolders.contains(item.relativePath)) {
            processedFolders.add(item.relativePath);
            foldersDone++;
          }
        }

        final now = DateTime.now();
        final diffMs = now.difference(lastUpdate).inMilliseconds;
        
        // Update at most 100ms or at the end
        if (diffMs > 100 || count == total) {
          final int bytesDelta = bytesCopied - state.syncedBytes;
          final double currentSpeed = diffMs > 0 ? (bytesDelta / (diffMs / 1000.0)) : 0;
          
          // Smooth speed calculation (Moving average)
          final double smoothedSpeed = state.syncSpeed == 0 
              ? currentSpeed 
              : (state.syncSpeed * 0.7 + currentSpeed * 0.3);

          Duration? remaining;
          if (smoothedSpeed > 1024) { // Only show ETA if we have decent speed data
            final remainingBytes = totalB - bytesCopied;
            remaining = Duration(seconds: (remainingBytes / smoothedSpeed).round());
          }

          state = state.copyWith(
            syncProgress: totalB > 0 ? bytesCopied / totalB : (total > 0 ? count / total : 1.0),
            syncingFileName: item.relativePath,
            syncedCount: count,
            syncedBytes: bytesCopied,
            syncedFilesCount: filesDone,
            syncedFoldersCount: foldersDone,
            syncingFileBytes: itemBytesCopied,
            syncingFileTotalBytes: item.fileSize,
            syncSpeed: smoothedSpeed,
            remainingTime: remaining,
          );
          lastUpdate = now;
        }
      },
    );

    state = state.copyWith(
      isSyncing: false,
      syncProgress: state.isSyncStopped ? state.syncProgress : 1.0,
      syncingFileName: null,
      isSyncPaused: false,
      isSyncStopped: false,
      syncedFilesCount: filesDone,
      syncedFoldersCount: foldersDone,
    );
    await _compare(keepSyncStats: true);
  }

  void togglePauseSyncing() {
    state = state.copyWith(isSyncPaused: !state.isSyncPaused);
  }

  void stopSyncing() {
    state = state.copyWith(isSyncStopped: true, isSyncPaused: false);
  }

  void clearSyncProgress() {
    state = state.copyWith(
      syncProgress: 0.0,
      syncedCount: 0,
      syncTotalCount: 0,
      syncedBytes: 0,
      syncTotalBytes: 0,
      syncedFilesCount: 0,
      syncedFoldersCount: 0,
      syncingFileName: null,
    );
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
