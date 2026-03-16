import 'dart:io';
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
  final int totalSelectedSize; // Total bytes of selected files
  final int sidebarItemLimit;
  final double syncProgress;
  final String? syncingFileName;
  final int syncedCount; // Files copied so far
  final int syncTotalCount; // Total files to copy
  final int syncedBytes; // Bytes copied so far
  final int syncTotalBytes; // Total bytes to copy
  final int itemsRevision;

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
    this.sidebarSearchQuery = '',
    this.sidebarSortOrder = SidebarSortOrder.name,
    this.sidebarItems = const [],
    this.itemsRevision = 0,
  });

  final SidebarSortOrder sidebarSortOrder;
  final String sidebarSearchQuery;
  final List<SyncItem> sidebarItems;

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
    String? sidebarSearchQuery,
    SidebarSortOrder? sidebarSortOrder,
    List<SyncItem>? sidebarItems,
    int? itemsRevision,
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
      sidebarSearchQuery: sidebarSearchQuery ?? this.sidebarSearchQuery,
      sidebarSortOrder: sidebarSortOrder ?? this.sidebarSortOrder,
      sidebarItems: sidebarItems ?? this.sidebarItems,
      itemsRevision: itemsRevision ?? this.itemsRevision,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  // ── Mutable internal storage (NOT in immutable state) ──
  final List<SyncItem> _allItems = [];
  final Set<String> _scannedPaths = {};
  // Persistent hierarchical tree for O(1) updates and instant expansion
  final List<SyncTreeNode> _rootNodes = [];
  final Map<String, SyncTreeNode> _nodesMap = {};

  // For selection inheritance during background scan
  final Set<String> _selectedPrefixes = {};

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
      itemsRevision: state.itemsRevision + 1,
    );
  }

  void toggleItemSelectionByPath(String relativePath, bool selected) {
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
        selectedCount: _allItems.where((e) => e.isSelected).length,
        totalSelectedSize: _allItems.where((e) => e.isSelected).fold<int>(0, (sum, item) => sum + (item.fileSize)),
        itemsRevision: state.itemsRevision + 1,
      );
      _rebuildSidebarCache();
    }
  }

  void toggleAll(bool selected) {
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
        totalCount = _allItems.length;
        totalSize = _allItems.fold(0, (sum, item) => sum + item.fileSize);
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
                  totalCount += selected ? 1 : -1;
                  totalSize += selected ? child.fileSize : -child.fileSize;
                }
              }
            }
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
    final expandedPaths = _getExpandedPaths(state.treeNodes);

    for (var item in _allItems) {
      if (item.status == FileStatus.missingInSource) {
        item.isSelected = value;
      }
    }

    state = state.copyWith(
      isTwoWaySync: value,
      selectedCount: _allItems.where((e) => e.isSelected).length,
      sidebarItemLimit: 50,
      itemsRevision: state.itemsRevision + 1,
    );

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

    final parts = item.relativePath.split(Platform.pathSeparator);
    String currentPath = "";

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
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
    _compare();
  }

  static const int _initialDepth = 1;

  Future<void> _compare() async {
    if (state.sourcePath == null || state.targetPath == null) return;

    _allItems.clear();
    _scannedPaths.clear();
    _selectedPrefixes.clear();
    _rootNodes.clear();
    _nodesMap.clear();

    state = state.copyWith(
      isComparing: true,
      scannedItemsCount: 0,
      selectedCount: 0,
      treeNodes: [],
      itemsRevision: state.itemsRevision + 1,
    );

    // 1. Shallow scan for immediate 1-layer display
    final shallowItems = await FolderComparisonService.compareFoldersShallow(
      state.sourcePath!,
      state.targetPath!,
      maxDepth: _initialDepth,
      isTwoWay: state.isTwoWaySync,
    );

    _allItems.addAll(shallowItems);
    _scannedPaths.addAll(shallowItems.map((e) => e.relativePath));

    for (final item in shallowItems) {
      _upsertItemToPersistentTree(item);
    }

    final flatNodes = <SyncTreeNode>[];
    _flattenTreeRecursive(_rootNodes, flatNodes);

    state = state.copyWith(
      treeNodes: flatNodes,
      isComparing: false,
      scannedItemsCount: _allItems.length,
      selectedCount: _allItems.where((e) => e.isSelected).length,
      itemsRevision: state.itemsRevision + 1,
    );

    // 2. Progressive background scan
    _runBackgroundFullScanProgressive(
      state.sourcePath!,
      state.targetPath!,
      isTwoWay: state.isTwoWaySync,
    );
  }

  Future<void> _runBackgroundFullScanProgressive(
    String sourcePath,
    String targetPath, {
    bool isTwoWay = true,
  }) async {
    state = state.copyWith(isBackgroundScanning: true);

    int pendingNewCount = 0;
    int pendingSelectedCount = 0;
    int pendingSelectedSize = 0;
    DateTime lastUpdateTime = DateTime.now();

    await FolderComparisonService.compareFoldersProgressive(
      sourcePath,
      targetPath,
      isTwoWay: isTwoWay,
      onBatch: (batch) async {
        for (final item in batch) {
          if (_scannedPaths.contains(item.relativePath)) continue;
          _scannedPaths.add(item.relativePath);

          // Selection inheritance: check if any ancestor is selected
          if (_shouldAutoSelect(item.relativePath)) {
            item.isSelected = true;
          }

          _allItems.add(item);
          _upsertItemToPersistentTree(item);
          pendingNewCount++;
          if (item.isSelected) {
            pendingSelectedCount++;
            pendingSelectedSize += item.fileSize;
          }
        }

        // Throttle state updates to every 1.5 seconds — only update COUNTER, not tree
        final now = DateTime.now();
        if (now.difference(lastUpdateTime) > const Duration(milliseconds: 1500)) {
          if (pendingNewCount > 0) {
            state = state.copyWith(
              scannedItemsCount: state.scannedItemsCount + pendingNewCount,
              selectedCount: state.selectedCount + pendingSelectedCount,
              totalSelectedSize: state.totalSelectedSize + pendingSelectedSize,
              itemsRevision: state.itemsRevision + 1,
            );
            _rebuildSidebarCache();
            pendingNewCount = 0;
            pendingSelectedCount = 0;
            pendingSelectedSize = 0;
          }
          lastUpdateTime = now;
        }
      },
    );

    // Final update
    if (pendingNewCount > 0) {
      state = state.copyWith(
        scannedItemsCount: state.scannedItemsCount + pendingNewCount,
        selectedCount: state.selectedCount + pendingSelectedCount,
        totalSelectedSize: state.totalSelectedSize + pendingSelectedSize,
        itemsRevision: state.itemsRevision + 1,
      );
      _rebuildSidebarCache();
    }

    state = state.copyWith(isBackgroundScanning: false);
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
        selectedCount: _allItems.where((e) => e.isSelected).length,
        totalSelectedSize: _allItems.where((e) => e.isSelected).fold<int>(0, (sum, item) => sum + item.fileSize),
        itemsRevision: state.itemsRevision + 1,
      );
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
    if (index >= 0 && index < _allItems.length) {
      final item = _allItems[index];
      item.isSelected = !item.isSelected;

      state = state.copyWith(
        selectedCount: _allItems.where((e) => e.isSelected).length,
        totalSelectedSize: _allItems.where((e) => e.isSelected).fold<int>(0, (sum, item) => sum + item.fileSize),
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
    if (node.isSelected == selected) return;

    int countDelta = 0;
    int sizeDelta = 0;

    void updateRecursive(SyncTreeNode n) {
      if (n.item != null && n.item!.isSelected != selected) {
        n.item!.isSelected = selected;
        countDelta += selected ? 1 : -1;
        sizeDelta += selected ? n.item!.fileSize : -n.item!.fileSize;
      }
      n.isSelected = selected;
      for (var child in n.children) {
        updateRecursive(child);
      }
    }

    updateRecursive(node);
    _updateParentSelection(state.treeNodes);

    // Also update all items in the flat list that might not be in the tree yet
    // but match the prefix (for safety)
    final prefix = '${node.relativePath}${Platform.pathSeparator}';
    for (final item in _allItems) {
      if (item.relativePath.startsWith(prefix) && item.isSelected != selected) {
        // Find if this item is ALREADY covered by tree recursion
        if (!_nodesMap.containsKey(item.relativePath)) {
           item.isSelected = selected;
           countDelta += selected ? 1 : -1;
           sizeDelta += selected ? item.fileSize : -item.fileSize;
        }
      }
    }

    // Track prefix for future background scan items
    if (selected) {
      _selectedPrefixes.add(node.relativePath);
    } else {
      _selectedPrefixes.remove(node.relativePath);
    }

    state = state.copyWith(
      selectedCount: state.selectedCount + countDelta,
      totalSelectedSize: state.totalSelectedSize + sizeDelta,
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
      totalBytes += item.fileSize;
    }

    state = state.copyWith(
      isSyncing: true,
      syncProgress: 0.0,
      syncingFileName: '',
      syncedCount: 0,
      syncTotalCount: itemsToSync.length,
      syncedBytes: 0,
      syncTotalBytes: totalBytes,
    );

    DateTime lastUpdate = DateTime.now();

    await SyncService.syncItems(
      itemsToSync,
      onProgress: (count, total, fileName, bytesCopied, totalB) {
        final now = DateTime.now();
        // Throttle updates to 100ms to prevent UI lag
        if (now.difference(lastUpdate).inMilliseconds > 100 || count == total) {
          state = state.copyWith(
            syncProgress: count / total,
            syncingFileName: fileName,
            syncedCount: count,
            syncedBytes: bytesCopied,
          );
          lastUpdate = now;
        }
      },
    );

    state = state.copyWith(
      isSyncing: false,
      syncProgress: 1.0,
      syncingFileName: null,
    );
    await _compare();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
