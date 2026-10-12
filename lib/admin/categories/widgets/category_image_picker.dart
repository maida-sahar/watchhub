import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/local_image_preview.dart';

/// A reusable Material 3 image-picker tile used for a category's
/// image, icon, and banner slots.
///
/// This widget is purely about *selecting* a file — it never touches
/// Firebase Storage itself. The chosen [XFile] is reported back via
/// [onImageSelected]; the parent screen holds onto it and passes it to
/// `CategoryProvider.createCategory()` / `updateCategory()` on submit,
/// where the actual upload happens.
class CategoryImagePicker extends StatelessWidget {
  const CategoryImagePicker({
    super.key,
    required this.label,
    required this.onImageSelected,
    this.selectedFile,
    this.existingImageUrl,
    this.isRequired = true,
    this.isUploading = false,
    this.uploadProgress,
    this.aspectRatioLabel,
    this.allowCamera = true,
  });

  /// Field label, e.g. "Category Image", "Category Icon", "Category Banner".
  final String label;

  /// Called with the newly picked file when the admin selects an image.
  final ValueChanged<XFile> onImageSelected;

  /// The currently selected local file, if any (takes priority over
  /// [existingImageUrl] for preview purposes).
  final XFile? selectedFile;

  /// The category's existing remote image URL, shown when editing a
  /// category and no new file has been picked yet.
  final String? existingImageUrl;

  /// Whether this image is required (shown as a hint, actual required
  /// validation is enforced by the parent form).
  final bool isRequired;

  /// Whether an upload for this slot is currently in progress.
  final bool isUploading;

  /// Optional 0.0–1.0 upload progress. When null but [isUploading] is
  /// true, an indeterminate progress indicator is shown instead.
  final double? uploadProgress;

  /// Optional short hint about the expected image shape, e.g. "1:1".
  final String? aspectRatioLabel;

  /// Whether to offer a "Camera" option alongside "Gallery".
  final bool allowCamera;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        onImageSelected(pickedFile);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source.name}: $e')),
        );
      }
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              if (allowCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(context, ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedFile != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (aspectRatioLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                aspectRatioLabel!,
                style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploading ? null : () => _showSourceSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasSelection)
                  _buildPreview(theme)
                else
                  _buildPlaceholder(theme),
                if (isUploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: uploadProgress,
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            uploadProgress != null
                                ? 'Uploading ${(uploadProgress! * 100).toStringAsFixed(0)}%'
                                : 'Uploading...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (selectedFile != null) {
      return LocalImagePreview(file: selectedFile!, fit: BoxFit.cover);
    }
    return Image.network(
      existingImageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
        theme,
        isError: true,
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, {bool isError = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.broken_image_outlined : Icons.add_photo_alternate_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            isError ? 'Could not load image' : 'Tap to select',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}