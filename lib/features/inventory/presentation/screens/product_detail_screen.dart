import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/add_edit_item_dialog.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/price_history_chart.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final String itemId;

  const ProductDetailScreen({
    super.key,
    required this.itemId,
  });

  static Future<void> push(BuildContext context, String itemId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(itemId: itemId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    final appState = Provider.of<AppStateProvider>(context);
    final isOwner = appState.isOwner;
    final permission = appState.effectivePermission;
    final canModify = isOwner || permission.canModifyItems;
    final canCount = isOwner || permission.canUpdateStockCount;

    // Find the item reactively
    final item = appState.inventoryList.cast<InventoryItem?>().firstWhere(
          (i) => i?.id == itemId,
          orElse: () => null,
        );

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Product Details', style: GoogleFonts.outfit()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.secondary),
              const SizedBox(height: 16),
              Text(
                'Product Not Found',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This product may have been deleted.',
                style: GoogleFonts.outfit(color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Inventory'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    // Status Badge Info
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;
    if (item.isOutOfStock) {
      badgeColor = AppColors.accentRose;
      badgeText = 'Out of Stock';
      badgeIcon = Icons.error_outline_rounded;
    } else if (item.isLowStock) {
      badgeColor = AppColors.accentAmber;
      badgeText = 'Low Stock (${item.quantity})';
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeColor = AppColors.accentEmerald;
      badgeText = 'In Stock (${item.quantity})';
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canModify) ...[
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit Product',
              onPressed: () {
                AddEditItemDialog.show(
                  context,
                  item: item,
                  onSave: (updated) {
                    appState.updateInventoryItem(updated);
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
              tooltip: 'Delete Product',
              onPressed: () => _confirmDelete(context, appState, item),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Header Card
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Stock Status Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category_rounded, size: 13, color: AppColors.primaryLight),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    item.category,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 13, color: badgeColor),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    badgeText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // SKU with quick copy
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.sku));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('SKU "${item.sku}" copied to clipboard!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_rounded, size: 14, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'SKU: ${item.sku}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy_rounded, size: 13, color: isDark ? Colors.white38 : Colors.black38),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Financial Overview Metric Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 560;

                    final retailCard = _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.sell_rounded,
                      iconColor: AppColors.primaryLight,
                      label: 'Retail (Selling) Price',
                      value: currencyFmt.format(item.price),
                      subtext: 'Price updated: ${_formatRelativeTime(item.priceLastUpdated)}',
                    );

                    final costCard = _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.price_change_outlined,
                      iconColor: AppColors.accentAmber,
                      label: 'Cost (Acquisition) Price',
                      value: currencyFmt.format(item.costPrice),
                      subtext: 'Wholesale / purchase cost',
                    );

                    final marginCard = _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.accentEmerald,
                      label: 'Profit Margin',
                      value: '+${item.effectiveMarginPercent.toStringAsFixed(1)}%',
                      subtext: '+${currencyFmt.format(item.profitPerUnit)} profit / item',
                      valueColor: AppColors.accentEmerald,
                    );

                    final stockValCard = _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppColors.accentPurple,
                      label: 'Total Inventory Value',
                      value: currencyFmt.format(item.totalStockValue),
                      subtext: 'Cost value: ${currencyFmt.format(item.totalStockCost)}',
                    );

                    if (isSmall) {
                      return Column(
                        children: [
                          retailCard,
                          const SizedBox(height: 12),
                          costCard,
                          const SizedBox(height: 12),
                          marginCard,
                          const SizedBox(height: 12),
                          stockValCard,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: retailCard),
                            const SizedBox(width: 14),
                            Expanded(child: costCard),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: marginCard),
                            const SizedBox(width: 14),
                            Expanded(child: stockValCard),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Interactive Price History Graph
                PriceHistoryChart(
                  history: item.priceHistory,
                  currentPrice: item.price,
                  currentCost: item.costPrice,
                ),
                const SizedBox(height: 16),

                // 4. Price Revisions Timeline Log
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Price Revision History',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (item.priceHistory.isEmpty)
                        Text(
                          'No historical price changes recorded.',
                          style: GoogleFonts.outfit(color: AppColors.secondary, fontSize: 13),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: item.priceHistory.length,
                          separatorBuilder: (_, _) => Divider(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                            height: 16,
                          ),
                          itemBuilder: (context, idx) {
                            // Reverse order so latest is on top
                            final entry = item.priceHistory.reversed.toList()[idx];
                            final isCurrent = idx == 0;

                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isCurrent ? AppColors.accentEmerald : AppColors.primary)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCurrent ? Icons.check_circle_rounded : Icons.radio_button_checked_rounded,
                                    size: 14,
                                    color: isCurrent ? AppColors.accentEmerald : AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              entry.note ?? (isCurrent ? 'Current Active Price' : 'Price Revision'),
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            currencyFmt.format(entry.price),
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        spacing: 8,
                                        runSpacing: 2,
                                        children: [
                                          Text(
                                            dateFmt.format(entry.timestamp),
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          Text(
                                            'Cost: ${currencyFmt.format(entry.costPrice)} (+${entry.effectiveMargin.toStringAsFixed(1)}%)',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Stock Management & Stepper Card
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_rounded, size: 20, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Stock Inventory',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Stock count last updated pill
                          Text(
                            'Count updated ${_formatRelativeTime(item.stockLastUpdated)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.quantity} Units',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Threshold: ${item.minThreshold} units',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Stepper
                          if (canCount)
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_rounded, size: 18),
                                    onPressed: item.quantity > 0
                                        ? () => appState.updateStockQuantity(item.id, item.quantity - 1)
                                        : null,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    onPressed: () =>
                                        appState.updateStockQuantity(item.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Comprehensive Audit Timestamps Card
                GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 20, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Audit Timestamps & System Logs',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildAuditRow(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Product Created / First Added',
                        time: dateFmt.format(item.createdAt),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildAuditRow(
                        icon: Icons.update_rounded,
                        label: 'Product Last Updated',
                        time: dateFmt.format(item.lastUpdated),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildAuditRow(
                        icon: Icons.sell_outlined,
                        label: 'Price Last Updated',
                        time: dateFmt.format(item.priceLastUpdated),
                        isDark: isDark,
                        highlight: true,
                      ),
                      const SizedBox(height: 10),
                      _buildAuditRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock Count Last Updated',
                        time: dateFmt.format(item.stockLastUpdated),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildAuditRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Internal Product Document ID',
                        time: item.id,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Action Button
                if (canModify)
                  GlowingGlassButton(
                    onPressed: () {
                      AddEditItemDialog.show(
                        context,
                        item: item,
                        onSave: (updated) {
                          appState.updateInventoryItem(updated);
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Edit Product & Price',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtext,
    Color? valueColor,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow({
    required IconData icon,
    required String label,
    required String time,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.08)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: highlight ? AppColors.primaryLight : AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight
                    ? AppColors.primaryLight
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(time);
  }

  void _confirmDelete(BuildContext context, AppStateProvider appState, InventoryItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${item.name}"?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete this product from inventory?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              appState.deleteInventoryItem(item.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const Text('Delete Product', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
