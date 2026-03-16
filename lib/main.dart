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
import 'package:multi_split_view/multi_split_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder Sync Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Minecraft',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(letterSpacing: 3),
          bodyMedium: TextStyle(letterSpacing: 3),
          bodySmall: TextStyle(letterSpacing: 3),
          titleLarge: TextStyle(letterSpacing: 3),
          titleMedium: TextStyle(letterSpacing: 3),
          titleSmall: TextStyle(letterSpacing: 3),
          displayLarge: TextStyle(letterSpacing: 3),
          displayMedium: TextStyle(letterSpacing: 3),
          displaySmall: TextStyle(letterSpacing: 3),
          headlineLarge: TextStyle(letterSpacing: 3),
          headlineMedium: TextStyle(letterSpacing: 3),
          headlineSmall: TextStyle(letterSpacing: 3),
          labelLarge: TextStyle(letterSpacing: 3),
          labelMedium: TextStyle(letterSpacing: 3),
          labelSmall: TextStyle(letterSpacing: 3),
        ),
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
          style: const TextStyle(fontFamily: 'Minecraft', letterSpacing: 5),
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
            const Text(
                  'Folder Sync Pro',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
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
              letterSpacing: 3,
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
                  child: _buildPrimaryButton(
                    onPressed:
                        state.isSyncing || !state.items.any((e) => e.isSelected)
                        ? null
                        : () => notifier.sync(),
                    icon: LucideIcons.copy,
                    label: 'Start Syncing',
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.cyanAccent],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.refreshCw,
            color: Colors.white,
            size: 20,
          ),
        ),
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
              letterSpacing: 4,
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

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 18),
            label: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
        )
        .animate(target: onPressed == null ? 0 : 1)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
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
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: state.isComparing || state.isBackgroundScanning
                            ? null
                            : () => notifier.reload(),
                        icon: Icon(
                          LucideIcons.refreshCw,
                          size: 16,
                          color: state.isComparing || state.isBackgroundScanning
                              ? Colors.grey
                              : Colors.blueAccent,
                        ),
                        tooltip: 'Reload structure',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ).animate(target: state.isComparing || state.isBackgroundScanning ? 1 : 0).shimmer(),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        state.isBackgroundScanning ? 'Discovering files...' : 'Select items to include in sync',
                        style: TextStyle(
                          color: state.isBackgroundScanning ? Colors.blueAccent.withValues(alpha: 0.7) : Colors.grey,
                          fontSize: 13,
                          fontWeight: state.isBackgroundScanning ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (state.isBackgroundScanning) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blueAccent.withValues(alpha: 0.5),
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
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                onPressed: () => notifier.toggleAll(false),
                icon: LucideIcons.circle,
                label: 'None',
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
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RightSidebar extends ConsumerWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);
    final displayedItems = state.selectedItems.take(state.sidebarItemLimit).toList();
    final hasMore = state.selectedItems.length > state.sidebarItemLimit;

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
                      const Text(
                        'TRANSFER QUEUE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${state.selectedItems.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: state.selectedItems.isEmpty
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
                            itemCount: displayedItems.length + (hasMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              if (index == displayedItems.length) {
                                return _buildLoadMore(ref, state.selectedItems.length - state.sidebarItemLimit);
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
            _buildProgressFooter(state).animate().fadeIn().slideY(begin: 0.1),
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

  Widget _buildProgressFooter(SyncState state) {
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
            children: [
              Text(
                state.isSyncing ? 'Synchronizing...' : 'Completed',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
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
          if (state.syncingFileName != null &&
              state.syncingFileName!.isNotEmpty)
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
}

class _SyncItemTile extends StatefulWidget {
  final SyncItem item;
  const _SyncItemTile({required this.item});

  @override
  State<_SyncItemTile> createState() => _SyncItemTileState();
}

class _SyncItemTileState extends State<_SyncItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(width: 8),
                  _buildOwnershipLine(widget.item.status),
                ],
              ),
            ),
            _StatusIcon(status: widget.item.status),
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
                        letterSpacing: 4,
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
