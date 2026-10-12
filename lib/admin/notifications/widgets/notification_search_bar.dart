import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../providers/notification_provider.dart';

class NotificationSearchBar extends StatefulWidget {
  const NotificationSearchBar({super.key});

  @override
  State<NotificationSearchBar> createState() => _NotificationSearchBarState();
}

class _NotificationSearchBarState extends State<NotificationSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    _controller.text = provider.searchQuery;
    _controller.addListener(() {
      provider.setSearchQuery(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.searchQuery.isEmpty && _controller.text.isNotEmpty) {
          _controller.clear();
        }

        return ClayCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: 24,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search title, body or ID...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                      onPressed: () {
                        _controller.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
            style: AppTypography.bodyLarge,
          ),
        );
      },
    );
  }
}
