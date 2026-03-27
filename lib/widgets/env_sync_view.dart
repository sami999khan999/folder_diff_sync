import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../providers/env_sync_provider.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';
import 'glass_card.dart';
import 'folder_selector.dart';
import 'primary_button.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerThickness: 4,
            dividerPainter: DividerPainter(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              highlightedBackgroundColor: Colors.greenAccent.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: MultiSplitView(
            initialAreas: [
              Area(
                flex: 0.25,
                min: 0.20,
                builder: (context, area) =>
                    _LeftSidebar(fileNameController: _fileNameController),
              ),
              Area(
                flex: 0.5,
                min: 0.4,
                builder: (context, area) => const _MiddleSection(),
              ),
              Area(
                flex: 0.25,
                min: 0.20,
                builder: (context, area) => const _RightSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftSidebar extends ConsumerStatefulWidget {
  final TextEditingController fileNameController;

  const _LeftSidebar({required this.fileNameController});

  @override
  ConsumerState<_LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends ConsumerState<_LeftSidebar> {
  bool _showOutputDir = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(envSyncProvider);
    final notifier = ref.read(envSyncProvider.notifier);
    final syncNotifier = ref.read(syncProvider.notifier);

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
                onPressed: () => syncNotifier.setMode(AppMode.fileContentSync),
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildLogo()),
              const SizedBox(width: 8),
              const _HelpButton(),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'CONFIGURATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PathSelectorCard(
                    title: 'Source .env File',
                    path: state.sourceFilePath,
                    hintText: 'Select source .env file...',
                    icon: LucideIcons.filePlus,
                    color: Colors.blueAccent,
                    onManualPath: (path) => notifier.setSourceFile(path),
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        dialogTitle: 'Select .env file',
                      );
                      if (result != null && result.files.single.path != null) {
                        notifier.setSourceFile(result.files.single.path!);
                      }
                    },
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),
                  if (state.sourceFilePath != null && !_showOutputDir)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Output will be saved to:',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.outputDirectory ?? 'Same directory as source',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showOutputDir = true),
                            icon: const Icon(LucideIcons.folderEdit, size: 14),
                            label: const Text(
                              'Change Directory',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  if (_showOutputDir) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowDown,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PathSelectorCard(
                      title: 'Output Directory',
                      path: state.outputDirectory,
                      hintText: 'Same as source (default)',
                      icon: LucideIcons.folderOutput,
                      color: Colors.purpleAccent,
                      onManualPath: (path) => notifier.setOutputDirectory(path),
                      onTap: () async {
                        final result = await FilePicker.platform
                            .getDirectoryPath(
                              dialogTitle: 'Select output directory',
                            );
                        if (result != null) notifier.setOutputDirectory(result);
                      },
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ],
              ),
            ),
          ),
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
              colors: [Colors.greenAccent, Colors.tealAccent],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.fileCode,
            color: Colors.black87,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.grey],
          ).createShader(bounds),
          child: const Text(
            'Env Sync',
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
}

class _MiddleSection extends ConsumerStatefulWidget {
  const _MiddleSection();

  @override
  ConsumerState<_MiddleSection> createState() => _MiddleSectionState();
}

class _MiddleSectionState extends ConsumerState<_MiddleSection> {
  late _EnvSyntaxController _textController;

  @override
  void initState() {
    super.initState();
    _textController = _EnvSyntaxController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(envSyncProvider);
    final notifier = ref.read(envSyncProvider.notifier);

    _textController.updateHideValues(state.hideValues);

    ref.listen(envSyncProvider, (previous, next) {
      final fileLoaded = previous?.lastLoadedAt != next.lastLoadedAt;

      if (fileLoaded) {
        final newText = next.entries
            .map((e) => e.toOutputLine(hideValues: false))
            .join('\n');
        if (_textController.text != newText) {
          _textController.text = newText;
        }
      }
    });

    if (_textController.text.isEmpty && state.entries.isNotEmpty) {
      _textController.text = state.entries
          .map((e) => e.toOutputLine(hideValues: false))
          .join('\n');
    }

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
                        'Preview',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: state.hideValues
                              ? Colors.orangeAccent.withValues(alpha: 0.1)
                              : Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 4),
                  Text(
                    state.entries.isEmpty
                        ? 'Select an .env file to preview its contents'
                        : '${state.entries.where((e) => e.key != null).length} variables found',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              blur: 10,
              opacity: 0.02,
              child: state.entries.isEmpty
                  ? Center(
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
                            'No data to display',
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        readOnly: false,
                        inputFormatters: [
                          _HideValuesFormatter(hideValues: state.hideValues),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          notifier.updateRawContent(val);
                        },
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.02),
        ],
      ),
    );
  }
}

class _RightSidebar extends ConsumerStatefulWidget {
  const _RightSidebar();

