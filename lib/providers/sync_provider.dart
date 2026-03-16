import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/sync_item.dart';
import '../services/comparison_service.dart';
import '../services/sync_service.dart';

class SyncTreeNode {
  SyncItem? item; // Null for root, mutable for background sync relinking
  final String name;
  final String relativePath; // Full relative path from root
  final bool isDirectory;
  final List<SyncTreeNode> children;
  bool isExpanded;
  bool isSelected;
  bool isLoaded; // Whether children have been loaded (for lazy loading)
  bool isLoading; // Whether children are currently being loaded
  int childLimit; // For pagination

  SyncTreeNode({
    this.item,
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    this.children = const [],
    this.isExpanded = false,
    this.isSelected = false,
    this.isLoaded = true,
    this.isLoading = false,
    this.childLimit = 100,
  });

  // Calculate if this node or any of its children need sync
  bool get needsSync {
    if (item != null && item!.status != FileStatus.identical) return true;
    return children.any((child) => child.needsSync);
  }
}

class SyncState {
  final String? sourcePath;
  final String? targetPath;
  final List<SyncItem> items;
  final List<SyncTreeNode> treeNodes;
  final bool isComparing;
  final bool isSyncing;
  final bool isTwoWaySync;
  final AppMode currentMode;
  final bool isBackgroundScanning;
  final int scannedItemsCount;
  final List<SyncItem> selectedItems; // Prefiltered for sidebar and sync
  final int sidebarItemLimit; // For infinite scrolling
  final double syncProgress;
  final String? syncingFileName;

  SyncState({
    this.sourcePath,
    this.targetPath,
    this.items = const [],
    this.treeNodes = const [],
    this.isComparing = false,
    this.isSyncing = false,
    this.isTwoWaySync = false,
    this.currentMode = AppMode.selection,
    this.isBackgroundScanning = false,
    this.scannedItemsCount = 0,
    this.selectedItems = const [],
    this.sidebarItemLimit = 50,
    this.syncProgress = 0.0,
    this.syncingFileName,
  });

