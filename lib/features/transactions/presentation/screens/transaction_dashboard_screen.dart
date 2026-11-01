import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/transactions/domain/models/transaction_model.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class TransactionDashboardScreen extends StatefulWidget {
  const TransactionDashboardScreen({super.key});

  @override
  State<TransactionDashboardScreen> createState() =>
      _TransactionDashboardScreenState();
}

class _TransactionDashboardScreenState
    extends State<TransactionDashboardScreen> {
  String _searchQuery = '';

  void _showNewSaleModal(BuildContext context, AppStateProvider appState) {
    final customerCtrl = TextEditingController(text: 'Customer Walk-in');
    final amountCtrl = TextEditingController(text: '89.99');
    PaymentMethod method = PaymentMethod.qrPay;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Record New Sale',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Customer Name', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customerCtrl,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
                      ),
                      const SizedBox(height: 14),
                      Text('Total Sale Amount (\$)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money_rounded)),
                      ),
                      const SizedBox(height: 14),
                      Text('Payment Method', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: PaymentMethod.values.map((pm) {
                          final isSel = method == pm;
                          return ChoiceChip(
                            label: Text(pm.name.toUpperCase()),
                            selected: isSel,
                            onSelected: (_) => setModalState(() => method = pm),
                            selectedColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      GlowingGlassButton(
                        onPressed: () {
                          final amt = double.tryParse(amountCtrl.text) ?? 50.0;
                          final newTx = ShopTransaction(
                            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                            invoiceNo: 'INV-2026-${1000 + appState.transactionList.length + 1}',
                            timestamp: DateTime.now(),
                            staffName: appState.isOwner ? 'Owner Admin' : (appState.currentStaff?.name ?? 'Staff'),
                            customerName: customerCtrl.text.trim().isEmpty ? 'Walk-in Customer' : customerCtrl.text.trim(),
                            totalAmount: amt,
                            paymentMethod: method,
                            itemsCount: 1,
                          );
                          appState.addTransaction(newTx);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Complete Transaction',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final currencyFmt = NumberFormat.currency(symbol: '\$');

    final transactions = appState.transactionList.where((tx) {
      final q = _searchQuery.toLowerCase();
      return tx.invoiceNo.toLowerCase().contains(q) ||
          tx.staffName.toLowerCase().contains(q) ||
          tx.customerName.toLowerCase().contains(q);
    }).toList();

    final avgSale = appState.transactionList.isNotEmpty
        ? (appState.totalRevenue / appState.transactionList.length)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          onRefresh: () => appState.refreshAllData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Dashboard',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Monitor daily shop revenues, payment methods, and invoices',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlowingGlassButton(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          onPressed: () => _showNewSaleModal(context, appState),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Record Sale',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Metrics Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 650;
                        if (isSmall) {
                          return Column(
                            children: [
                              _MetricCard(
                                title: 'Total Revenue',
                                value: currencyFmt.format(appState.totalRevenue),
                                icon: Icons.payments_rounded,
                                iconColor: AppColors.accentEmerald,
                              ),
                              const SizedBox(height: 12),
                              _MetricCard(
                                title: 'Total Orders',
                                value: '${appState.transactionList.length}',
                                icon: Icons.shopping_cart_checkout_rounded,
                                iconColor: AppColors.primaryLight,
                              ),
                              const SizedBox(height: 12),
                              _MetricCard(
                                title: 'Avg Order Value',
                                value: currencyFmt.format(avgSale),
                                icon: Icons.analytics_rounded,
                                iconColor: AppColors.accentPurple,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Revenue',
                                value: currencyFmt.format(appState.totalRevenue),
                                icon: Icons.payments_rounded,
                                iconColor: AppColors.accentEmerald,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Orders',
                                value: '${appState.transactionList.length}',
                                icon: Icons.shopping_cart_checkout_rounded,
                                iconColor: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MetricCard(
                                title: 'Avg Order Value',
                                value: currencyFmt.format(avgSale),
                                icon: Icons.analytics_rounded,
                                iconColor: AppColors.accentPurple,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Search box
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search by Invoice No, Customer, or Staff Member...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Transactions Table / List
            transactions.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No matching transactions found.',
                        style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = transactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransactionCard(tx: tx),
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    ),
  );
}
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ShopTransaction tx;

  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: '\$');
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp);

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_rounded, color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.invoiceNo,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.status,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Customer: ${tx.customerName} • Served by ${tx.staffName}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFmt.format(tx.totalAmount),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentEmerald,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.paymentMethodName,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
