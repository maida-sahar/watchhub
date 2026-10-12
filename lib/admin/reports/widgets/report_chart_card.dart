import 'package:flutter/material.dart';

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });
}

class ReportChartCard extends StatefulWidget {
  final String title;
  final List<ChartDataPoint> dataPoints;
  final Color chartColor;
  final bool isCurrency;
  final String currencySymbol;
  final String emptyMessage;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.dataPoints,
    required this.chartColor,
    this.isCurrency = false,
    // Matches the app-wide default currency (see OrderModel.fromMap,
    // which falls back to 'USD') — this previously defaulted to 'Rs',
    // showing the wrong currency symbol on this chart's tooltip while
    // every other screen in the app displays amounts with '$'.
    this.currencySymbol = '\$',
    this.emptyMessage = 'No trend data available.',
  });

  @override
  State<ReportChartCard> createState() => _ReportChartCardState();
}

class _ReportChartCardState extends State<ReportChartCard> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedIndex != -1 && widget.dataPoints.isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.chartColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.dataPoints[_selectedIndex].label}: '
                      '${widget.isCurrency ? widget.currencySymbol : ''}'
                      '${widget.dataPoints[_selectedIndex].value.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.chartColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.dataPoints.isEmpty)
              SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    widget.emptyMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              _renderBarChart(context),
          ],
        ),
      ),
    );
  }

  Widget _renderBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = widget.dataPoints
        .map((dp) => dp.value)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.dataPoints.length, (index) {
          final dp = widget.dataPoints[index];
          final fraction = maxVal <= 0 ? 0.0 : dp.value / maxVal;
          final isSelected = _selectedIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = isSelected ? -1 : index;
                });
              },
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          FractionallySizedBox(
                            heightFactor: fraction,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.chartColor
                                    : widget.chartColor.withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dp.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
