import 'package:flutter/material.dart';
import 'price_range_slider.dart';
import 'category_filter.dart';
import 'brand_filter.dart';
import 'rating_filter.dart';
import 'availability_filter.dart';
import 'color_filter.dart';
import 'featured_filter.dart';
import 'best_seller_filter.dart';
import 'new_arrival_filter.dart';

class FilterStateData {
  RangeValues priceRange;
  String? category;
  List<String> selectedBrands;
  double? minRating;
  String? availability;
  String? color;
  bool isFeatured;
  bool isBestSeller;
  bool isNewArrival;
  bool discountedOnly;

  FilterStateData({
    required this.priceRange,
    this.category,
    required this.selectedBrands,
    this.minRating,
    this.availability,
    this.color,
    this.isFeatured = false,
    this.isBestSeller = false,
    this.isNewArrival = false,
    this.discountedOnly = false,
  });

  FilterStateData copyWith({
    RangeValues? priceRange,
    String? category,
    List<String>? selectedBrands,
    double? minRating,
    String? availability,
    String? color,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNewArrival,
    bool? discountedOnly,
  }) {
    return FilterStateData(
      priceRange: priceRange ?? this.priceRange,
      category: category,
      selectedBrands: selectedBrands ?? List.from(this.selectedBrands),
      minRating: minRating,
      availability: availability,
      color: color,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      discountedOnly: discountedOnly ?? this.discountedOnly,
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterStateData initialFilters;
  final List<String> availableCategories;
  final List<String> availableBrands;
  final List<String> availableColors;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<FilterStateData> onApply;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.availableCategories,
    required this.availableBrands,
    required this.availableColors,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterStateData _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = FilterStateData(
      priceRange: widget.initialFilters.priceRange,
      category: widget.initialFilters.category,
      selectedBrands: List.from(widget.initialFilters.selectedBrands),
      minRating: widget.initialFilters.minRating,
      availability: widget.initialFilters.availability,
      color: widget.initialFilters.color,
      isFeatured: widget.initialFilters.isFeatured,
      isBestSeller: widget.initialFilters.isBestSeller,
      isNewArrival: widget.initialFilters.isNewArrival,
      discountedOnly: widget.initialFilters.discountedOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PriceRangeSlider(
                    currentRange: _localFilters.priceRange,
                    minPrice: widget.minPrice,
                    maxPrice: widget.maxPrice,
                    onChanged: (val) => setState(() => _localFilters.priceRange = val),
                  ),
                  const SizedBox(height: 16),
                  CategoryFilter(
                    categories: widget.availableCategories,
                    selectedCategory: _localFilters.category,
                    onSelected: (cat) => setState(() => _localFilters.category = cat),
                  ),
                  const SizedBox(height: 16),
                  BrandFilter(
                    brands: widget.availableBrands,
                    selectedBrands: _localFilters.selectedBrands,
                    onToggleBrand: (brand) {
                      setState(() {
                        if (_localFilters.selectedBrands.contains(brand)) {
                          _localFilters.selectedBrands.remove(brand);
                        } else {
                          _localFilters.selectedBrands.add(brand);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  RatingFilter(
                    selectedRating: _localFilters.minRating,
                    onSelected: (r) => setState(() => _localFilters.minRating = r),
                  ),
                  const SizedBox(height: 16),
                  AvailabilityFilter(
                    selectedAvailability: _localFilters.availability,
                    onSelected: (a) => setState(() => _localFilters.availability = a),
                  ),
                  const SizedBox(height: 16),
                  ColorFilter(
                    availableColors: widget.availableColors,
                    selectedColor: _localFilters.color,
                    onSelected: (c) => setState(() => _localFilters.color = c),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Discounted Products Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _localFilters.discountedOnly,
                    onChanged: (val) => setState(() => _localFilters.discountedOnly = val),
                  ),
                  FeaturedFilter(
                    isFeatured: _localFilters.isFeatured,
                    onChanged: (val) => setState(() => _localFilters.isFeatured = val),
                  ),
                  BestSellerFilter(
                    isBestSeller: _localFilters.isBestSeller,
                    onChanged: (val) => setState(() => _localFilters.isBestSeller = val),
                  ),
                  NewArrivalFilter(
                    isNewArrival: _localFilters.isNewArrival,
                    onChanged: (val) => setState(() => _localFilters.isNewArrival = val),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onApply(_localFilters);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}