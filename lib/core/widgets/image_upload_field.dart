import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/brand_colors.dart';
import '../../providers/storage_provider.dart';
import 'primary_button.dart';

/// Reusable widget for picking, previewing, and uploading menu item images.
class ImageUploadField extends ConsumerStatefulWidget {
  /// The existing image URL stored in Firestore (if editing).
  final String? currentImageUrl;

  /// The unique item ID used as the Firebase Storage directory key.
  final String itemId;

  /// Callback invoked when an image is successfully uploaded to Firebase Storage.
  final void Function(String url) onUploaded;

  /// Optional callback invoked when the user clears or removes the image.
  final void Function()? onRemoved;

  /// Total height for the image preview box.
  final double height;

  const ImageUploadField({
    super.key,
    required this.itemId,
    required this.onUploaded,
    this.currentImageUrl,
    this.onRemoved,
    this.height = 200,
  });

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  XFile? _pickedFile;
  Uint8List? _pickedImageBytes;
  String? _displayUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(covariant ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl &&
        _pickedFile == null) {
      _displayUrl = widget.currentImageUrl;
    }
  }

  Future<void> _showSourceSelectionSheet() async {
    // On desktop, directly open gallery because camera is not supported
    if (!kIsWeb &&
        const {
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      await _pickImage(ImageSource.gallery);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: BrandColors.primaryOrange,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Pick an existing photo from device library',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: BrandColors.primaryOrange,
                  ),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Capture new photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final file = await storageService.pickImage(source: source);
      if (file != null) {
        final imageBytes = await file.readAsBytes();
        setState(() {
          _pickedFile = file;
          _pickedImageBytes = imageBytes;
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: BrandColors.error,
        ),
      );
    }
  }

  Future<void> _uploadPickedImage() async {
    final pickedFile = _pickedFile;
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadMenuImageWithProgress(
        itemId: widget.itemId,
        file: pickedFile,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _displayUrl = downloadUrl;
        _pickedFile = null;
        _pickedImageBytes = null;
      });

      widget.onUploaded(downloadUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: BrandColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: BrandColors.error,
        ),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _pickedFile = null;
      _pickedImageBytes = null;
      _displayUrl = null;
    });

    widget.onRemoved?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: BrandColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPickedFile = _pickedFile != null;
    final hasRemoteUrl = _displayUrl != null && _displayUrl!.isNotEmpty;
    final hasAnyImage = hasPickedFile || hasRemoteUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Container / Preview Card
        Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: BrandColors.creamBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasAnyImage
                  ? BrandColors.primaryOrange.withValues(alpha: 0.3)
                  : BrandColors.border,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPickedFile && _pickedImageBytes != null)
                  Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                else if (hasRemoteUrl)
                  Image.network(
                    _displayUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: BrandColors.primaryOrange,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              color: BrandColors.textMuted,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: BrandColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  // Empty State Placeholder
                  InkWell(
                    onTap: _isUploading ? null : _showSourceSelectionSheet,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: BrandColors.primaryOrangeLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: BrandColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upload Dish Photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PNG, JPG up to 10MB (max 1200px)',
                          style: TextStyle(
                            fontSize: 12,
                            color: BrandColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Uploading Overlay with Progress Indicator
                if (_isUploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: CircularProgressIndicator(
                                value: _uploadProgress > 0
                                    ? _uploadProgress
                                    : null,
                                strokeWidth: 4,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _uploadProgress > 0
                                  ? 'Uploading... ${(_uploadProgress * 100).toInt()}%'
                                  : 'Preparing upload...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  BrandColors.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Quick Action Buttons on Image Overlay
                if (hasAnyImage && !_isUploading)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Change photo button
                        Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                            tooltip: 'Change Photo',
                            onPressed: _showSourceSelectionSheet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Remove photo button
                        Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.white,
                            ),
                            tooltip: 'Remove Photo',
                            onPressed: _removeImage,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action Buttons Row below image (when a new file is picked)
        if (hasPickedFile && !_isUploading) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Upload Photo to Storage',
                  icon: Icons.cloud_upload_outlined,
                  onPressed: _uploadPickedImage,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.textSecondary,
                  side: const BorderSide(color: BrandColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _pickedFile = null;
                    _pickedImageBytes = null;
                  });
                },
              ),
            ],
          ),
        ],

        if (!hasAnyImage) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(
                Icons.image,
                size: 16,
                color: BrandColors.primaryOrange,
              ),
              label: const Text(
                'Browse files',
                style: TextStyle(
                  color: BrandColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: _showSourceSelectionSheet,
            ),
          ),
        ],
      ],
    );
  }
}
