import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HelpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showHelpDialog(context),
      icon: const Icon(LucideIcons.helpCircle, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        padding: const EdgeInsets.all(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      tooltip: 'User Manual',
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
            ),
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
                const Spacer(),
                _HelpButton(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Choose your synchronization method to begin.',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
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
                  ),
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
                  ),
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

Widget _buildSectionHeader(String title) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.grey,
        ),
      ),
    ],
  );
}

class _LeftSidebar extends ConsumerStatefulWidget {
  const _LeftSidebar();

  @override
  ConsumerState<_LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends ConsumerState<_LeftSidebar> {
  late TextEditingController _speedController;

  @override
  void initState() {
    super.initState();
    final initialSpeed = ref.read(syncProvider).speedLimit;
    _speedController = TextEditingController(
      text: initialSpeed == 0 ? '' : initialSpeed.toString(),
    );
  }

  @override
  void dispose() {
    _speedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(syncProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: const Color(0xFF0F0F0F),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
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
                const SizedBox(width: 8),
                _HelpButton(),
              ],
            ),
            const SizedBox(height: 48),
            _buildSectionHeader('FOLDERS'),
            const SizedBox(height: 16),
            const FolderSelectorRow(),
            const SizedBox(height: 32),
            // Consolidated Sync Controls Section
            Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(syncProvider);
                final notifier = ref.read(syncProvider.notifier);
                final isTwoWay = state.isTwoWaySync;
                final isSyncing = state.isSyncing;
                final selectedCount = state.selectedCount;
                final isVisible = (state.sourcePath != null &&
                        state.sourcePath!.isNotEmpty &&
                        state.targetPath != null &&
                        state.targetPath!.isNotEmpty) ||
                    isSyncing;

                if (!isVisible) return const SizedBox.shrink();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2-Way Sync Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isTwoWay ? Colors.purpleAccent : Colors.grey)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isTwoWay ? LucideIcons.repeat : LucideIcons.arrowRight,
                              size: 16,
                              color: isTwoWay ? Colors.purpleAccent : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '2-Way Sync',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  isTwoWay ? 'Sync Both' : 'Push Only',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isTwoWay,
                            onChanged: isSyncing
                                ? null
                                : (val) => notifier.toggleTwoWaySync(val),
                            mouseCursor: isSyncing
                                ? SystemMouseCursors.forbidden
                                : SystemMouseCursors.click,
                            activeThumbColor: Colors.purpleAccent,
                            activeTrackColor: Colors.purpleAccent.withValues(
                              alpha: 0.2,
                            ),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.white10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Speed Limit Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.gauge,
                                size: 14,
                                color: Colors.blueAccent.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'SPEED LIMIT',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                state.speedLimit == 0 ? 'Unlimited' : '${state.speedLimit} MB/s',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 11,
                                  color: Colors.blueAccent.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _speedController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: '0 (Unlimited)',
                              hintStyle: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 12,
                              ),
                              suffixText: 'MB/s',
                              suffixStyle: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blueAccent.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              final limit = int.tryParse(val) ?? 0;
                              notifier.setSpeedLimit(limit);
                            },
                          ),
                        ],
                      ),
                    ),

                    if (selectedCount > 0 || isSyncing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isSyncing ? null : () => notifier.sync(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.3,
                          ),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.5,
                          ),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isSyncing ? 0 : 8,
                          shadowColor: Colors.blueAccent.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSyncing)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              const Icon(LucideIcons.refreshCw, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              isSyncing ? 'Syncing...' : 'Sync $selectedCount Items',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset('assets/logo.png', width: 22, height: 22),
        ),
        const SizedBox(width: 14),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFAAAAAA)],
          ).createShader(bounds),
          child: const Text(
            'Sync Pro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
        ),
      ],
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
                      _buildSectionHeader('STRUCTURE'),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed:
                            state.isComparing ||
                                state.isBackgroundScanning ||
                                state.isSyncing
                            ? null
                            : () => notifier.reload(),
                        mouseCursor:
                            (state.isComparing ||
                                state.isBackgroundScanning ||
                                state.isSyncing)
                            ? SystemMouseCursors.forbidden
                            : SystemMouseCursors.click,
                        icon: Icon(
                          LucideIcons.refreshCw,
                          size: 16,
                          color:
                              state.isComparing ||
                                  state.isBackgroundScanning ||
                                  state.isSyncing
                              ? Colors.grey
                              : Colors.blueAccent,
                        ),
                        tooltip: 'Reload structure',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (state.isBackgroundScanComplete &&
                          !state.isBackgroundScanning)
                        const Icon(
                          LucideIcons.checkCircle2,
                          color: Colors.greenAccent,
                          size: 14,
                        ),
                      if (state.isBackgroundScanComplete &&
                          !state.isBackgroundScanning)
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
                          fontFamily: 'Fredoka',
                          color: state.isBackgroundScanning
                              ? Colors.blueAccent.withValues(alpha: 0.7)
                              : (state.isBackgroundScanComplete
                                    ? Colors.greenAccent.withValues(alpha: 0.8)
                                    : Colors.grey),
                          fontSize: 13,
                        ),
                      ),
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
          ),
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
        foregroundColor: disabled
            ? Colors.grey.withValues(alpha: 0.3)
            : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Fredoka',
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
    final notifier = ref.read(syncProvider.notifier);
    final sidebarItems = ref.watch(syncProvider.select((s) => s.sidebarItems));
    final sidebarLimit = ref.watch(
      syncProvider.select((s) => s.sidebarItemLimit),
    );
    final sidebarSearchQuery = ref.watch(
      syncProvider.select((s) => s.sidebarSearchQuery),
    );

    final displayedItems = sidebarItems.take(sidebarLimit).toList();
    final hasMore = sidebarItems.length > sidebarLimit;

    // These don't change during sync progress, only on major state changes
    final sidebarSortOrder = ref.watch(
      syncProvider.select((s) => s.sidebarSortOrder),
    );
    final selectedCount = ref.watch(
      syncProvider.select((s) => s.selectedCount),
    );
    final totalSelectedSize = ref.watch(
      syncProvider.select((s) => s.totalSelectedSize),
    );
    final syncProgress = ref.watch(syncProvider.select((s) => s.syncProgress));
    final isSyncing = ref.watch(syncProvider.select((s) => s.isSyncing));
    final syncedFilesCount = ref.watch(
      syncProvider.select((s) => s.syncedFilesCount),
    );
    final syncTotalBytes = ref.watch(
      syncProvider.select((s) => s.syncTotalBytes),
    );

    // Watch itemsRevision to force rebuild when selection logic clears/rebuilds internal state
    ref.watch(syncProvider.select((s) => s.itemsRevision));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSectionHeader('TRANSFER QUEUE'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => notifier.toggleAll(true),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: Colors.blueAccent.withValues(alpha: 0.1),
                      ),
                      child: const Text(
                        'All',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => notifier.toggleAll(false),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: Colors.redAccent.withValues(alpha: 0.1),
                      ),
                      child: const Text(
                        'None',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              notifier.setSidebarSearchQuery(val),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search in queue...',
                            hintStyle: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (sidebarSearchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => notifier.setSidebarSearchQuery(''),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      const SizedBox(width: 10),
                      const VerticalDivider(
                        width: 1,
                        indent: 10,
                        endIndent: 10,
                        color: Colors.white12,
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<SidebarSortOrder>(
                        offset: const Offset(0, 40),
                        icon: Icon(
                          LucideIcons.listFilter,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Sort By',
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (order) =>
                            notifier.setSidebarSortOrder(order),
                        itemBuilder: (context) => [
                          _buildSortItem(
                            SidebarSortOrder.name,
                            'Name',
                            LucideIcons.type,
                            sidebarSortOrder,
                          ),
                          _buildSortItem(
                            SidebarSortOrder.size,
                            'Size',
                            LucideIcons.hardDrive,
                            sidebarSortOrder,
                          ),
                          _buildSortItem(
                            SidebarSortOrder.status,
                            'Status',
                            LucideIcons.info,
                            sidebarSortOrder,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Size and count summary
                Row(
                  children: [
                    Icon(
                      LucideIcons.file,
                      size: 13,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      syncProgress >= 1.0 && selectedCount == 0 && !isSyncing
                          ? '$syncedFilesCount files synced'
                          : '$selectedCount files',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.hardDrive,
                      size: 13,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      syncProgress >= 1.0 && selectedCount == 0 && !isSyncing
                          ? _formatBytes(syncTotalBytes)
                          : _formatBytes(totalSelectedSize),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: sidebarItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.inbox,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Queue is empty',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    color: Colors.white.withValues(alpha: 0.2),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount:
                                displayedItems.length + (hasMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              if (index == displayedItems.length) {
                                return _buildLoadMore(
                                  ref,
                                  sidebarItems.length - sidebarLimit,
                                );
                              }
                              final item = displayedItems[index];
                              return _SyncItemTile(
                                key: ValueKey('sidebar_${item.relativePath}'),
                                item: item,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Dashboard & Report Section
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(syncProvider);
              final bool showDashboard = state.isSyncing;
              final bool showReport =
                  state.syncProgress >= 1.0 &&
                  !state.isSyncing &&
                  state.syncTotalCount > 0;

              if (showDashboard) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Colors.white10),
                    _buildSyncDashboard(state, notifier),
                  ],
                );
              }

              if (showReport) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: Colors.white10),
                    _buildSyncReport(state, notifier),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.blueAccent : Colors.grey,
          ),
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
} // End of _RightSidebar

Widget _buildSyncDashboard(SyncState state, SyncNotifier notifier) {
  return RepaintBoundary(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE SYNC',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.isSyncPaused ? 'PAUSED' : 'IN PROGRESS',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _IconButton(
                    icon: state.isSyncPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    onPressed: () => notifier.togglePauseSyncing(),
                    tooltip: state.isSyncPaused ? 'Resume' : 'Pause',
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.stop_rounded,
                    onPressed: () => notifier.stopSyncing(),
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    tooltip: 'Abort',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Overall Progress Metric
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  (state.syncProgress * 100).toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '%',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Overall Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: state.syncProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          // Metrics Grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricWidget(
                        'SPEED',
                        _formatSpeed(state.syncSpeed),
                        LucideIcons.zap,
                        Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricWidget(
                        'ETA',
                        state.remainingTime != null
                            ? _formatDuration(state.remainingTime!)
                            : '--',
                        LucideIcons.timer,
                        Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.white10),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricWidget(
                        'FILES',
                        '${state.syncedCount} / ${state.syncTotalCount}',
                        LucideIcons.fileCheck,
                        Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricWidget(
                        'SIZE',
                        '${_formatBytes(state.syncedBytes)} / ${_formatBytes(state.syncTotalBytes)}',
                        LucideIcons.database,
                        Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // CURRENT FILE DETAILS
          if (state.syncingFileName != null &&
              state.syncingFileName!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  LucideIcons.refreshCcw,
                  size: 12,
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.syncingFileName!,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (state.syncingFileTotalBytes > 0)
                  Opacity(
                    opacity: state.syncingFileTotalBytes >= 50 * 1024 * 1024
                        ? 1.0
                        : 0.0,
                    child: Text(
                      '${(state.syncingFileBytes / state.syncingFileTotalBytes * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.syncingFileTotalBytes > 0) ...[
              Opacity(
                opacity: state.syncingFileTotalBytes >= 50 * 1024 * 1024
                    ? 1.0
                    : 0.0,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            state.syncingFileBytes /
                            state.syncingFileTotalBytes,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.purpleAccent,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatBytes(state.syncingFileBytes)} of ${_formatBytes(state.syncingFileTotalBytes)}',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}

Widget _buildSyncReport(SyncState state, SyncNotifier notifier) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    decoration: BoxDecoration(
      color: const Color(0xFF0F0F0F).withValues(alpha: 0.98),
      borderRadius: BorderRadius.zero,
      border: Border(
        top: BorderSide(
          color: Colors.greenAccent.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 30,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.greenAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SYNC COMPLETE',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${state.syncedFilesCount} files synced successfully (${_formatBytes(state.syncedBytes)})',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => notifier.clearSyncProgress(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Text(
            'Dismiss',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMetricWidget(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  );
}

String _formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 B/s';
  const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s', 'TB/s'];
  int i = 0;
  double speed = bytesPerSecond;
  while (speed >= 1024 && i < suffixes.length - 1) {
    speed /= 1024;
    i++;
  }
  return '${speed.toStringAsFixed(1)} ${suffixes[i]}';
}

String _formatDuration(Duration duration) {
  if (duration.isNegative) return '--';
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return '$hours:${minutes}h';
  } else if (duration.inMinutes > 0) {
    return '$minutes:${seconds}m';
  } else {
    return '${seconds}s';
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color ?? Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
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

class _SyncItemTile extends ConsumerStatefulWidget {
  final SyncItem item;
  const _SyncItemTile({super.key, required this.item});

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (_isHovered ? Colors.blueAccent : Colors.white)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.item.type == SyncType.directory
                    ? LucideIcons.folder
                    : LucideIcons.file,
                size: 14,
                color: (_isHovered ? Colors.blueAccent : Colors.grey)
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.item.relativePath,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        color: _isHovered
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontWeight: _isHovered
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.item.type == SyncType.file &&
                      widget.item.fileSize > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      _formatBytes(widget.item.fileSize),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  _buildOwnershipLine(widget.item.status),
                ],
              ),
            ),
            _StatusIcon(status: widget.item.status),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: widget.item.isSelected,
                activeColor:
                    (isSyncing || widget.item.status == FileStatus.identical)
                    ? Colors.blueAccent.withValues(alpha: 0.3)
                    : Colors.blueAccent,
                checkColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha:
                        (isSyncing ||
                            widget.item.status == FileStatus.identical)
                        ? 0.05
                        : 0.2,
                  ),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged:
                    (isSyncing || widget.item.status == FileStatus.identical)
                    ? null
                    : (val) => ref
                          .read(syncProvider.notifier)
                          .toggleItemSelectionByPath(
                            widget.item.relativePath,
                            val ?? false,
                          ),
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
          fontFamily: 'Fredoka',
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
                        fontFamily: 'Fredoka',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Choose a file sync tool',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _HelpButton(),
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

void _showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.helpCircle, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'USER MANUAL',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpSection(
                        '1. Folder Selection',
                        'Choose a SOURCE folder (where your files are) and a TARGET folder (where you want them to go). The app scans for differences automatically.',
                        LucideIcons.folderSearch,
                      ),
                      _buildHelpSection(
                        '2. Sync Modes',
                        '• 2-Way Sync: Keeps both folders identical by copying changes in both directions.\n• Push Only: Only copies changes from Source to Target.',
                        LucideIcons.repeat,
                      ),
                      _buildHelpSection(
                        '3. Transfer Speed',
                        'Set a Speed Limit in the sidebar (MB/s) to throttle bandwidth. Use 0 for Unlimited. You can change this even while syncing!',
                        LucideIcons.gauge,
                      ),
                      _buildHelpSection(
                        '4. Transfer Queue',
                        'The right sidebar shows all detected differences. Use checkboxes to select what to sync, or use the "All/None" shortcuts.',
                        LucideIcons.list,
                      ),
                      _buildHelpSection(
                        '5. Start Sync',
                        'Click the primary "Sync Items" button to begin. You can pause or stop the process at any time from the dashboard.',
                        LucideIcons.refreshCw,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildHelpSection(String title, String description, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent.withValues(alpha: 0.6)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
