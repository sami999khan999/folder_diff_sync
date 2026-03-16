import 'dart:io';
import '../models/env_sync_item.dart';

class EnvSyncService {
  static Future<List<EnvEntry>> parseEnvFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    return parseEnvContent(content);
  }

  static List<EnvEntry> parseEnvContent(String content) {
    if (content.isEmpty) return [];
    
    // Split by lines, being careful to preserve empty lines
    final lines = content.split(RegExp(r'\r?\n'));
    final entries = <EnvEntry>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        entries.add(EnvEntry(rawLine: line, isBlank: true));
      } else if (trimmed.startsWith('#')) {
        entries.add(EnvEntry(rawLine: line, isComment: true));
      } else {
        final eqIndex = trimmed.indexOf('=');
        if (eqIndex > 0) {
          final key = trimmed.substring(0, eqIndex).trim();
          final value = trimmed.substring(eqIndex + 1).trim();
          entries.add(EnvEntry(rawLine: line, key: key, value: value));
        } else {
          // Line without '=' — treat as a key with empty value
          entries.add(EnvEntry(rawLine: line, key: trimmed, value: ''));
        }
      }
    }

    return entries;
  }

  static Future<String> generateEnvFile({
    required List<EnvEntry> entries,
    required String outputPath,
    required bool hideValues,
  }) async {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln(entry.toOutputLine(hideValues: hideValues));
    }

    final file = File(outputPath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    await file.writeAsString(buffer.toString());

    return outputPath;
  }
}
