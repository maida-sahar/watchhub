import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/report_export_service.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  ReportDateFilterResult _dateFilter = const ReportDateFilterResult(ReportDateFilter.thisMonth);
  String _selectedType = 'All Reports';
  String _selectedFormat = 'PDF';

  bool _includeCharts = true;
  bool _includeDataTables = true;
  bool _includeMetadata = true;

  bool _isExporting = false;

  final List<String> _reportTypes = [
    'All Reports',
    'Sales Report',
    'Revenue Report',
    'Inventory Report',
    'Customer Report',
    'Product Performance',
  ];

  final List<String> _formats = ['PDF', 'Excel', 'CSV'];

  final ReportExportService _exportService = const ReportExportService();
  String? _exportError;

  ReportExportType _resolveType() {
    switch (_selectedType) {
      case 'Sales Report':
        return ReportExportType.sales;
      case 'Revenue Report':
        return ReportExportType.revenue;
      case 'Inventory Report':
        return ReportExportType.inventory;
      case 'Customer Report':
        return ReportExportType.customer;
      case 'Product Performance':
        return ReportExportType.product;
      default:
        return ReportExportType.all;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().watchAllOrders();
      context.read<ProductProvider>().loadProducts();
      context.read<UserProvider>().watchCustomers();
    });
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<ReportDateFilterResult>(
      context: context,
      builder: (_) => ReportFilterDialog(current: _dateFilter),
    );
    if (result != null) {
      setState(() => _dateFilter = result);
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      final orders = context.read<OrderProvider>().allOrders;
      final products = context.read<ProductProvider>().products;
      final customers = context.read<UserProvider>().customers;

      await _exportService.exportReport(
        type: _resolveType(),
        format: _selectedFormat,
        dateRange: _dateFilter.resolve(),
        orders: orders,
        products: products,
        customers: customers,
        includeMetadata: _includeMetadata,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedType exported as $_selectedFormat!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_exportError ?? 'Export failed.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Configuration card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Parameters',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Report Type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Select Report Module',
                          prefixIcon: const Icon(Icons.analytics_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _reportTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Format selector
                      DropdownButtonFormField<String>(
                        value: _selectedFormat,
                        decoration: InputDecoration(
                          labelText: 'Select Export Format',
                          prefixIcon: const Icon(Icons.file_present_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _formats.map((format) {
                          return DropdownMenuItem<String>(
                            value: format,
                            child: Text(format),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedFormat = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date range selector row
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporting Interval',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateFilter.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openFilterDialog,
                            child: const Text('Change Date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Export toggles
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Include Options',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _includeCharts,
                        title: const Text('Include Charts & Graphs'),
                        subtitle: const Text('Renders visual data buckets'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _includeCharts = val),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        value: _includeDataTables,
                        title: const Text('Include Data Tables'),
                        subtitle: const Text('Lists itemized transactional records'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _includeDataTables = val),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        value: _includeMetadata,
                        title: const Text('Include Audit Signatures'),
                        subtitle: const Text('Appends database timestamp hash'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _includeMetadata = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Export Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: _isExporting ? null : _startExport,
                  child: _isExporting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Exporting... Please wait'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded),
                            const SizedBox(width: 8),
                            Text('Generate & Export Report', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}