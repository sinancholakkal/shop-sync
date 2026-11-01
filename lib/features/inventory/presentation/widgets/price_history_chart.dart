import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';

class PriceHistoryChart extends StatefulWidget {
  final List<PriceHistoryEntry> history;
  final double currentPrice;
  final double currentCost;

  const PriceHistoryChart({
    super.key,
    required this.history,
    required this.currentPrice,
    required this.currentCost,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  int _selectedFilterDays = 0; // 0 = All, 7 = 7 days, 30 = 30 days
  int? _hoveredIndex;

  List<PriceHistoryEntry> get _filteredHistory {
    if (widget.history.isEmpty) {
      return [
        PriceHistoryEntry(
          timestamp: DateTime.now(),
          price: widget.currentPrice,
          costPrice: widget.currentCost,
          note: 'Current Price',
        ),
      ];
    }

    final sorted = List<PriceHistoryEntry>.from(widget.history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (_selectedFilterDays <= 0) return sorted;

    final cutoff = DateTime.now().subtract(Duration(days: _selectedFilterDays));
    final filtered = sorted.where((e) => e.timestamp.isAfter(cutoff)).toList();

    if (filtered.isEmpty) {
      return [sorted.last];
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: '\$');
    final points = _filteredHistory;

    final prices = points.map((e) => e.price).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);

    // Percentage change from first to last point
    double percentChange = 0.0;
    if (points.length >= 2 && points.first.price > 0) {
      percentChange = ((points.last.price - points.first.price) / points.first.price) * 100.0;
    }

    final activeEntry = (_hoveredIndex != null &&
            _hoveredIndex! >= 0 &&
            _hoveredIndex! < points.length)
        ? points[_hoveredIndex!]
        : points.last;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title & Stats
          // Header with Title & Stats
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Price Trajectory',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${points.length} recorded revision${points.length == 1 ? '' : 's'}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Trend Badge
              if (points.length >= 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentChange >= 0
                        ? AppColors.accentEmerald.withValues(alpha: 0.15)
                        : AppColors.accentRose.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: percentChange >= 0
                          ? AppColors.accentEmerald.withValues(alpha: 0.3)
                          : AppColors.accentRose.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percentChange >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: percentChange >= 0 ? AppColors.accentEmerald : AppColors.accentRose,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: percentChange >= 0 ? AppColors.accentEmerald : AppColors.accentRose,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Time Range Filter Tabs & Legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              _buildFilterChip('All Time', 0, isDark),
              _buildFilterChip('30 Days', 30, isDark),
              _buildFilterChip('7 Days', 7, isDark),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retail',
                    style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cost',
                    style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hover / Active Tooltip Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primaryLight),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(activeEntry.timestamp),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if (activeEntry.note != null && activeEntry.note!.isNotEmpty)
                      Text(
                        '(${activeEntry.note})',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Retail: ',
                          style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                        Text(
                          currencyFmt.format(activeEntry.price),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cost: ',
                          style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                        Text(
                          currencyFmt.format(activeEntry.costPrice),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${activeEntry.effectiveMargin.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Painted Chart Area
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, points.length),
                  onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, points.length),
                  onPanEnd: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 180),
                    painter: _PriceChartPainter(
                      points: points,
                      hoveredIndex: _hoveredIndex,
                      isDark: isDark,
                      primaryColor: AppColors.primaryLight,
                      costColor: AppColors.accentAmber,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Min & Max Price Labels
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Lowest: ${currencyFmt.format(minPrice)}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                'Highest: ${currencyFmt.format(maxPrice)}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, double width, int pointCount) {
    if (pointCount <= 1) return;
    final padding = 20.0;
    final effectiveWidth = width - (padding * 2);
    final dx = (localPosition.dx - padding).clamp(0.0, effectiveWidth);
    final index = ((dx / effectiveWidth) * (pointCount - 1)).round();
    setState(() {
      _hoveredIndex = index.clamp(0, pointCount - 1);
    });
  }

  Widget _buildFilterChip(String label, int days, bool isDark) {
    final isSelected = _selectedFilterDays == days;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        _selectedFilterDays = days;
        _hoveredIndex = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.25)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryLight
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  final List<PriceHistoryEntry> points;
  final int? hoveredIndex;
  final bool isDark;
  final Color primaryColor;
  final Color costColor;

  _PriceChartPainter({
    required this.points,
    required this.hoveredIndex,
    required this.isDark,
    required this.primaryColor,
    required this.costColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double paddingX = 20.0;
    const double paddingY = 24.0;
    final double graphWidth = size.width - (paddingX * 2);
    final double graphHeight = size.height - (paddingY * 2);

    // Compute min and max across both price and cost
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final p in points) {
      if (p.price < minY) minY = p.price;
      if (p.price > maxY) maxY = p.price;
      if (p.costPrice < minY) minY = p.costPrice;
      if (p.costPrice > maxY) maxY = p.costPrice;
    }

    if (minY == maxY) {
      minY = minY * 0.8;
      maxY = maxY * 1.2;
    } else {
      final range = maxY - minY;
      minY = math.max(0, minY - (range * 0.15));
      maxY = maxY + (range * 0.15);
    }

    // Grid lines (3 horizontal dashed guides)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = paddingY + (graphHeight / 3) * i;
      canvas.drawLine(Offset(paddingX, y), Offset(size.width - paddingX, y), gridPaint);
    }

    // If single point, render flat dashed line with point
    if (points.length == 1) {
      final yPrice = paddingY + graphHeight * (1 - (points.first.price - minY) / (maxY - minY));
      final yCost = paddingY + graphHeight * (1 - (points.first.costPrice - minY) / (maxY - minY));

      final dashPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.6)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(paddingX, yPrice), Offset(size.width - paddingX, yPrice), dashPaint);

      final costDashPaint = Paint()
        ..color = costColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(paddingX, yCost), Offset(size.width - paddingX, yCost), costDashPaint);

      // Node circles
      final midX = size.width / 2;
      _drawGlowPoint(canvas, Offset(midX, yPrice), primaryColor, 6);
      _drawGlowPoint(canvas, Offset(midX, yCost), costColor, 5);
      return;
    }

    // Calculate offsets for Price and Cost
    final priceOffsets = <Offset>[];
    final costOffsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);
      final x = paddingX + (graphWidth * t);

