import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/sync_item.dart';
import 'providers/sync_provider.dart';
import 'widgets/folder_selector.dart';
import 'widgets/diff_list.dart';
import 'widgets/glass_card.dart';
import 'widgets/env_sync_view.dart';

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
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F0F)],
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
              style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.w500),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
            const Text(
              'Folder Sync Pro',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5),
            ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              'Choose your synchronization method to begin.',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 16),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ModeCard(
                    title: 'Folder & Subfolder Sync',
                    description: 'Keep entire directory structures in sync across devices or locations.',
                    icon: LucideIcons.folders,
                    color: Colors.blueAccent,
                    onTap: () => ref.read(syncProvider.notifier).setMode(AppMode.folderSync),
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).scale(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ModeCard(
                    title: 'File Content Sync',
                    description: 'Generate env templates, strip values, and manage config files.',
                    icon: LucideIcons.fileText,
                    color: Colors.purpleAccent,
                    onTap: () => ref.read(syncProvider.notifier).setMode(AppMode.fileContentSync),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('SOON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14),
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
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(syncNotifier),
            const SizedBox(height: 32),
            const FolderSelectorRow().animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: syncState.isComparing
                    ? const Center(child: CircularProgressIndicator())
                    : const DiffList(),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
            ),
            if (syncState.items.isNotEmpty) _buildFooter(syncState, syncNotifier).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SyncNotifier notifier) {
    return Row(
      children: [
        IconButton(
          onPressed: () => notifier.setMode(AppMode.selection),
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
              'Folder Sync',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              'Synchronize entire directory structures',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(SyncState state, SyncNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Two-Way Sync', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Sync missing files to source as well'),
            value: state.isTwoWaySync,
            onChanged: state.isSyncing ? null : (val) => notifier.toggleTwoWaySync(val),
            secondary: Icon(LucideIcons.arrowLeftRight, size: 20, color: state.isTwoWaySync ? Colors.blueAccent : Colors.grey),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 32),
          if (state.isSyncing)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.syncProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Syncing... ${(state.syncProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Text(
                '${state.items.where((e) => e.isSelected).length} items selected to sync',
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: state.isSyncing || state.items.where((e) => e.isSelected).isEmpty
                    ? null
                    : () => notifier.sync(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.copy, size: 18),
                label: const Text('Start Syncing', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
                    description: 'Generate .env templates, strip values for sharing, and manage environment configuration files.',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}
