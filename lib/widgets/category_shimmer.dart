import 'package:flutter/material.dart';

/// A lightweight, dependency-free shimmer effect used while categories
/// are loading, so the User App never shows a blank screen or a bare
/// spinner during the initial `CategoryProvider.loadActiveCategories()`
/// call.
///
/// Implemented with a plain [AnimationController] + [ShaderMask] sweep
/// rather than the `shimmer` package, to avoid adding a new dependency
/// for a single visual effect.
class CategoryShimmer extends StatefulWidget {
  const CategoryShimmer({
    super.key,
    required this.crossAxisCount,
    this.itemCount = 8,
  });

  /// Number of grid columns to mirror (should match [CategoryGrid]'s
  /// current responsive column count, so the skeleton lines up with the
  /// real content that will replace it).
  final int crossAxisCount;

  /// How many skeleton tiles to render.
  final int itemCount;

  @override
  State<CategoryShimmer> createState() => _CategoryShimmerState();
}

class _CategoryShimmerState extends State<CategoryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                // Sweeps a highlight band left-to-right, looping via the
                // controller's 0..1 value mapped across a wider gradient
                // stop range so the band enters and exits smoothly.
                final sweep = _controller.value;
                return LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: [
                    (sweep - 0.3).clamp(0.0, 1.0),
                    sweep.clamp(0.0, 1.0),
                    (sweep + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: _ShimmerTile(color: baseColor),
        );
      },
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 12, width: 80, color: color),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 50, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}