  SyncState copyWith({
    String? sourcePath,
    String? targetPath,
    List<SyncItem>? items,
    List<SyncTreeNode>? treeNodes,
    bool? isComparing,
    bool? isSyncing,
    bool? isTwoWaySync,
    AppMode? currentMode,
    bool? isBackgroundScanning,
    int? scannedItemsCount,
    List<SyncItem>? selectedItems,
    int? sidebarItemLimit,
    double? syncProgress,
    String? syncingFileName,
  }) {
    return SyncState(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      items: items ?? this.items,
      treeNodes: treeNodes ?? this.treeNodes,
      isComparing: isComparing ?? this.isComparing,
      isSyncing: isSyncing ?? this.isSyncing,
      isTwoWaySync: isTwoWaySync ?? this.isTwoWaySync,
      currentMode: currentMode ?? this.currentMode,
      isBackgroundScanning: isBackgroundScanning ?? this.isBackgroundScanning,
      scannedItemsCount: scannedItemsCount ?? this.scannedItemsCount,
      selectedItems: selectedItems ?? this.selectedItems,
      sidebarItemLimit: sidebarItemLimit ?? this.sidebarItemLimit,
      syncProgress: syncProgress ?? this.syncProgress,
      syncingFileName: syncingFileName ?? this.syncingFileName,
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
    // 1. Save current expansion state
    final expandedPaths = _getExpandedPaths(state.treeNodes);

    // 2. Update selection in the items list
    final updatedItems = state.items.map((item) {
      if (item.status == FileStatus.missingInSource) {
        item.isSelected = value;
      }
      return item;
    }).toList();

    // 3. Update state
    state = state.copyWith(
      isTwoWaySync: value,
      items: updatedItems,
      selectedItems: updatedItems.where((e) => e.isSelected).toList(),
      sidebarItemLimit: 50, // Reset limit when selection significantly changes
    );

    // 4. Rebuild tree and restore expansion
    final newTree = _buildTree(updatedItems, isTwoWaySync: value);
    _restoreExpansionState(newTree, expandedPaths);
    
    state = state.copyWith(treeNodes: newTree);

    // 5. If turning two-way scan ON, trigger a fresh comparison to discover destination items
    if (value) {
      _compare();
    }
  }

  void reload() {
    _compare();
  }

  static const int _initialDepth = 1;

  Future<void> _compare() async {
    if (state.sourcePath == null || state.targetPath == null) return;
    
    state = state.copyWith(
      isComparing: true, 
      items: [], 
      scannedItemsCount: 0,
      treeNodes: [],
    );
    
    // 1. Shallow scan for immediate 1-layer display
    final shallowItems = await FolderComparisonService.compareFoldersShallow(
      state.sourcePath!,
      state.targetPath!,
      maxDepth: _initialDepth,
      isTwoWay: state.isTwoWaySync,
    );
    
    final treeNodes = _buildTree(shallowItems, maxDepth: _initialDepth);
    state = state.copyWith(
      items: shallowItems, 
      treeNodes: treeNodes,
      isComparing: false,
      scannedItemsCount: shallowItems.length,
      selectedItems: shallowItems.where((e) => e.isSelected).toList(),
    );

    // 2. Progressive background scan for sidebar
    _runBackgroundFullScanProgressive(state.sourcePath!, state.targetPath!, isTwoWay: state.isTwoWaySync);
  }

  Future<void> _runBackgroundFullScanProgressive(String source, String target, {bool isTwoWay = true}) async {
    state = state.copyWith(isBackgroundScanning: true);
    
    DateTime lastUpdateTime = DateTime.now();
    List<SyncItem> pendingItems = [];

    await FolderComparisonService.compareFoldersProgressive(
      source,
      target,
      isTwoWay: isTwoWay,
      onBatch: (batch) {
        pendingItems.addAll(batch);

        final now = DateTime.now();
        // Update UI at most every 800ms to prevent lag with many files
        if (now.difference(lastUpdateTime) > const Duration(milliseconds: 800)) {
          final existingPaths = state.items.map((e) => e.relativePath).toSet();
          final newItems = pendingItems.where((e) => !existingPaths.contains(e.relativePath)).toList();
          pendingItems.clear();

          if (newItems.isNotEmpty) {
            final expandedPaths = _getExpandedPaths(state.treeNodes);
            final updatedItems = [...state.items, ...newItems];

            final newTree = _buildTree(updatedItems);
            _restoreExpansionState(newTree, expandedPaths);

            state = state.copyWith(
              items: updatedItems,
              scannedItemsCount: updatedItems.length,
              treeNodes: newTree,
              selectedItems: updatedItems.where((e) => e.isSelected).toList(),
            );
          }
          lastUpdateTime = now;
        }
      },
    );

    // Final flush of any pending items
    if (pendingItems.isNotEmpty) {
      final existingPaths = state.items.map((e) => e.relativePath).toSet();
      final newItems = pendingItems.where((e) => !existingPaths.contains(e.relativePath)).toList();
      if (newItems.isNotEmpty) {
        final expandedPaths = _getExpandedPaths(state.treeNodes);
        final updatedItems = [...state.items, ...newItems];
        final newTree = _buildTree(updatedItems);
        _restoreExpansionState(newTree, expandedPaths);
        state = state.copyWith(
          items: updatedItems,
          scannedItemsCount: updatedItems.length,
          treeNodes: newTree,
          selectedItems: updatedItems.where((e) => e.isSelected).toList(),
        );
      }
    }

    state = state.copyWith(isBackgroundScanning: false);
  }

  List<SyncTreeNode> _buildTree(List<SyncItem> items, {int? maxDepth, bool? isTwoWaySync}) {
    final effectiveTwoWay = isTwoWaySync ?? state.isTwoWaySync;
    final Map<String, SyncTreeNode> nodes = {};
    final List<SyncTreeNode> rootNodes = [];

    // Filter items based on two-way sync setting
    final filteredItems = items.where((item) {
      if (effectiveTwoWay) return true;
      return item.status != FileStatus.missingInSource;
    }).toList();

    // Sort items by depth to ensure parent directories are created first
    final sortedItems = filteredItems
      ..sort((a, b) => a.relativePath.split(Platform.pathSeparator).length
          .compareTo(b.relativePath.split(Platform.pathSeparator).length));

    for (var item in sortedItems) {
      final parts = item.relativePath.split(Platform.pathSeparator);
      String currentPath = "";
      
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isLast = i == parts.length - 1;
        final parentPath = currentPath;
        currentPath = currentPath.isEmpty ? part : p.join(currentPath, part);

        // Determine depth of this path segment (0-indexed)
        final depth = i + 1;
        final isAtBoundary = maxDepth != null && depth >= maxDepth;

        if (!nodes.containsKey(currentPath)) {
          final isDir = !isLast || item.type == SyncType.directory;
          final node = SyncTreeNode(
            item: isLast ? item : null,
            name: part,
            relativePath: currentPath,
            isDirectory: isDir,
            children: [],
            // Respect the item's own selection property if it's the leaf node
            isSelected: isLast ? item.isSelected : false,
            // Mark directory nodes at the depth boundary as not loaded
            isLoaded: isDir && isLast && isAtBoundary ? false : true,
            childLimit: 100,
          );
          nodes[currentPath] = node;

          if (parentPath.isEmpty) {
            rootNodes.add(node);
          } else {
            nodes[parentPath]!.children.add(node);
          }
        } else if (isLast) {
          final existing = nodes[currentPath]!;
          nodes[currentPath] = SyncTreeNode(
            item: item,
            name: part,
            relativePath: currentPath,
            isDirectory: existing.isDirectory,
            children: existing.children,
            isSelected: item.isSelected, // Respect item's selection
            isLoaded: existing.isLoaded,
          );
        }
      }
    }
    _updateParentSelection(rootNodes);
    return rootNodes;
  }

