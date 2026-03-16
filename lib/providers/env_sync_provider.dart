import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
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
  final bool outputExists;
  final bool replaceFile;
  final DateTime? lastLoadedAt;

  EnvSyncState({
    this.sourceFilePath,
    this.outputDirectory,
    this.outputFileName = '.env.example',
    this.hideValues = true,
    this.entries = const [],
    this.isProcessing = false,
    this.isGenerated = false,
    this.generatedPath,
    this.outputExists = false,
    this.replaceFile = false,
    this.lastLoadedAt,
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
    bool? outputExists,
    bool? replaceFile,
    DateTime? lastLoadedAt,
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
      outputExists: outputExists ?? this.outputExists,
      replaceFile: replaceFile ?? this.replaceFile,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}

class EnvSyncNotifier extends Notifier<EnvSyncState> {
  @override
  EnvSyncState build() {
    return EnvSyncState();
  }

  void _checkFileExistence({String? dir, String? file}) {
    final currentDir = dir ?? state.outputDirectory;
    final sourcePath = state.sourceFilePath;
    final currentFileName = file ?? state.outputFileName;
    
    if (sourcePath == null) {
      state = state.copyWith(outputExists: false, replaceFile: false);
      return;
    }

    final effectiveDir = currentDir ?? p.dirname(sourcePath);
    final outputPath = p.join(effectiveDir, currentFileName);
    
    final exists = File(outputPath).existsSync();
    state = state.copyWith(
      outputExists: exists,
      replaceFile: exists ? state.replaceFile : false, // Reset replace toggle if file no longer exists
    );
  }

  Future<void> setSourceFile(String path) async {
    state = state.copyWith(
      sourceFilePath: path,
      isGenerated: false,
      generatedPath: null,
    );
    _checkFileExistence();
    
    // Parse immediately
    final entries = await EnvSyncService.parseEnvFile(path);
    state = state.copyWith(entries: entries, lastLoadedAt: DateTime.now());
  }

  void setOutputDirectory(String path) {
    state = state.copyWith(outputDirectory: path, isGenerated: false);
    _checkFileExistence(dir: path);
  }

  void setOutputFileName(String name) {
    state = state.copyWith(outputFileName: name, isGenerated: false);
    _checkFileExistence(file: name);
  }

  void toggleReplaceFile(bool value) {
    state = state.copyWith(replaceFile: value);
  }

  void updateRawContent(String content) {
    final newEntries = EnvSyncService.parseEnvContent(content);
    state = state.copyWith(entries: newEntries, isGenerated: false);
  }

  void toggleHideValues(bool value) {
    state = state.copyWith(hideValues: value, isGenerated: false);
  }

  Future<void> generateFile() async {
    if (state.sourceFilePath == null || state.entries.isEmpty) return;
    
    if (state.outputExists && !state.replaceFile) {
      return; // Can't generate if it exists and replace isn't toggled
    }

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
