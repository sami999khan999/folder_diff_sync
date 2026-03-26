// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers
import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  const int _bufferSize = 1024 * 1024; // 1MB

  final sourceFile = File('test_source.bin');
  final targetPath1 = 'test_target_std.bin';
  final targetPath2 = 'test_target_opt.bin';

  print('Creating 100MB test file...');
  final sink = sourceFile.openWrite();
  final chunk = Uint8List(1024 * 1024);
  for (int i = 0; i < 100; i++) {
    sink.add(chunk);
  }
  await sink.close();
  print('Test file created.');

  print('Running Standard File.copy...');
  final sw1 = Stopwatch()..start();
  await sourceFile.copy(targetPath1);
  sw1.stop();
  print('Standard File.copy took: ${sw1.elapsedMilliseconds}ms');

  print('Running Optimized chunked copy...');
  final sw2 = Stopwatch()..start();
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
  sw2.stop();
  print('Optimized copy took: ${sw2.elapsedMilliseconds}ms');

  // Cleanup
  if (await sourceFile.exists()) await sourceFile.delete();
  if (await File(targetPath1).exists()) await File(targetPath1).delete();
  if (await File(targetPath2).exists()) await File(targetPath2).delete();
  
  print('Benchmark complete.');
}
