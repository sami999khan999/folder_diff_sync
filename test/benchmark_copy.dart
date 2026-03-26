// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers, depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';

void main() {
  const int _bufferSize = 1024 * 1024; // 1MB

  group('File Copy Benchmark', () {
    late File sourceFile;
    late String targetPath1;
    late String targetPath2;

    setUpAll(() async {
      sourceFile = File('test_source.bin');
      targetPath1 = 'test_target_std.bin';
      targetPath2 = 'test_target_opt.bin';

      print('Creating 100MB test file...');
      final sink = sourceFile.openWrite();
      final chunk = Uint8List(1024 * 1024);
      for (int i = 0; i < 100; i++) {
        sink.add(chunk);
      }
      await sink.close();
      print('Test file created.');
    });

    tearDownAll(() async {
      if (await sourceFile.exists()) await sourceFile.delete();
      if (await File(targetPath1).exists()) await File(targetPath1).delete();
      if (await File(targetPath2).exists()) await File(targetPath2).delete();
    });

    test('Standard File.copy performance', () async {
      final stopwatch = Stopwatch()..start();
      await sourceFile.copy(targetPath1);
      stopwatch.stop();
      print('Standard File.copy took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Optimized chunked copy performance', () async {
      final stopwatch = Stopwatch()..start();
      
      final source = await sourceFile.open(mode: FileMode.read);
      final target = await File(targetPath2).open(mode: FileMode.write);
      
      try {
        final buffer = Uint8List(_bufferSize);
        int bytesRead;
        while ((bytesRead = await source.readInto(buffer)) > 0) {
          await target.writeFrom(buffer, 0, bytesRead);
        }
      } finally {
        await source.close();
        await target.close();
      }
      
      stopwatch.stop();
      print('Optimized copy took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
