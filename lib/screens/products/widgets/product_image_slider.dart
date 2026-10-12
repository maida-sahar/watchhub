import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'image_viewer.dart';

class ProductImageSlider extends StatefulWidget {
  final String thumbnail;
  final List<String> galleryImages;

  const ProductImageSlider({
    super.key,
    required this.thumbnail,
    required this.galleryImages,
  });

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _allImages = [
      if (widget.thumbnail.isNotEmpty) widget.thumbnail,
      ...widget.galleryImages.where((img) => img != widget.thumbnail),
    ];
    if (_allImages.isEmpty) {
      _allImages = [''];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openImageViewer(int index) {
    if (_allImages.isEmpty || _allImages[0].isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          imageUrls: _allImages,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Image Slider Container
        Stack(
          children: [
            Container(
              height: 340,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _allImages.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final url = _allImages[index];
                    return GestureDetector(
                      onTap: () => _openImageViewer(index),
                      child: Hero(
                        tag: index == 0 ? 'product-image-${_allImages[0]}' : 'product-slide-$index',
                        child: url.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.watch,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(Icons.watch, size: 80, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Page Indicator Badge
            if (_allImages.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_allImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Thumbnail Strip
        if (_allImages.length > 1)
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _allImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _allImages[index],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.error_outline, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}