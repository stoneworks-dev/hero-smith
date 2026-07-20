import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Absolute path of the directory where hero portrait images are copied.
///
/// Watched by the heroes list so it can resolve stored portrait file names to
/// on-disk files at build time. The application documents directory is stable
/// for the lifetime of an install, so this only needs to resolve once.
final portraitsDirProvider = FutureProvider<String>((ref) async {
  return HeroPortraitService.ensurePortraitsDir();
});

/// Handles picking, copying, resolving and deleting hero portrait images.
///
/// Portraits are copied into the app's documents directory (`hero_portraits/`)
/// so we never depend on the volatile path the OS picker hands back. Only the
/// file name is persisted (in `hero_values`); the absolute path is rebuilt from
/// [ensurePortraitsDir] at read time because the documents container path can
/// change between installs on iOS.
class HeroPortraitService {
  static const String _subDir = 'hero_portraits';

  /// Width / height of the portrait band. Shared by the card and the reposition
  /// dialog so the visible crop matches exactly in both places.
  static const double bandAspectRatio = 2.2;

  /// Longest-edge cap for stored portraits. Phone photos are many megapixels;
  /// decoding one at full size costs ~40MB+ and crashes low-memory devices, so
  /// we downscale to this before saving. Also keeps the card cheap to render.
  static const int _maxDimension = 1280;

  /// Ensure the portraits directory exists and return its absolute path.
  static Future<String> ensurePortraitsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Resolve a stored portrait [fileName] to an on-disk [File].
  static File resolve(String dirPath, String fileName) =>
      File(p.join(dirPath, fileName));

  /// Let the user pick an image, copy it into app storage and return the stored
  /// file name (or `null` if cancelled/failed).
  ///
  /// Any previous portrait files for [heroId] are removed so a hero never keeps
  /// more than one image on disk.
  Future<String?> pickAndStore(String heroId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.first;

    final dirPath = await ensurePortraitsDir();

    // Load the raw bytes (path on desktop/mobile, bytes as a fallback).
    Uint8List? rawBytes;
    try {
      if (picked.bytes != null) {
        rawBytes = picked.bytes;
      } else if (picked.path != null) {
        rawBytes = await File(picked.path!).readAsBytes();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to read picked image: $e');
    }
    if (rawBytes == null) return null;

    // Downscale to a sane size; the result is always PNG-encoded.
    final Uint8List data;
    try {
      data = await _downscaleToPng(rawBytes);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to process portrait: $e');
      return null;
    }

    final fileName = '${heroId}_${DateTime.now().millisecondsSinceEpoch}.png';
    final dest = File(p.join(dirPath, fileName));
    try {
      await dest.writeAsBytes(data, flush: true);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to store portrait: $e');
      return null;
    }

    // Drop any earlier portraits for this hero, keeping the one just written.
    await _deleteHeroFiles(heroId, keep: fileName, dirPath: dirPath);
    return fileName;
  }

  /// Decode [bytes] at a capped resolution (longest edge <= [_maxDimension])
  /// and re-encode as PNG. Reads the image's dimensions from its header first
  /// (no full-size decode) so oversized photos never fully materialize.
  Future<Uint8List> _downscaleToPng(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final srcW = descriptor.width;
    final srcH = descriptor.height;
    final longest = math.max(srcW, srcH);

    int? targetW;
    int? targetH;
    if (longest > _maxDimension) {
      final scale = _maxDimension / longest;
      targetW = math.max(1, (srcW * scale).round());
      targetH = math.max(1, (srcH * scale).round());
    }

    final codec = await descriptor.instantiateCodec(
      targetWidth: targetW,
      targetHeight: targetH,
    );
    final frame = await codec.getNextFrame();
    try {
      final pngData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) {
        throw StateError('PNG encoding returned null');
      }
      return pngData.buffer.asUint8List();
    } finally {
      frame.image.dispose();
      codec.dispose();
      descriptor.dispose();
    }
  }

  /// Delete every portrait file belonging to [heroId] (used on hero delete).
  Future<void> deleteForHero(String heroId) async {
    final dirPath = await ensurePortraitsDir();
    await _deleteHeroFiles(heroId, keep: null, dirPath: dirPath);
  }

  Future<void> _deleteHeroFiles(
    String heroId, {
    required String? keep,
    required String dirPath,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    // Hero ids are `H0001`-style, so an underscore-terminated prefix is an
    // unambiguous match (no id is a prefix of another once `_` is appended).
    final prefix = '${heroId}_';
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith(prefix)) continue;
      if (keep != null && name == keep) continue;
      try {
        await entity.delete();
      } catch (_) {
        // Best effort — a leftover file is harmless.
      }
    }
  }
}
