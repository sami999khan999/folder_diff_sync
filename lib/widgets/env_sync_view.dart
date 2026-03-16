import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/env_sync_provider.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';
import '../models/env_sync_item.dart';
import 'glass_card.dart';

class EnvSyncView extends ConsumerStatefulWidget {
  const EnvSyncView({super.key});

  @override
  ConsumerState<EnvSyncView> createState() => _EnvSyncViewState();
}

class _EnvSyncViewState extends ConsumerState<EnvSyncView> {
  final _fileNameController = TextEditingController(text: '.env.example');

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final envState = ref.watch(envSyncProvider);
    final envNotifier = ref.read(envSyncProvider.notifier);
    final syncNotifier = ref.read(syncProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(syncNotifier),
            const SizedBox(height: 32),
            // Source file picker
            _buildSourcePicker(
              envState,
              envNotifier,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            // Options row
            Row(
              children: [
                Expanded(child: _buildOutputDirPicker(envState, envNotifier)),
                const SizedBox(width: 16),
                Expanded(child: _buildFileNameField(envNotifier)),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            // Hide values toggle
            _buildHideValuesToggle(
              envState,
              envNotifier,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            // Preview
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: envState.entries.isEmpty
                    ? _buildPlaceholder()
                    : _buildPreview(envState),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
            ),
            // Footer
            if (envState.entries.isNotEmpty)
              _buildFooter(
                envState,
                envNotifier,
              ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SyncNotifier syncNotifier) {
    return Row(
      children: [
        IconButton(
          onPressed: () => syncNotifier.setMode(AppMode.fileContentSync),
          icon: const Icon(LucideIcons.arrowLeft),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.fileCode,
            color: Colors.greenAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Env File Sync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            Text(
              'Generate env templates from existing files',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourcePicker(EnvSyncState state, EnvSyncNotifier notifier) {
    return _HoverCard(
      color: Colors.blueAccent,
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          dialogTitle: 'Select .env file',
        );
        if (result != null && result.files.single.path != null) {
          notifier.setSourceFile(result.files.single.path!);
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.filePlus,
              size: 20,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Source .env File',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  state.sourceFilePath ?? 'Click to select an env file...',
                  style: TextStyle(
                    fontSize: 13,
                    color: state.sourceFilePath != null
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.grey.withValues(alpha: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (state.entries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${state.entries.where((e) => e.key != null).length} vars',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputDirPicker(EnvSyncState state, EnvSyncNotifier notifier) {
    return _HoverCard(
      color: Colors.purpleAccent,
      onTap: () async {
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select output directory',
        );
        if (result != null) notifier.setOutputDirectory(result);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.folderOutput,
              size: 16,
              color: Colors.purpleAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Output Directory',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  state.outputDirectory ?? 'Same as source (default)',
                  style: TextStyle(
                    fontSize: 11,
                    color: state.outputDirectory != null
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNameField(EnvSyncNotifier notifier) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.fileEdit,
              size: 16,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _fileNameController,
              onChanged: (val) => notifier.setOutputFileName(val),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Output File Name',
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHideValuesToggle(EnvSyncState state, EnvSyncNotifier notifier) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SwitchListTile(
        title: const Text(
          'Hide Values',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: const Text(
          'Output only variable names without values',
          style: TextStyle(fontSize: 12),
        ),
        value: state.hideValues,
        onChanged: (val) => notifier.toggleHideValues(val),
        secondary: Icon(
          state.hideValues ? LucideIcons.eyeOff : LucideIcons.eye,
          size: 20,
          color: state.hideValues ? Colors.orangeAccent : Colors.grey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.fileCode,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select an .env file to preview its contents',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPreview(EnvSyncState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              const Text(
                'Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: state.hideValues
                      ? Colors.orangeAccent.withValues(alpha: 0.1)
                      : Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.hideValues ? 'VALUES HIDDEN' : 'WITH VALUES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: state.hideValues
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 24, endIndent: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return _buildPreviewLine(entry, state.hideValues, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewLine(EnvEntry entry, bool hideValues, int index) {
    if (entry.isBlank) {
      return const SizedBox(height: 16);
    }

    if (entry.isComment) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          entry.rawLine,
          style: TextStyle(
            fontFamily: 'Consolas',
            fontSize: 13,
            color: Colors.grey.withValues(alpha: 0.4),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
          children: [
            TextSpan(
              text: entry.key,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '=',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            if (!hideValues)
              TextSpan(
                text: entry.value,
                style: const TextStyle(color: Colors.greenAccent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(EnvSyncState state, EnvSyncNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (state.isGenerated)
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    size: 16,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generated: ${state.generatedPath}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              '${state.entries.where((e) => e.key != null).length} variables found',
              style: const TextStyle(color: Colors.grey),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: state.isProcessing || state.entries.isEmpty
                ? null
                : () => notifier.generateFile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: Icon(
              state.isProcessing ? LucideIcons.loader : LucideIcons.download,
              size: 18,
            ),
            label: Text(
              state.isProcessing ? 'Generating...' : 'Generate File',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _HoverCard({
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          hoverColor: Colors.transparent,
          splashColor: widget.color.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
