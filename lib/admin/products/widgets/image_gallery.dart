import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/local_image_preview.dart';

class ImageGallery extends StatelessWidget {
  final List<String> networkImages;
  final List<XFile> localImages;
  final Function(int index, bool isNetwork) onRemove;
  final Function(int oldIndex, int newIndex) onReorderNetwork;

  const ImageGallery({
    super.key,
    required this.networkImages,
    required this.localImages,
    required this.onRemove,
    required this.onReorderNetwork,
  });

  /// [ReorderableListView] reports indices over the combined list
  /// (network images first, then local/not-yet-uploaded images), but
  /// [onReorderNetwork] only knows how to reorder [networkImages].
  /// Dragging a local image, or dropping past the end of the network
  /// section, previously passed an out-of-range index straight through
  /// and crashed with a [RangeError]. Only forward genuinely
  /// network-to-network moves, and clamp the drop target to the end of
  /// the network section otherwise.
  void _handleReorder(int oldIndex, int newIndex) {
    final networkCount = networkImages.length;
    if (oldIndex >= networkCount) {
      // Dragged a local image — reordering local images isn't supported.
      return;
    }
    final clampedNewIndex = newIndex > networkCount ? networkCount : newIndex;
    onReorderNetwork(oldIndex, clampedNewIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (networkImages.isEmpty && localImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery Images',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            onReorder: (oldIndex, newIndex) =>
                _handleReorder(oldIndex, newIndex),
            children: [
              ...networkImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Container(
                  key: ValueKey('net_$url'),
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                     children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(idx, true),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              ...localImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Container(
                  key: ValueKey('loc_${file.path}'),
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LocalImagePreview(
                          file: file,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(idx, false),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}