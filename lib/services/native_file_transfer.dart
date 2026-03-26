import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef NativeCopyFile = Int32 Function(
  Pointer<Utf8> src,
  Pointer<Utf8> dst,
  Pointer<NativeFunction<Void Function(Int64)>> callback,
);

typedef DartCopyFile = int Function(
  Pointer<Utf8> src,
  Pointer<Utf8> dst,
  Pointer<NativeFunction<Void Function(Int64)>> callback,
);

base class CopyItem extends Struct {
  external Pointer<Utf8> src;
  external Pointer<Utf8> dst;
}

typedef NativeCopyBatch = Int32 Function(
  Pointer<CopyItem> items,
  IntPtr count,
  IntPtr concurrency,
  Pointer<NativeFunction<Void Function(Int64)>> callback,
);

typedef DartCopyBatch = int Function(
  Pointer<CopyItem> items,
  int count,
  int concurrency,
  Pointer<NativeFunction<Void Function(Int64)>> callback,
);

class NativeFileTransfer {
  static DynamicLibrary? _lib;
  static bool _attemptedLoad = false;

  static DynamicLibrary? get lib {
    if (_lib != null) return _lib;
    if (_attemptedLoad) return null;

    _attemptedLoad = true;
    try {
      if (Platform.isWindows) {
        // In dev, it might be in the build output or the rust target folder
        _lib = DynamicLibrary.open('file_transfer_rs.dll');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libfile_transfer_rs.so');
      }
    } catch (e) {
      // Fallback: try different paths if needed, or just let it fail to Dart sync
      // ignore: avoid_print
      print('Native transfer failed, falling back to Dart: $e');
    }
    return _lib;
  }

  static bool get isAvailable => lib != null;

  static Future<int> copyFile(
    String src,
    String dst, {
    void Function(int bytes)? onProgress,
  }) async {
    final nativeLib = lib;
    if (nativeLib == null) return -100; // Native not available

    final copyFunc = nativeLib.lookupFunction<NativeCopyFile, DartCopyFile>('copy_file_native');

    final srcPtr = src.toNativeUtf8();
    final dstPtr = dst.toNativeUtf8();

    Pointer<NativeFunction<Void Function(Int64)>>? callbackPtr;
    NativeCallable<Void Function(Int64)>? nativeCallable;

    if (onProgress != null) {
      nativeCallable = NativeCallable<Void Function(Int64)>.isolateLocal((int bytes) {
        onProgress(bytes);
      });
      callbackPtr = nativeCallable.nativeFunction;
    }

    try {
      final result = copyFunc(srcPtr, dstPtr, callbackPtr ?? nullptr);
      return result;
    } finally {
      malloc.free(srcPtr);
      malloc.free(dstPtr);
      nativeCallable?.close();
    }
  }

  static Future<int> copyBatch(
    List<Map<String, String>> items, {
    int concurrency = 4,
    void Function(int count)? onProgress,
  }) async {
    final nativeLib = lib;
    if (nativeLib == null) return -100;

    final copyBatchFunc = nativeLib.lookupFunction<NativeCopyBatch, DartCopyBatch>('copy_batch_native');

    final itemsPtr = malloc<CopyItem>(items.length);
    final pointersToFree = <Pointer<Utf8>>[];

    for (var i = 0; i < items.length; i++) {
      final srcPtr = items[i]['src']!.toNativeUtf8();
      final dstPtr = items[i]['dst']!.toNativeUtf8();
      itemsPtr[i].src = srcPtr;
      itemsPtr[i].dst = dstPtr;
      pointersToFree.add(srcPtr);
      pointersToFree.add(dstPtr);
    }

    Pointer<NativeFunction<Void Function(Int64)>>? callbackPtr;
    NativeCallable<Void Function(Int64)>? nativeCallable;

    if (onProgress != null) {
      nativeCallable = NativeCallable<Void Function(Int64)>.isolateLocal((int count) {
        onProgress(count);
      });
      callbackPtr = nativeCallable.nativeFunction;
    }

    try {
      final result = copyBatchFunc(itemsPtr, items.length, concurrency, callbackPtr ?? nullptr);
      return result;
    } finally {
      for (final ptr in pointersToFree) {
        malloc.free(ptr);
      }
      malloc.free(itemsPtr);
      nativeCallable?.close();
    }
  }
}
