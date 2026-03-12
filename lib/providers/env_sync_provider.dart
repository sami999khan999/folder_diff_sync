import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/env_sync_item.dart';
import '../services/env_sync_service.dart';

class EnvSyncState {
  final String? sourceFilePath;
  final String? outputDirectory;
  final String outputFileName;
  final bool hideValues;
  final List<EnvEntry> entries;
  final bool isProcessing;
  final bool isGenerated;
  final String? generatedPath;

  EnvSyncState({
    this.sourceFilePath,
    this.outputDirectory,
    this.outputFileName = '.env.example',
    this.hideValues = true,
    this.entries = const [],
    this.isProcessing = false,
    this.isGenerated = false,
    this.generatedPath,
  });

  EnvSyncState copyWith({
    String? sourceFilePath,
    String? outputDirectory,
    String? outputFileName,
    bool? hideValues,
    List<EnvEntry>? entries,
    bool? isProcessing,
    bool? isGenerated,
    String? generatedPath,
  }) {
    return EnvSyncState(
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      outputFileName: outputFileName ?? this.outputFileName,
      hideValues: hideValues ?? this.hideValues,
      entries: entries ?? this.entries,
      isProcessing: isProcessing ?? this.isProcessing,
      isGenerated: isGenerated ?? this.isGenerated,
      generatedPath: generatedPath ?? this.generatedPath,
    );
  }
}

class EnvSyncNotifier extends Notifier<EnvSyncState> {
  @override
  EnvSyncState build() {
    return EnvSyncState();
  }

  Future<void> setSourceFile(String path) async {
    state = state.copyWith(
      sourceFilePath: path,
      isGenerated: false,
      generatedPath: null,
    );
    // Parse immediately
    final entries = await EnvSyncService.parseEnvFile(path);
    state = state.copyWith(entries: entries);
  }

  void setOutputDirectory(String path) {
    state = state.copyWith(outputDirectory: path, isGenerated: false);
  }

  void setOutputFileName(String name) {
    state = state.copyWith(outputFileName: name, isGenerated: false);
  }

  void toggleHideValues(bool value) {
    state = state.copyWith(hideValues: value, isGenerated: false);
  }

  Future<void> generateFile() async {
    if (state.sourceFilePath == null || state.entries.isEmpty) return;

    state = state.copyWith(isProcessing: true, isGenerated: false);

    final outputDir = state.outputDirectory ??
        p.dirname(state.sourceFilePath!);
    final outputPath = p.join(outputDir, state.outputFileName);

    final result = await EnvSyncService.generateEnvFile(
      entries: state.entries,
      outputPath: outputPath,
      hideValues: state.hideValues,
    );

    state = state.copyWith(
      isProcessing: false,
      isGenerated: true,
      generatedPath: result,
    );
  }

  void reset() {
    state = EnvSyncState();
  }
}

final envSyncProvider = NotifierProvider<EnvSyncNotifier, EnvSyncState>(() {
  return EnvSyncNotifier();
});
