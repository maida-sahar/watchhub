import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/local_image_preview.dart';

class BrandBannerPicker extends StatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<XFile?> onImageSelected;

  const BrandBannerPicker({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
  });

  @override
  State<BrandBannerPicker> createState() => _BrandBannerPickerState();
}

class _BrandBannerPickerState extends State<BrandBannerPicker> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBanner(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
        widget.onImageSelected(_imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking banner image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickBanner(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickBanner(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brand Banner (Optional)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showImageSourceDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _imageFile != null
                  ? LocalImagePreview(file: _imageFile!, fit: BoxFit.cover, width: double.infinity)
                  : (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: widget.initialImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: theme.colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to select banner image', style: theme.textTheme.bodyMedium),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}