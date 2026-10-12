import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../utils/report_file_saver.dart';

/// Which of the Export screen's report types was requested. Kept distinct
/// from any UI-layer string so the table-building logic below stays
/// readable regardless of how the dropdown labels are worded.
enum ReportExportType { sales, revenue, inventory, customer, product, all }

class ReportExportException implements Exception {
  final String message;
  const ReportExportException(this.message);
  @override
  String toString() => message;
}

/// Builds and delivers a real, downloadable report file (PDF, Excel, or
/// CSV) from data the app already has loaded — [OrderProvider.allOrders],
/// [ProductProvider.products], and [UserProvider.customers]. No new
/// Firestore reads happen here; this only formats what the report screens
/// themselves already pull from those same providers.
class ReportExportService {
  const ReportExportService();

  /// Generates the report and hands it to the platform's save/share flow.
  /// Throws [ReportExportException] on failure so the UI can show a real
  /// error instead of a fake "success" toast.
  Future<void> exportReport({
    required ReportExportType type,
    required String format, // 'PDF' | 'Excel' | 'CSV'
    required DateTimeRange dateRange,
    required List<OrderModel> orders,
    required List<ProductModel> products,
    required List<UserModel> customers,
    bool includeMetadata = true,
  }) async {
    final ordersInRange = orders
        .where((o) => !o.createdAt.isBefore(dateRange.start) && o.createdAt.isBefore(dateRange.end))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final title = _titleFor(type);
    final headers = _headersFor(type);
    final rows = _rowsFor(type, ordersInRange, products, customers);

    if (rows.isEmpty) {
      throw const ReportExportException('No data found for the selected report and date range.');
    }

    final dateStamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final baseName = '${title.replaceAll(' ', '_')}_$dateStamp';

    switch (format) {
      case 'PDF':
        final bytes = await _buildPdf(title, dateRange, headers, rows, includeMetadata);
        await saveAndShareReportFile(bytes: bytes, fileName: '$baseName.pdf', mimeType: 'application/pdf');
        break;
      case 'Excel':
        final bytes = _buildExcel(title, headers, rows);
        await saveAndShareReportFile(
          bytes: bytes,
          fileName: '$baseName.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        break;
      case 'CSV':
        final bytes = _buildCsv(headers, rows);
        await saveAndShareReportFile(bytes: bytes, fileName: '$baseName.csv', mimeType: 'text/csv');
        break;
      default:
        throw ReportExportException('Unsupported export format: $format');
    }
  }

  String _titleFor(ReportExportType type) {
    switch (type) {
      case ReportExportType.sales:
        return 'Sales Report';
      case ReportExportType.revenue:
        return 'Revenue Report';
      case ReportExportType.inventory:
        return 'Inventory Report';
      case ReportExportType.customer:
        return 'Customer Report';
      case ReportExportType.product:
        return 'Product Performance Report';
      case ReportExportType.all:
        return 'WatchHub Full Report';
    }
  }

  List<String> _headersFor(ReportExportType type) {
    switch (type) {
      case ReportExportType.sales:
      case ReportExportType.all:
        return const ['Order ID', 'Date', 'Customer', 'Items', 'Total', 'Status'];
      case ReportExportType.revenue:
        return const ['Order ID', 'Date', 'Subtotal', 'Discount', 'Tax', 'Shipping', 'Grand Total'];
      case ReportExportType.inventory:
        return const ['SKU', 'Product', 'Brand', 'Stock', 'Min Stock', 'Status'];
      case ReportExportType.customer:
        return const ['Name', 'Email', 'Phone', 'Status'];
      case ReportExportType.product:
        return const ['Product', 'Brand', 'Price', 'Rating', 'Reviews', 'Stock'];
    }
  }

  List<List<String>> _rowsFor(
    ReportExportType type,
    List<OrderModel> orders,
    List<ProductModel> products,
    List<UserModel> customers,
  ) {
    final dateFmt = DateFormat('MMM d, yyyy');

    switch (type) {
      case ReportExportType.sales:
      case ReportExportType.all:
        return orders
            .map((o) => [
                  o.orderId,
                  dateFmt.format(o.createdAt),
                  o.shippingAddress.fullName,
                  o.items.length.toString(),
                  '${o.currency} ${o.grandTotal.toStringAsFixed(2)}',
                  o.orderStatus,
                ])
            .toList();

      case ReportExportType.revenue:
        return orders
            .map((o) => [
                  o.orderId,
                  dateFmt.format(o.createdAt),
                  o.subtotal.toStringAsFixed(2),
                  (o.discount + o.couponDiscount).toStringAsFixed(2),
                  o.tax.toStringAsFixed(2),
                  o.shippingCharge.toStringAsFixed(2),
                  o.grandTotal.toStringAsFixed(2),
                ])
            .toList();

      case ReportExportType.inventory:
        return products
            .map((p) => [
                  p.sku,
                  p.name,
                  p.brandName,
                  p.stock.toString(),
                  p.minimumStock.toString(),
                  p.stock <= 0 ? 'Out of Stock' : (p.stock <= p.minimumStock ? 'Low Stock' : 'In Stock'),
                ])
            .toList();

      case ReportExportType.customer:
        return customers
            .map((c) => [
                  c.name,
                  c.email,
                  c.phone,
                  c.isBlocked ? 'Blocked' : 'Active',
                ])
            .toList();

      case ReportExportType.product:
        return products
            .map((p) => [
                  p.name,
                  p.brandName,
                  p.price.toStringAsFixed(2),
                  p.averageRating.toStringAsFixed(1),
                  p.totalReviews.toString(),
                  p.stock.toString(),
                ])
            .toList();
    }
  }

  // =========================================================
  // PDF
  // =========================================================
  Future<Uint8List> _buildPdf(
    String title,
    DateTimeRange range,
    List<String> headers,
    List<List<String>> rows,
    bool includeMetadata,
  ) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('MMM d, yyyy');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${dateFmt.format(range.start)} - ${dateFmt.format(range.end.subtract(const Duration(days: 1)))}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          if (includeMetadata) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Generated by WatchHub Admin on ${dateFmt.format(DateTime.now())} • ${rows.length} record(s)',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // =========================================================
  // EXCEL
  // =========================================================
  Uint8List _buildExcel(String title, List<String> headers, List<List<String>> rows) {
    final excel = xl.Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());
    for (final row in rows) {
      sheet.appendRow(row.map((cell) => xl.TextCellValue(cell)).toList());
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw const ReportExportException('Failed to encode Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  // =========================================================
  // CSV
  // =========================================================
  Uint8List _buildCsv(List<String> headers, List<List<String>> rows) {
    final data = [headers, ...rows];
    // csv 8.x renamed CsvCodec -> Csv and dropped the old
    // ListToCsvConverter/CsvToListConverter classes entirely.
    final csv = Csv().encode(data);
    return Uint8List.fromList(csv.codeUnits);
  }
}