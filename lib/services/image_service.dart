import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/failure.dart';

/// A simple, cross-platform container for a picked image so the rest of the
/// app doesn't have to juggle File vs bytes (Web has no File paths).
class PickedImage {
  final Uint8List bytes; // The image data (used to upload for OCR).
  final String mediaType; // e.g. "image/jpeg" — needed by the AI vision call.
  final String? savedPath; // Local copy path (null on Web).

  PickedImage({required this.bytes, required this.mediaType, this.savedPath});
}

/// Wraps `image_picker` so screens can grab a photo from the **camera**,
/// **gallery/upload**, and downsize it before sending it to the cloud OCR.
///
/// Works on all platforms. On Web there is no filesystem, so we keep the bytes
/// in memory and skip saving a local copy.
class ImageService {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Wraps raw bytes captured by the live camera (see ScanScreen) into a
  /// [PickedImage], shrinking + saving a local copy just like a picked photo.
  Future<PickedImage> fromCameraBytes(Uint8List rawBytes,
      {String name = 'scan.jpg'}) async {
    final bytes = _maybeShrink(rawBytes);
    String? savedPath;
    if (!kIsWeb) {
      savedPath = await _saveLocally(bytes, name);
    }
    return PickedImage(
      bytes: bytes,
      mediaType: _mediaTypeFor(name),
      savedPath: savedPath,
    );
  }

  /// Take a photo with the device camera.
  Future<PickedImage?> takePhoto() => _pick(ImageSource.camera);

  /// Pick / upload an existing image from the gallery or file system.
  Future<PickedImage?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<PickedImage?> _pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        // Cap the size so uploads stay small and fast, even on old phones.
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return null; // User cancelled.

      final rawBytes = await file.readAsBytes();
      final mediaType = _mediaTypeFor(file.name);

      // Optionally re-compress large images to keep the OCR upload light.
      final bytes = _maybeShrink(rawBytes);

      // Save a local copy for history thumbnails (not possible on Web).
      String? savedPath;
      if (!kIsWeb) {
        savedPath = await _saveLocally(bytes, file.name);
      }

      return PickedImage(bytes: bytes, mediaType: mediaType, savedPath: savedPath);
    } catch (e) {
      throw Failure.camera(e);
    }
  }

  /// Re-encodes very large images to JPEG to shrink the upload. If decoding
  /// fails for any reason we just return the original bytes unchanged.
  Uint8List _maybeShrink(Uint8List input) {
    try {
      if (input.lengthInBytes < 600 * 1024) return input; // Already small.
      final decoded = img.decodeImage(input);
      if (decoded == null) return input;
      final resized = decoded.width > 1600
          ? img.copyResize(decoded, width: 1600)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (_) {
      return input;
    }
  }

  Future<String> _saveLocally(Uint8List bytes, String originalName) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'scans'));
    if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
    final ext = p.extension(originalName).isNotEmpty
        ? p.extension(originalName)
        : '.jpg';
    final file = File(p.join(imagesDir.path, '${_uuid.v4()}$ext'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _mediaTypeFor(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
