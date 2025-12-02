import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Reusable image compression service for resizing before uploads.
/// Targets ~1080px min width with reasonable quality while keeping size down.
class ImageCompressService {
  const ImageCompressService();

  /// Compress from File and return bytes (Uint8List). Returns original bytes on failure.
  Future<Uint8List> compressFileToBytes(
    File file, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75,
    CompressFormat format = CompressFormat.jpeg,
    int rotate = 0,
  }) async {
    try {
      // Try flutter_image_compress first
      final bytes = await file.readAsBytes();
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        rotate: rotate,
        format: format,
      );
      return Uint8List.fromList(result);
    } catch (e) {
      try {
        // Fallback to native compression
        return await _compressBytesFallback(
          await file.readAsBytes(),
          minWidth: minWidth,
          minHeight: minHeight,
          quality: quality,
        );
      } catch (e2) {
        return file.readAsBytes();
      }
    }
  }

  /// Compress from XFile and return bytes.
  Future<Uint8List> compressXFileToBytes(
    XFile xfile, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75,
    CompressFormat format = CompressFormat.jpeg,
    int rotate = 0,
  }) async {
    try {
      final bytes = await xfile.readAsBytes();
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        rotate: rotate,
        format: format,
      );
      return Uint8List.fromList(result);
    } catch (e) {
      return xfile.readAsBytes();
    }
  }

  /// Compress from File and return a temporary File. Caller should manage lifecycle.
  Future<File> compressFileToTempFile(
    File file, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75,
    CompressFormat format = CompressFormat.jpeg,
    int rotate = 0,
    String? outPath,
  }) async {
    try {
      
      // Try flutter_image_compress first
      try {
        final result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: minWidth,
          minHeight: minHeight,
          quality: quality,
          rotate: rotate,
          format: format,
        );
        
        if (result != null) {
          final tmp = outPath != null ? File(outPath) : await _tempSibling(file);
          await tmp.writeAsBytes(result, flush: true);
          return tmp;
        }
      } catch (e) {
        // Ignore flutter_image_compress errors, will try fallback
      }
      
      // Fallback to native compression
      try {
        final originalBytes = await file.readAsBytes();
        final compressedBytes = await _compressBytesFallback(
          originalBytes,
          minWidth: minWidth,
          minHeight: minHeight,
          quality: quality,
        );

        final tmp = outPath != null
            ? File(outPath)
            : await _tempSibling(file);
        await tmp.writeAsBytes(compressedBytes, flush: true);
        return tmp;
      } catch (e2) {
        // Ignore fallback compression errors, will return original
      }
      
      // If all fails, return original file
      return file;
      
    } catch (e) {
      return file;
    }
  }
  
  /// Fallback compression using Flutter's native image decoding/encoding
  Future<Uint8List> _compressBytesFallback(
    Uint8List bytes, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75,
  }) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Could not decode image');
      }

      // Calculate target size preserving aspect ratio
      var targetW = decoded.width;
      var targetH = decoded.height;
      if (decoded.width >= decoded.height) {
        if (decoded.width > minWidth) {
          targetW = minWidth;
          targetH = (decoded.height * (minWidth / decoded.width)).round();
        }
      } else {
        if (decoded.height > minHeight) {
          targetH = minHeight;
          targetW = (decoded.width * (minHeight / decoded.height)).round();
        }
      }

      final resized = (targetW != decoded.width || targetH != decoded.height)
          ? img.copyResize(decoded, width: targetW, height: targetH, interpolation: img.Interpolation.linear)
          : decoded;

      // Encode as JPEG to match storage metadata
      final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      return out;
    } catch (e) {
      return bytes;
    }
  }

  /// Utility: create a temp file next to original (or in system temp if no permission).
  Future<File> _tempSibling(File original, {String suffix = '_compressed', String forcedExt = '.jpg'}) async {
    try {
      final dir = original.parent;
      final name = original.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      final base = dot > 0 ? name.substring(0, dot) : name;
      final path = '${dir.path}/$base$suffix$forcedExt';
      return File(path);
    } catch (_) {
      final tmpDir = Directory.systemTemp;
      return File('${tmpDir.path}/${DateTime.now().microsecondsSinceEpoch}$suffix.jpg');
    }
  }
}