import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';

/// Provider for the singleton StorageService instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  final storageService = StorageService();
  ref.onDispose(storageService.dispose);
  return storageService;
});

/// Upload status enumeration.
enum UploadStatus { initial, picking, ready, uploading, success, error }

/// Represents the state of an image upload session.
class ImageUploadState {
  final UploadStatus status;
  final XFile? pickedFile;
  final double progress; // 0.0 to 1.0
  final String? uploadedUrl;
  final String? errorMessage;

  const ImageUploadState({
    this.status = UploadStatus.initial,
    this.pickedFile,
    this.progress = 0.0,
    this.uploadedUrl,
    this.errorMessage,
  });

  bool get isUploading => status == UploadStatus.uploading;
  bool get hasFile => pickedFile != null;

  ImageUploadState copyWith({
    UploadStatus? status,
    XFile? pickedFile,
    double? progress,
    String? uploadedUrl,
    String? errorMessage,
    bool clearFile = false,
  }) {
    return ImageUploadState(
      status: status ?? this.status,
      pickedFile: clearFile ? null : (pickedFile ?? this.pickedFile),
      progress: progress ?? this.progress,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier to manage picking, previewing, progress tracking, and uploading.
class ImageUploadNotifier extends Notifier<ImageUploadState> {
  @override
  ImageUploadState build() => const ImageUploadState();

  StorageService get _service => ref.read(storageServiceProvider);

  /// Picks an image from either gallery or camera and updates state to ready.
  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    state = state.copyWith(status: UploadStatus.picking, errorMessage: null);
    try {
      final file = await _service.pickImage(source: source);
      if (file != null) {
        state = state.copyWith(
          status: UploadStatus.ready,
          pickedFile: file,
          progress: 0.0,
        );
      } else {
        state = state.copyWith(status: UploadStatus.initial);
      }
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Uploads the picked file for the given [itemId] with progress updates.
  Future<String?> upload(String itemId) async {
    final file = state.pickedFile;
    if (file == null) return null;

    state = state.copyWith(
      status: UploadStatus.uploading,
      progress: 0.0,
      errorMessage: null,
    );

    try {
      final url = await _service.uploadMenuImageWithProgress(
        itemId: itemId,
        file: file,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        status: UploadStatus.success,
        uploadedUrl: url,
        progress: 1.0,
      );
      return url;
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Clears the picked file and resets state.
  void reset() {
    state = const ImageUploadState();
  }
}

/// Auto-disposed provider for managing upload workflows within forms or dialogs.
final imageUploadNotifierProvider =
    NotifierProvider.autoDispose<ImageUploadNotifier, ImageUploadState>(
      ImageUploadNotifier.new,
    );