      final normPrice = ((points[i].price - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final yPrice = paddingY + (graphHeight * (1.0 - normPrice));
      priceOffsets.add(Offset(x, yPrice));

      final normCost = ((points[i].costPrice - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final yCost = paddingY + (graphHeight * (1.0 - normCost));
      costOffsets.add(Offset(x, yCost));
    }

    // 1. Draw Cost Price Line (Secondary, amber)
    final costPath = _buildSmoothPath(costOffsets);
    final costLinePaint = Paint()
      ..color = costColor.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(costPath, costLinePaint);

    // 2. Draw Retail Price Area Gradient
    final pricePath = _buildSmoothPath(priceOffsets);

    final areaPath = Path.from(pricePath)
      ..lineTo(priceOffsets.last.dx, size.height - paddingY)
      ..lineTo(priceOffsets.first.dx, size.height - paddingY)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(paddingX, paddingY, graphWidth, graphHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // 3. Draw Retail Price Glowing Line
    final glowLinePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(pricePath, glowLinePaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pricePath, linePaint);

    // 4. Draw Point Markers
    for (int i = 0; i < priceOffsets.length; i++) {
      final isHovered = hoveredIndex == i;
      _drawGlowPoint(
        canvas,
        priceOffsets[i],
        primaryColor,
        isHovered ? 7.0 : 4.5,
      );
      _drawGlowPoint(
        canvas,
        costOffsets[i],
        costColor,
        isHovered ? 5.5 : 3.5,
      );

      // Vertical guide line for hovered index
      if (isHovered) {
        final guidePaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(priceOffsets[i].dx, paddingY),
          Offset(priceOffsets[i].dx, size.height - paddingY),
          guidePaint,
        );
      }
    }
  }

  Path _buildSmoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);

    if (pts.length == 2) {
      path.lineTo(pts.last.dx, pts.last.dy);
      return path;
    }

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i < pts.length - 2 ? pts[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  void _drawGlowPoint(Canvas canvas, Offset offset, Color color, double radius) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, radius + 3, glowPaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, radius, fillPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, radius * 0.4, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.isDark != isDark;
  }
}
