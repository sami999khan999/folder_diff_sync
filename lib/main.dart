import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/sync_item.dart';
import 'providers/sync_provider.dart';
import 'widgets/folder_selector.dart';
import 'widgets/glass_card.dart';
import 'widgets/env_sync_view.dart';
import 'widgets/sync_tree_view.dart';
import 'widgets/primary_button.dart';
import 'package:multi_split_view/multi_split_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder Diff Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Fredoka',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF0F0F0F),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ),
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Fredoka'),
          child: child!,
        );
      },
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends ConsumerWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(syncProvider.select((s) => s.currentMode));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14142B), Color(0xFF0F0F0F), Color(0xFF050505)],
          ),
        ),
        child: AnimatedSwitcher(
          duration: 600.ms,
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: mode == AppMode.selection
              ? const SelectionScreen()
              : mode == AppMode.folderSync
              ? const FolderSyncView()
              : mode == AppMode.fileContentSync
              ? const FileContentSyncScreen()
              : const EnvSyncView(),
        ),
      ),
    );
  }
}

class SelectionScreen extends ConsumerWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: MaxWidthContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to',
              style: TextStyle(
                color: Colors.blueAccent.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
            Row(
              children: [
                Image.asset('assets/logo.png', width: 44, height: 44),
                const SizedBox(width: 16),
                const Text(
                  'Folder Diff Sync',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
                  'Choose your synchronization method to begin.',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ModeCard(
                    title: 'Folder & Subfolder Sync',
                    description:
                        'Keep entire directory structures in sync across devices or locations.',
                    icon: LucideIcons.folders,
                    color: Colors.blueAccent,
                    onTap: () => ref
                        .read(syncProvider.notifier)
                        .setMode(AppMode.folderSync),
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).scale(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ModeCard(
                    title: 'File Content Sync',
                    description:
                        'Generate env templates, strip values, and manage config files.',
                    icon: LucideIcons.fileText,
                    color: Colors.purpleAccent,
                    onTap: () => ref
                        .read(syncProvider.notifier)
                        .setMode(AppMode.fileContentSync),
                  ).animate().fadeIn(duration: 600.ms, delay: 500.ms).scale(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isComingSoon;

  const ModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: isComingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SOON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderSyncView extends ConsumerWidget {
  const FolderSyncView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerThickness: 4,
            dividerPainter: DividerPainter(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              highlightedBackgroundColor: Colors.blueAccent.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: MultiSplitView(
            initialAreas: [
              Area(
                flex: 0.25,
                min: 0.15,
                builder: (context, area) => const _LeftSidebar(),
              ),
              Area(
                flex: 0.5,
                min: 0.3,
                builder: (context, area) => const _MiddleSection(),
              ),
              Area(
                flex: 0.25,
                min: 0.15,
                builder: (context, area) => const _RightSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftSidebar extends ConsumerWidget {
  const _LeftSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF14142B).withValues(alpha: 0.9),
            const Color(0xFF0F0F0F).withValues(alpha: 1.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => notifier.setMode(AppMode.selection),
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildLogo()),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'FOLDERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 16),
          const FolderSelectorRow().animate().fadeIn(delay: 300.ms),
          const Spacer(),
          _buildSidebarCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Two-Way Sync',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  value: state.isTwoWaySync,
                  onChanged: state.isSyncing
                      ? null
                      : (val) => notifier.toggleTwoWaySync(val),
                  secondary: AnimatedRotation(
                    duration: 300.ms,
                    turns: state.isTwoWaySync ? 0.5 : 0,
                    child: Icon(
                      LucideIcons.arrowLeftRight,
                      size: 18,
                      color: state.isTwoWaySync
                          ? Colors.blueAccent
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed:
                        state.isSyncing || state.isBackgroundScanning || state.selectedCount == 0
                        ? null
                        : () => notifier.sync(),
                    icon: LucideIcons.copy,
                    label: state.isBackgroundScanning ? 'Scanning...' : 'Start Syncing',
                    isLoading: state.isSyncing,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Image.asset('assets/logo.png', width: 24, height: 24),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.grey],
          ).createShader(bounds),
          child: const Text(
            'Sync Pro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSidebarCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _MiddleSection extends ConsumerWidget {
  const _MiddleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Structure',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                            onPressed:
                                state.isComparing || state.isBackgroundScanning || state.isSyncing
                                ? null
                                : () => notifier.reload(),
                            icon: Icon(
                              LucideIcons.refreshCw,
                              size: 16,
                              color:
                                  state.isComparing ||
                                      state.isBackgroundScanning || state.isSyncing
                                  ? Colors.grey
                                  : Colors.blueAccent,
                            ),
                            tooltip: 'Reload structure',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          )
                          .animate(
                            target:
                                state.isComparing || state.isBackgroundScanning || state.isSyncing
                                ? 1
                                : 0,
                          )
                          .shimmer(),
                    ],
                  ),
                   Row(
                    children: [
                      if (state.isBackgroundScanComplete && !state.isBackgroundScanning)
                        const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 14)
                      else
                        const SizedBox.shrink(),
                      if (state.isBackgroundScanComplete && !state.isBackgroundScanning)
                        const SizedBox(width: 8),
                      Text(
                        state.isBackgroundScanning
                            ? 'Checking for differences...'
                            : (state.isBackgroundScanComplete 
                                ? (state.diffCount == 0 
                                    ? 'No differences found. Folders are in sync.' 
                                    : 'Scan complete. Found ${state.diffCount} differences.')
                                : 'Select items to include in sync'),
                        style: TextStyle(
                          color: state.isBackgroundScanning
                              ? Colors.blueAccent.withValues(alpha: 0.7)
                              : (state.isBackgroundScanComplete ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.grey),
                          fontSize: 13,
                          fontWeight: state.isBackgroundScanning || state.isBackgroundScanComplete
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (state.isBackgroundScanning) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _buildActionButton(
                onPressed: () => notifier.toggleAll(true),
                icon: LucideIcons.checkCheck,
                label: 'All',
                disabled: state.isSyncing,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: () => notifier.toggleAll(false),
                icon: LucideIcons.circle,
                label: 'None',
                disabled: state.isSyncing,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              blur: 10,
              opacity: 0.02,
              child: state.isComparing
                  ? const Center(child: CircularProgressIndicator())
                  : const SyncTreeView(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.02),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool disabled = false,
  }) {
    return TextButton.icon(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: disabled ? Colors.grey.withValues(alpha: 0.3) : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: disabled ? Colors.white.withValues(alpha: 0.2) : null,
        ),
      ),
    );
  }
}

class _RightSidebar extends ConsumerWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);
    // Watch itemsRevision for updates
    ref.watch(syncProvider.select((s) => s.itemsRevision));
    final selItems = state.sidebarItems;

    final displayedItems = selItems
        .take(state.sidebarItemLimit)
        .toList();
    final hasMore = selItems.length > state.sidebarItemLimit;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                           Image.asset('assets/logo.png', width: 20, height: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'TRANSFER QUEUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => notifier.toggleAll(true),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('All', style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                      ),
                      TextButton(
                        onPressed: () => notifier.toggleAll(false),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('None', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => notifier.setSidebarSearchQuery(val),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search in queue...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.2)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (state.sidebarSearchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => notifier.setSidebarSearchQuery(''),
                            child: Icon(LucideIcons.x, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                          ),
                        const SizedBox(width: 8),
                        const VerticalDivider(width: 1, indent: 8, endIndent: 8, color: Colors.white12),
                        const SizedBox(width: 4),
                        PopupMenuButton<SidebarSortOrder>(
                          offset: const Offset(0, 40),
                          icon: Icon(LucideIcons.listFilter, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                          padding: EdgeInsets.zero,
                          tooltip: 'Sort By',
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (order) => notifier.setSidebarSortOrder(order),
                          itemBuilder: (context) => [
                            _buildSortItem(SidebarSortOrder.name, 'Name', LucideIcons.type, state.sidebarSortOrder),
                            _buildSortItem(SidebarSortOrder.size, 'Size', LucideIcons.hardDrive, state.sidebarSortOrder),
                            _buildSortItem(SidebarSortOrder.status, 'Status', LucideIcons.info, state.sidebarSortOrder),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Size and count summary
                  Row(
                    children: [
                      Icon(LucideIcons.file, size: 13, color: Colors.grey.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        state.syncProgress >= 1.0 && state.selectedCount == 0 && !state.isSyncing
                            ? '${state.syncedFilesCount} files synced'
                            : '${state.selectedCount} files',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(LucideIcons.hardDrive, size: 13, color: Colors.grey.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        state.syncProgress >= 1.0 && state.selectedCount == 0 && !state.isSyncing
                            ? _formatBytes(state.syncTotalBytes)
                            : _formatBytes(state.totalSelectedSize),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: selItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.inbox,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Queue is empty',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount:
                                displayedItems.length + (hasMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              if (index == displayedItems.length) {
                                return _buildLoadMore(
                                  ref,
                                  selItems.length -
                                      state.sidebarItemLimit,
                                );
                              }
                              final item = displayedItems[index];
                              return _SyncItemTile(item: item);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isSyncing || state.syncProgress > 0)
            _buildProgressFooter(state, notifier).animate().fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildLoadMore(WidgetRef ref, int remaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => ref.read(syncProvider.notifier).loadMoreSidebarItems(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text(
              'Show $remaining more items...',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressFooter(SyncState state, SyncNotifier notifier) {
    final bool isDone = state.syncProgress >= 1.0 && !state.isSyncing;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDone 
                        ? 'SYNC REPORT: ${state.syncedFilesCount}F, ${state.syncedFoldersCount} Dir' 
                        : (state.isSyncing ? 'Synchronizing...' : 'Sync Complete'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isDone)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Total data synced: ${_formatBytes(state.syncTotalBytes)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isDone)
                TextButton(
                  onPressed: () => notifier.clearSyncProgress(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                Text(
                  '${(state.syncProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.syncedCount} / ${state.syncTotalCount} items synced',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  '${_formatBytes(state.syncedBytes)} / ${_formatBytes(state.syncTotalBytes)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
          if (!isDone) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 300.ms,
                      height: 6,
                      width: constraints.maxWidth * state.syncProgress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.cyanAccent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (state.isSyncing && state.syncingFileName != null && state.syncingFileName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.syncingFileName!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<SidebarSortOrder> _buildSortItem(
    SidebarSortOrder order,
    String label,
    IconData icon,
    SidebarSortOrder current,
  ) {
    final isSelected = order == current;
    return PopupMenuItem(
      value: order,
      child: Row(
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.blueAccent : Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blueAccent : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(LucideIcons.check, size: 12, color: Colors.blueAccent),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}

class _SyncItemTile extends ConsumerStatefulWidget {
  final SyncItem item;
  const _SyncItemTile({required this.item});

  @override
  ConsumerState<_SyncItemTile> createState() => _SyncItemTileState();
}

class _SyncItemTileState extends ConsumerState<_SyncItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSyncing = ref.watch(syncProvider.select((s) => s.isSyncing));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              widget.item.type == SyncType.directory
                  ? LucideIcons.folder
                  : LucideIcons.file,
              size: 14,
              color: (_isHovered ? Colors.blueAccent : Colors.grey).withValues(
                alpha: 0.7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.item.relativePath,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isHovered
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: _isHovered
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.item.type == SyncType.file && widget.item.fileSize > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      _RightSidebar._formatBytes(widget.item.fileSize),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildOwnershipLine(widget.item.status),
                ],
              ),
            ),
            _StatusIcon(status: widget.item.status),
            const SizedBox(width: 12),
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: widget.item.isSelected,
                activeColor: (isSyncing || widget.item.status == FileStatus.identical) 
                    ? Colors.blueAccent.withValues(alpha: 0.3) 
                    : Colors.blueAccent,
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: (isSyncing || widget.item.status == FileStatus.identical) ? 0.05 : 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (isSyncing || widget.item.status == FileStatus.identical) 
                    ? null 
                    : (val) => ref.read(syncProvider.notifier).toggleItemSelectionByPath(widget.item.relativePath, val ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnershipLine(FileStatus status) {
    bool inSource = status != FileStatus.missingInSource;
    bool inTarget = status != FileStatus.missingInTarget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOwnershipIndicator(
          "S",
          inSource ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05),
        ),
        const SizedBox(width: 2),
        _buildOwnershipIndicator(
          "T",
          inTarget ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  Widget _buildOwnershipIndicator(String label, Color color) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final FileStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      FileStatus.missingInTarget => _buildIcon(
        LucideIcons.arrowRight,
        Colors.blueAccent,
      ),
      FileStatus.missingInSource => _buildIcon(
        LucideIcons.arrowLeft,
        Colors.purpleAccent,
      ),
      FileStatus.different => _buildIcon(
        LucideIcons.refreshCw,
        Colors.orangeAccent,
      ),
      FileStatus.identical => _buildIcon(
        LucideIcons.checkCircle2,
        Colors.blueAccent,
      ),
    };
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Icon(icon, size: 12, color: color.withValues(alpha: 0.8));
  }
}

class FileContentSyncScreen extends ConsumerWidget {
  const FileContentSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncNotifier = ref.read(syncProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => syncNotifier.setMode(AppMode.selection),
                  icon: const Icon(LucideIcons.arrowLeft),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Content Sync',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Choose a file sync tool',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 48),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ModeCard(
                    title: 'Env File Sync',
                    description:
                        'Generate .env templates, strip values for sharing, and manage environment configuration files.',
                    icon: LucideIcons.fileCode,
                    color: Colors.greenAccent,
                    onTap: () => syncNotifier.setMode(AppMode.envSync),
                  ).animate().fadeIn(delay: 200.ms).scale(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  const MaxWidthContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}