  void toggleNodeExpansion(SyncTreeNode node) {
    node.isExpanded = !node.isExpanded;
    state = state.copyWith(treeNodes: List.from(state.treeNodes));
  }

  /// Expand a directory node, lazily loading its children if needed.
  Future<void> expandAndLoadNode(SyncTreeNode node) async {
    if (!node.isDirectory) return;

    // If already loaded, just toggle expansion
    if (node.isLoaded) {
      toggleNodeExpansion(node);
      return;
    }

    // Not loaded yet — check if background full scan already found these items
    final childrenFromBackground = state.items.where((item) {
      final parentPath = p.dirname(item.relativePath);
      return parentPath == node.relativePath || (node.relativePath == "." && !item.relativePath.contains(Platform.pathSeparator));
    }).toList();

    // Special case for root level relative paths if node.relativePath is just a folder name with no depth
    // Actually p.dirname handles it. If relativePath is "dir1", dirname(dir1/file) is "dir1".

    if (childrenFromBackground.isNotEmpty) {
      _populateNode(node, childrenFromBackground);
      node.isLoaded = true;
      node.isExpanded = true;
      state = state.copyWith(treeNodes: List.from(state.treeNodes));
      return;
    }

    // Fallback: fetch children manually if background scan hasn't reached them yet
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

      // Add newly discovered items to the main items list (deduplicated)
      final existingPaths = state.items.map((e) => e.relativePath).toSet();
      final newItems = childItems.where((e) => !existingPaths.contains(e.relativePath)).toList();
      final updatedItems = List<SyncItem>.from(state.items)..addAll(newItems);

      _populateNode(node, childItems);

      node.isLoaded = true;
      node.isLoading = false;
      _updateParentSelection(state.treeNodes);

      state = state.copyWith(
        items: updatedItems,
        treeNodes: List.from(state.treeNodes),
        selectedItems: updatedItems.where((e) => e.isSelected).toList(),
      );
    } catch (e) {
      node.isLoading = false;
      state = state.copyWith(treeNodes: List.from(state.treeNodes));
    }
  }

  void _populateNode(SyncTreeNode node, List<SyncItem> childItems) {
    node.children.clear();
    for (var item in childItems) {
      // Filter out items missing in source if two-way sync is off
      if (!state.isTwoWaySync && item.status == FileStatus.missingInSource) {
        continue;
      }

      final name = item.relativePath.split(Platform.pathSeparator).last;
      
      // Determine if this item is a direct child
      final parentPath = p.dirname(item.relativePath);
      if (parentPath != node.relativePath && !(node.relativePath == "." && !item.relativePath.contains(Platform.pathSeparator))) {
         // This item might be a grandchild found in state.items, skip it here
         continue;
      }

      final isSyncNeeded = state.isTwoWaySync
          ? item.status != FileStatus.identical
          : (item.status == FileStatus.missingInTarget || item.status == FileStatus.different);

      final childNode = SyncTreeNode(
        item: item,
        name: name,
        relativePath: item.relativePath,
        isDirectory: item.type == SyncType.directory,
        children: [],
        isSelected: isSyncNeeded,
        // Child directories are also not loaded yet
        isLoaded: item.type == SyncType.directory ? false : true,
        childLimit: 100,
      );
      node.children.add(childNode);
    }
  }

  void toggleItemSelection(int index) {
    if (index >= 0 && index < state.items.length) {
      final item = state.items[index];
      item.isSelected = !item.isSelected;
      
      _updateTreeFromItems();
      
      state = state.copyWith(
        items: List.from(state.items),
        treeNodes: List.from(state.treeNodes),
        selectedItems: state.items.where((e) => e.isSelected).toList(),
      );
    }
  }

  void _updateTreeFromItems() {
    // If visibility changed (e.g. background scan found items that should be visible), 
    // it's safest to rebuild the tree while preserving expansion state.
    // However, for performance, we'll just update existing nodes and then 
    // re-run _buildTree if the item count changed significantly? 
    // No, let's just make it simpler: update selection.
    
    // To handle new items appearing in already expanded folders, we should 
    // ideally check if any new items belong to loaded folders.
    
    // For now, let's just fix the selection sync.
    final Map<String, SyncItem> itemMap = {
      for (var item in state.items) item.relativePath: item
    };

    // Before updating, let's see if we need to add new nodes.
    // If the number of items changed, a full rebuild might be needed 
    // if those items should be visible in the current tree.
    
    _updateNodeFromItemRecursive(state.treeNodes, itemMap);
    _updateParentSelection(state.treeNodes);
  }

  void _updateNodeFromItemRecursive(List<SyncTreeNode> nodes, Map<String, SyncItem> itemMap) {
    for (var node in nodes) {
      if (itemMap.containsKey(node.relativePath)) {
        node.item = itemMap[node.relativePath];
        node.isSelected = node.item!.isSelected;
      }
      if (node.children.isNotEmpty) {
        _updateNodeFromItemRecursive(node.children, itemMap);
      }
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

  void _restoreExpansionState(List<SyncTreeNode> nodes, Set<String> expandedPaths) {
    for (var node in nodes) {
      if (expandedPaths.contains(node.relativePath)) {
        node.isExpanded = true;
      }
      if (node.children.isNotEmpty) {
        _restoreExpansionState(node.children, expandedPaths);
      }
    }
  }

  void loadMoreChildren(SyncTreeNode node) {
    node.childLimit += 100;
    state = state.copyWith(treeNodes: List.from(state.treeNodes));
  }

  void toggleNodeSelection(SyncTreeNode node, bool selected) {
    // 1. Recursive update for the visible UI tree
    _setSelectionRecursive(node, selected);
    _updateParentSelection(state.treeNodes);
    
    // 2. Optimized MASS selection using path-prefix matching on EVERYTHING in state.items
    // This catches files that aren't even discovered/populated in the tree yet.
    final List<SyncItem> updatedItems = state.items.map((item) {
      // If it's the node itself or a child (starts with "node.relativePath/")
      if (item.relativePath == node.relativePath || 
          item.relativePath.startsWith('${node.relativePath}${Platform.pathSeparator}')) {
        item.isSelected = selected;
      }
      return item;
    }).toList();

    state = state.copyWith(
      items: updatedItems,
      treeNodes: List.from(state.treeNodes),
      selectedItems: updatedItems.where((e) => e.isSelected).toList(),
      sidebarItemLimit: 50, // Reset limit to keep sidebar snappy
    );
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
        // Parent is selected if all children are selected
        node.isSelected = node.children.every((child) => child.isSelected);
      }
    }
  }

  void loadMoreSidebarItems() {
    state = state.copyWith(
      sidebarItemLimit: state.sidebarItemLimit + 100,
    );
  }

  void toggleAll(bool selected) {
    for (var node in state.treeNodes) {
      _setSelectionRecursive(node, selected);
    }
    _updateParentSelection(state.treeNodes);
    
    // Optimize for mass select-all
    final updatedItems = state.items.map((item) {
      item.isSelected = selected;
      return item;
    }).toList();

    state = state.copyWith(
      items: updatedItems,
      treeNodes: List.from(state.treeNodes),
      selectedItems: selected ? updatedItems : [],
      sidebarItemLimit: 50,
    );
  }


  Future<void> sync() async {
    if (state.items.isEmpty) return;
    
    state = state.copyWith(isSyncing: true, syncProgress: 0.0, syncingFileName: '');
    
    final selectedItems = state.items.where((e) => e.isSelected).toList();
    if (selectedItems.isEmpty) {
       state = state.copyWith(isSyncing: false);
       return;
    }

    await SyncService.syncItems(
      selectedItems,
      onProgress: (count, total, fileName) {
        state = state.copyWith(
          syncProgress: count / total,
          syncingFileName: fileName,
        );
      },
    );
    
    state = state.copyWith(isSyncing: false, syncProgress: 1.0, syncingFileName: null);
    await _compare();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
