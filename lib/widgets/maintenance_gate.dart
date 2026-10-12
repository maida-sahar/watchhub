import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/settings_provider.dart';

/// Wraps the customer-facing app shell and enforces Admin Settings'
/// "Maintenance Mode" toggle.
///
/// Previously `AdminSettings.maintenanceMode` could be turned on from
/// Admin → Settings and saved successfully to Firestore, but nothing in
/// the app ever read it back — the switch had no actual effect on the
/// Customer side. This widget is the read side: it watches the same
/// `settings/admin` document (via [SettingsProvider]) and, when
/// maintenance mode is on, replaces [child] with a blocking "under
/// maintenance" screen instead of the normal customer UI.
///
/// Only wraps customer-facing routes — the Admin app shell is never
/// wrapped by this, so an admin can always get back into Settings to
/// turn maintenance mode off again.
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsProv = context.read<SettingsProvider>();
      if (settingsProv.adminSettings == null) {
        settingsProv.loadAdminSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final isUnderMaintenance = settingsProv.adminSettings?.maintenanceMode ?? false;

    if (!isUnderMaintenance) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_outlined, size: 72, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  'Under Maintenance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "We're making some improvements. Please check back shortly.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => settingsProv.loadAdminSettings(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
