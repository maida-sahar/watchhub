import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/local_image_preview.dart';

class ProductImagesPicker extends StatelessWidget {
  final XFile? thumbnailFile;
  final String? networkThumbnailUrl;
  final VoidCallback onPickThumbnail;
  final VoidCallback onPickGallery;

  const ProductImagesPicker({
    super.key,
    this.thumbnailFile,
    this.networkThumbnailUrl,
    required this.onPickThumbnail,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Thumbnail *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPickThumbnail,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: thumbnailFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LocalImagePreview(file: thumbnailFile!, fit: BoxFit.cover),
                  )
                : networkThumbnailUrl != null && networkThumbnailUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: networkThumbnailUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to select main thumbnail image', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onPickGallery,
          icon: const Icon(Icons.collections),
          label: const Text('Add Gallery Images'),
        ),
      ],
    );
  }
}