  @override
  ConsumerState<_RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends ConsumerState<_RightSidebar> {
  late TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(envSyncProvider);
    _fileNameController = TextEditingController(text: state.outputFileName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.watch(envSyncProvider);
    if (state.outputFileName != _fileNameController.text) {
      _fileNameController.text = state.outputFileName;
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(envSyncProvider);
    final notifier = ref.read(envSyncProvider.notifier);

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
                  const Text(
                    'OUTPUT PREFERENCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.fileEdit,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Output File Name',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fileNameController,
                          onChanged: (val) => notifier.setOutputFileName(val),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
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
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
          _buildSidebarCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Hide Values',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  value: state.hideValues,
                  onChanged: (val) => notifier.toggleHideValues(val),
                  secondary: AnimatedRotation(
                    duration: 300.ms,
                    turns: state.hideValues ? 0.5 : 0,
                    child: Icon(
                      state.hideValues ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: state.hideValues
                          ? Colors.orangeAccent
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),
                if (state.outputExists)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'File Exists! Replace?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      value: state.replaceFile,
                      onChanged: (val) => notifier.toggleReplaceFile(val),
                      activeThumbColor: Colors.orangeAccent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      dense: true,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed:
                        state.isProcessing ||
                            state.entries.isEmpty ||
                            (state.outputExists && !state.replaceFile)
                        ? null
                        : () => notifier.generateFile(),
                    icon: state.isProcessing
                        ? LucideIcons.loader
                        : LucideIcons.download,
                    label: state.isProcessing
                        ? 'Generating...'
                        : 'Generate File',
                    color: Colors.greenAccent.withValues(alpha: 0.8),
                    isLoading: state.isProcessing,
                  ),
                ),
                if (state.isGenerated) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle,
                          size: 14,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Generated to: ${state.generatedPath ?? "Directory"}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildSidebarCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _EnvSyntaxController extends TextEditingController {
  bool hideValues = false;

  _EnvSyntaxController();

  void updateHideValues(bool value) {
    if (hideValues != value) {
      hideValues = value;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('#')) {
        // Comment
        children.add(
          TextSpan(
            text: line,
            style: style?.copyWith(
              color: Colors.grey.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (trimmed.contains('=')) {
        // Key/Value Pair
        final eqIndex = line.indexOf('=');
        final keyPart = line.substring(0, eqIndex + 1); // includes '='
        final valuePart = line.substring(eqIndex + 1);

        String displayValue = valuePart;
        if (hideValues) {
          // Replace each character with a dot, but keep the \r if present
          if (valuePart.endsWith('\r')) {
            displayValue = '•' * (valuePart.length - 1) + '\r';
          } else {
            displayValue = '•' * valuePart.length;
          }
        }

        children.add(
          TextSpan(
            children: [
              TextSpan(
                text: keyPart,
                style: style?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: displayValue,
                style: style?.copyWith(color: Colors.greenAccent),
              ),
            ],
          ),
        );
      } else {
        // Plain text / empty space
        children.add(TextSpan(text: line, style: style));
      }

      if (i < lines.length - 1) {
        children.add(TextSpan(text: '\n', style: style));
      }
    }

    return TextSpan(style: style, children: children);
  }
}

class _HideValuesFormatter extends TextInputFormatter {
  final bool hideValues;
  _HideValuesFormatter({required this.hideValues});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!hideValues) return newValue;

    // Detect what changed by finding the first difference
    int firstDiff = 0;
    while (firstDiff < oldValue.text.length &&
        firstDiff < newValue.text.length &&
        oldValue.text[firstDiff] == newValue.text[firstDiff]) {
      firstDiff++;
    }

    // Check if the difference happened after an '=' in that line
    final prefix = newValue.text.substring(0, firstDiff);
    final lastNewLine = prefix.lastIndexOf('\n');
    final startOfLine = lastNewLine == -1 ? 0 : lastNewLine + 1;
    final currentLinePrefix = prefix.substring(startOfLine);

    if (currentLinePrefix.contains('=')) {
      // If the change is after the first '=', block it
      return oldValue;
    }

    return newValue;
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showEnvHelpDialog(context),
      icon: const Icon(LucideIcons.helpCircle, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        padding: const EdgeInsets.all(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      tooltip: 'Env Sync Manual',
    );
  }
}

void _showEnvHelpDialog(BuildContext context) {
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
                        color: Colors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.helpCircle,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'ENV SYNC MANUAL',
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
                        '1. Source Selection',
                        'Pick your .env or configuration file. The app will parse its keys and values automatically for preview.',
                        LucideIcons.filePlus,
                      ),
                      _buildHelpSection(
                        '2. Masking Values',
                        'Use the "Hide Values" feature to mask sensitive information (like API keys or passwords). Perfect for creating shared templates.',
                        LucideIcons.eyeOff,
                      ),
                      _buildHelpSection(
                        '3. Output Controls',
                        'Customize the output filename and choose a save directory. By default, it saves to the same folder as the source.',
                        LucideIcons.folderOutput,
                      ),
                      _buildHelpSection(
                        '4. Live Preview',
                        'View and edit your configuration directly. The editor includes syntax highlighting and real-time validation.',
                        LucideIcons.edit3,
                      ),
                      _buildHelpSection(
                        '5. Generate File',
                        'Click "Generate File" to export your changes. If the target file already exists, you can choose to replace it.',
                        LucideIcons.download,
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
        Icon(icon, size: 18, color: Colors.greenAccent.withValues(alpha: 0.6)),
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
