import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception wrapper for [StorageService] failures.
///
/// Every calling service (Category/Brand/Product/etc.) already has its
/// own `*ServiceException` type that it maps lower-level failures into,
/// so this type stays intentionally simple — callers catch it, read
/// [message], and re-wrap it into their own domain exception.
class StorageServiceException implements Exception {
  final String message;
  final Object? cause;

  const StorageServiceException(this.message, [this.cause]);

  @override
  String toString() => 'StorageServiceException: $message';
}

/// StorageService
///
/// The single owner of every Supabase Storage operation in this app.
/// Every module that needs to upload, replace, or delete an image
/// (Category, Brand, Product, and any future module) goes through this
/// service instead of talking to Supabase Storage directly — this is
/// the only file in the project that imports `supabase_flutter`.
///
/// Firestore remains the source of truth for all *data* (documents,
/// fields, the image URL string itself); this service only ever
/// uploads/deletes the underlying image bytes and returns/consumes
/// public URLs. It never touches Firestore.
///
/// All images across the app live in a single Supabase Storage bucket,
/// [bucketName] ('productimages'), organized into folders by path
/// (e.g. `categories/{id}/image`, `products/{id}/thumbnail.jpg`) —
/// callers choose the path, this service only handles the upload/
/// delete/URL mechanics.
class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// The single Supabase Storage bucket used by the entire app.
  static const String bucketName = 'productimages';

  StorageFileApi get _bucket => _client.storage.from(bucketName);

  // =========================================================
  // VALIDATION & UTILS
  // =========================================================

  /// Validates the [file] to ensure it exists, is non-empty, does not
  /// exceed size limits, has a supported extension, and has valid magic
  /// signature bytes (detecting corruption).
  ///
  /// Supported formats: JPG, JPEG, PNG, WEBP.
  Future<void> validateImage(XFile file) async {
    final int size = await file.length();
    if (size == 0) {
      throw const StorageServiceException('Image file is empty.');
    }

    // Limit to 10 MB (10 * 1024 * 1024 bytes)
    const int maxSizeBytes = 10 * 1024 * 1024;
    if (size > maxSizeBytes) {
      final double sizeMb = size / (1024 * 1024);
      throw StorageServiceException(
        'Image file is too large (${sizeMb.toStringAsFixed(1)} MB). Maximum allowed size is 10 MB.',
      );
    }

    final path = file.path.toLowerCase();
    final name = file.name.toLowerCase();
    final hasValidExt = name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        path.startsWith('blob:');

    if (!hasValidExt) {
      throw const StorageServiceException(
        'Invalid image format. Supported formats are JPG, JPEG, PNG, and WEBP.',
      );
    }

    // Read first few bytes to check file headers (magic bytes signature)
    final bytes = await file.readAsBytes();
    if (bytes.length < 4) {
      throw const StorageServiceException('Corrupted or invalid image file structure.');
    }

    // PNG: 89 50 4E 47
    final isPng = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
    // JPEG/JPG: FF D8
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    // WEBP: RIFF ... WEBP (starts with 52 49 46 46 (RIFF) and has 57 45 42 50 (WEBP) at offset 8)
    bool isWebp = false;
    if (bytes.length >= 12) {
      final isRiff = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
      final isWebpHeader = bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;
      isWebp = isRiff && isWebpHeader;
    }

    if (!isPng && !isJpeg && !isWebp) {
      throw const StorageServiceException(
        'The file content does not match a valid image (JPEG, PNG, or WEBP). It may be corrupted.',
      );
    }
  }

  /// Generates a unique filename for the given [file].
  ///
  /// Combines current milliseconds since epoch with a high-resolution microsecond
  /// entropy component to guarantee uniqueness.
  String generateUniqueFileName(XFile file) {
    final originalName = file.name.isNotEmpty ? file.name : 'image.jpg';
    String ext = originalName.contains('.') ? originalName.split('.').last.toLowerCase() : '';
    if (ext.isEmpty || ext == 'blob' || !['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      final mime = file.mimeType?.toLowerCase() ?? '';
      if (mime.contains('png')) {
        ext = 'png';
      } else if (mime.contains('webp')) {
        ext = 'webp';
      } else {
        ext = 'jpg';
      }
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (DateTime.now().microsecond % 9000));
    return 'img_${timestamp}_$random.$ext';
  }

  // =========================================================
  // UPLOAD
  // =========================================================

  /// Uploads [file] to [path] within [bucketName] and returns its
  /// public URL.
  ///
  /// Performs validation before starting the upload.
  Future<String> uploadImage({
    required XFile file,
    required String path,
    bool upsert = true,
  }) async {
    await validateImage(file);
    try {
      final bytes = await file.readAsBytes();
      final String contentType;
      final name = file.name.toLowerCase();
      final mime = file.mimeType?.toLowerCase() ?? '';
      if (name.endsWith('.png') || mime.contains('png')) {
        contentType = 'image/png';
      } else if (name.endsWith('.webp') || mime.contains('webp')) {
        contentType = 'image/webp';
      } else {
        contentType = 'image/jpeg';
      }

      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: upsert,
          contentType: contentType,
        ),
      );
      return getPublicUrl(path);
    } on StorageException catch (e) {
      final detail = e.message.isNotEmpty ? e.message : e.toString();
      throw StorageServiceException(
        'Failed to upload image to "$path": $detail',
        e,
      );
    } catch (e) {
      final detail = e.toString().replaceFirst('Exception: ', '');
      throw StorageServiceException(
        'Failed to upload image to "$path": $detail',
        e,
      );
    }
  }

  /// Uploads every file in [files] to its corresponding path in [paths]
  /// (matched by index — both lists must be the same length) in
  /// parallel, and returns their public URLs in that same order.
  Future<List<String>> uploadMultipleImages({
    required List<XFile> files,
    required List<String> paths,
    bool upsert = true,
  }) async {
    if (files.length != paths.length) {
      throw const StorageServiceException(
        'files and paths must have the same length.',
      );
    }
    if (files.isEmpty) {
      throw const StorageServiceException(
        'files cannot be empty — at least one image is required.',
      );
    }
    for (final file in files) {
      await validateImage(file);
    }

    try {
      final uploads = List.generate(
        files.length,
        (i) => uploadImage(file: files[i], path: paths[i], upsert: upsert),
      );
      return await Future.wait(uploads);
    } on StorageServiceException {
      rethrow;
    } catch (e) {
      throw StorageServiceException('Failed to upload one or more images.', e);
    }
  }

  /// Replaces an existing image with [newFile] at [path], returning the
  /// new public URL.
  ///
  /// If [oldPublicUrl] is provided and points to an existing file in the bucket,
  /// the old file is deleted after the new upload succeeds.
  Future<String> replaceImage({
    required XFile newFile,
    required String path,
    String? oldPublicUrl,
    bool upsert = true,
  }) async {
    final newUrl = await uploadImage(file: newFile, path: path, upsert: upsert);

    if (oldPublicUrl != null && oldPublicUrl.isNotEmpty) {
      final oldPath = _extractPathFromPublicUrl(oldPublicUrl);
      if (oldPath != null && oldPath != path) {
        await deleteImage(oldPublicUrl);
      }
    }

    return newUrl;
  }

  // =========================================================
  // DELETE
  // =========================================================

  /// Deletes a single image, best-effort — never throws.
  Future<void> deleteImage(String publicUrlOrPath) async {
    if (publicUrlOrPath.isEmpty) return;
    final path = _extractPathFromPublicUrl(publicUrlOrPath) ?? publicUrlOrPath;
    try {
      await _bucket.remove([path]);
    } catch (_) {
      // Ignore cleanup failures
    }
  }

  /// Deletes every image in [publicUrlsOrPaths] in parallel,
  /// best-effort — never throws.
  Future<void> deleteMultipleImages(List<String> publicUrlsOrPaths) async {
    final paths = publicUrlsOrPaths
        .where((s) => s.isNotEmpty)
        .map((s) => _extractPathFromPublicUrl(s) ?? s)
        .toList();
    if (paths.isEmpty) return;

    try {
      await _bucket.remove(paths);
    } catch (_) {
      await Future.wait(paths.map((p) => _bucket.remove([p]).catchError((_) => <FileObject>[])));
    }
  }

  /// Lists every file directly under [folderPath] and deletes them all,
  /// best-effort — never throws.
  Future<void> deleteFolder(String folderPath) async {
    try {
      final items = await _bucket.list(path: folderPath);
      if (items.isEmpty) return;
      final paths = items.map((item) => '$folderPath/${item.name}').toList();
      await _bucket.remove(paths);
    } catch (_) {
      // Ignore cleanup failures
    }
  }

  // =========================================================
  // PUBLIC URL
  // =========================================================

  /// Returns the public URL for [path] within [bucketName].
  String getPublicUrl(String path) {
    return _bucket.getPublicUrl(path);
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Extracts the bucket-relative path from a Supabase public URL.
  String? _extractPathFromPublicUrl(String url) {
    final marker = '/object/public/$bucketName/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    return url.substring(index + marker.length);
  }
}