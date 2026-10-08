import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Picks menu images and uploads them to Cloudinary using an unsigned preset.
class StorageService {
  static const _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'uekye2ta',
  );
  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'dine flow',
  );

  final ImagePicker _picker;
  final http.Client _client;
  final String cloudName;
  final String uploadPreset;

  StorageService({
    ImagePicker? picker,
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
  }) : _picker = picker ?? ImagePicker(),
       _client = client ?? http.Client(),
       cloudName = cloudName ?? _cloudName,
       uploadPreset = uploadPreset ?? _uploadPreset;

  void dispose() => _client.close();

  /// Picks an image from the user's gallery or camera.
  ///
  /// Applies image compression, and falls back to gallery on desktop.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      var effectiveSource = source;
      if (!kIsWeb &&
          const {
            TargetPlatform.windows,
            TargetPlatform.linux,
            TargetPlatform.macOS,
          }.contains(defaultTargetPlatform) &&
          source == ImageSource.camera) {
        debugPrint(
          'Camera not available on desktop. Falling back to gallery picker.',
        );
        effectiveSource = ImageSource.gallery;
      }

      return await _picker.pickImage(
        source: effectiveSource,
        imageQuality: 75,
        maxWidth: 1200,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<XFile?> pickFromCamera() => pickImage(source: ImageSource.camera);

  /// Uploads to `menu/{itemId}/{timestamp}.jpg` and returns `secure_url`.
  Future<String> uploadMenuImage({
    required String itemId,
    required XFile file,
  }) {
    return uploadMenuImageWithProgress(itemId: itemId, file: file);
  }

  /// Uploads using Cloudinary's unsigned upload API, which works on web and
  /// native platforms without exposing an API secret in the client.
  Future<String> uploadMenuImageWithProgress({
    required String itemId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is not configured. Provide CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET using --dart-define.',
      );
    }

    final safeItemId = itemId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (safeItemId.isEmpty) {
      throw ArgumentError.value(itemId, 'itemId', 'Must not be empty');
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final publicId = '$timestamp';
    final folder = 'menu/$safeItemId';
    final uploadUrl = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );

    try {
      debugPrint('Cloudinary upload starting: $folder/$publicId.jpg');
      onProgress?.call(0);

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..fields['public_id'] = publicId
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: '$publicId.jpg',
          ),
        );

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        throw const FormatException(
          'Cloudinary returned an invalid upload response.',
        );
      }
      final responseBody = decodedBody;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final cloudinaryError = responseBody['error'];
        final error = cloudinaryError is Map
            ? cloudinaryError['message']
            : null;
        throw Exception(
          'Cloudinary upload failed (${response.statusCode}): '
          '${error ?? response.body}',
        );
      }

      final secureUrl = responseBody['secure_url'];
      if (secureUrl is! String || secureUrl.isEmpty) {
        throw const FormatException(
          'Cloudinary upload response did not include secure_url.',
        );
      }

      debugPrint('Cloudinary upload complete: $folder/$publicId.jpg');
      onProgress?.call(1);
      return secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload failed: $e');
      rethrow;
    }
  }

  /// Client-side unsigned uploads cannot delete Cloudinary assets. Deletion
  /// requires a signed server-side endpoint; keep this method as a safe
  /// compatibility hook for existing callers.
  Future<void> deleteImageByUrl(String imageUrl) async {
    await deleteImageSafely(imageUrl);
  }

  Future<bool> deleteImageSafely(String imageUrl) async {
    if (imageUrl.trim().isEmpty) return false;
    debugPrint(
      'Cloudinary asset not deleted from the client; configure a signed '
      'server endpoint if deletion is required.',
    );
    return false;
  }
}
