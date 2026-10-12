import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/widgets/app_header.dart';

import '../../../providers/wishlist_provider.dart';

/// Luxury AppHeader displaying title and dynamic Wishlist item count.
class WishlistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WishlistAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final count = context.select<WishlistProvider, int>(
      (p) => p.wishlistCount,
    );

    return AppHeader(
      title: 'My Wishlist',
      subtitle: count > 0 ? '$count saved timepieces' : '0 saved',
      actions: [
        AppHeaderActionButton(
          tooltip: 'Wishlist Count',
          icon: Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}