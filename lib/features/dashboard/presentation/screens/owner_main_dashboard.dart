import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_dashboard_qr_screen.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/add_edit_item_dialog.dart';
import 'package:shop_sync_app/features/staff/presentation/widgets/permission_modal.dart';
import 'package:shop_sync_app/shared/cubit/shop_sync_cubit.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class OwnerMainDashboard extends StatelessWidget {
  const OwnerMainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final currencyFmt = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Top Welcome & Shop Banner
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
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    appState.shopName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      appState.isOwner ? 'Owner HQ' : 'Staff Portal',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appState.isOwner
                                    ? 'Welcome back! Here is your shop operational overview for today.'
                                    : 'Logged in as ${appState.currentStaff?.name ?? "Staff"} (${appState.effectivePermission.title})',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (appState.isOwner)
                          GlowingGlassButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OwnerDashboardQrScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Staff QR',
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

                    // Low Stock Alert Banner
                    if (appState.lowStockItemCount > 0) ...[
                      const SizedBox(height: 20),
                      GlassContainer(
                        borderRadius: 16,
                        color: AppColors.accentAmber.withValues(alpha: isDark ? 0.15 : 0.12),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: AppColors.accentAmber, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attention: ${appState.lowStockItemCount} product(s) are low in stock!',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Replenish inventory to avoid running out of high-demand items.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => appState.setActiveNavIndex(1), // switch to inventory
                              child: Text(
                                'View Items',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Staff Pending Approval Banner (Option 1)
                    if (appState.isOwner && appState.pendingStaffCount > 0) ...[
                      const SizedBox(height: 20),
                      _PendingStaffApprovalQueueCard(appState: appState),
                    ],

                    const SizedBox(height: 24),

                    // Quick Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 950;
                        final isTablet = constraints.maxWidth > 550 && !isDesktop;

                        final cards = [
                          _StatCard(
                            title: 'Total Revenue',
                            value: currencyFmt.format(appState.totalRevenue),
                            subtext: '+14.2% from yesterday',
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.accentEmerald,
                          ),
                          _StatCard(
                            title: 'Total Inventory Units',
                            value: '${appState.totalStockQuantity} units',
                            subtext: '${appState.inventoryList.length} unique catalog items',
                            icon: Icons.inventory_2_rounded,
                            iconColor: AppColors.primaryLight,
                          ),
                          _StatCard(
                            title: 'Active Team Staff',
                            value: '${appState.activeStaffCount} / ${appState.staffList.length}',
                            subtext: appState.pendingStaffCount > 0
                                ? '${appState.pendingStaffCount} awaiting approval'
                                : 'Team accounts linked',
                            icon: Icons.people_alt_rounded,
                            iconColor: appState.pendingStaffCount > 0
                                ? Colors.amber
                                : AppColors.secondary,
                          ),
                          _StatCard(
                            title: 'Completed Sales',
                            value: '${appState.transactionList.length}',
                            subtext: 'Orders processed',
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.accentPurple,
                          ),
                        ];

                        if (isDesktop) {
                          return Row(
                            children: cards
                                .map((c) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: c,
                                      ),
                                    ))
                                .toList(),
                          );
                        } else if (isTablet) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: cards[1]),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: cards[2]),
                                  const SizedBox(width: 12),
                                  Expanded(child: cards[3]),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: cards
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: c,
                                    ))
                                .toList(),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 28),

                    // Quick Actions Glass Bar
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (appState.isOwner)
                            _QuickActionButton(
                              icon: Icons.qr_code_rounded,
                              label: 'Onboarding QR',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerDashboardQrScreen(),
                                  ),
                                );
                              },
                            ),
                          if (appState.isOwner || appState.effectivePermission.canModifyItems) ...[
                            const SizedBox(width: 12),
                            _QuickActionButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add Product',
                              onTap: () {
                                AddEditItemDialog.show(
                                  context,
                                  onSave: (newItem) {
                                    appState.addInventoryItem(newItem);
                                  },
                                );
                              },
                            ),
                          ],
                          const SizedBox(width: 12),
                          _QuickActionButton(
                            icon: Icons.inventory_rounded,
                            label: 'Inventory Count',
                            onTap: () => appState.setActiveNavIndex(1),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'View Transactions',
                            onTap: () => appState.setActiveNavIndex(3),
                          ),
                          if (appState.isOwner) ...[
                            const SizedBox(width: 12),
                            _QuickActionButton(
                              icon: Icons.badge_rounded,
                              label: 'Manage Staff',
                              onTap: () => appState.setActiveNavIndex(2),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Recent Activity & Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Transactions',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => appState.setActiveNavIndex(3),
                          child: Text(
                            'View All',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions Preview
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = appState.transactionList[index];
                    final dateStr = DateFormat('hh:mm a').format(tx.timestamp);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryLight, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.invoiceNo,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${tx.customerName} • By ${tx.staffName}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.accentEmerald,
                                  ),
                                ),
                                Text(
                                  '$dateStr • ${tx.paymentMethodName}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: appState.transactionList.take(4).length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      onTap: onTap,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingStaffApprovalQueueCard extends StatelessWidget {
  final AppStateProvider appState;

  const _PendingStaffApprovalQueueCard({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingStaff = appState.pendingStaffList;

    return GlassContainer(
      borderRadius: 20,
      color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
      border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Staff Approval Queue',
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
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${appState.pendingStaffCount} PENDING',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Staff joined via rotating QR code and require your approval to access the store.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pending members list
          ...pendingStaff.map((staff) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          staff.email,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reject button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.accentRose),
                    tooltip: 'Decline Staff',
                    onPressed: () {
                      appState.rejectStaff(staff.id);
                      try {
                        context.read<ShopSyncCubit?>()?.rejectStaff(staff.id);
                      } catch (_) {}
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${staff.name}\'s registration was rejected.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // Approve button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      PermissionAssignmentModal.show(
                        context,
                        staff: staff,
                        isApprovalMode: true,
                        onSavePermission: (newPerm) {
                          appState.approveStaff(staff.id, newPerm);
                          try {
                            context.read<ShopSyncCubit?>()?.approveStaff(staff.id, newPerm);
                          } catch (_) {}
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              content: Text('${staff.name} approved with ${newPerm.title}!'),
                            ),
                          );
                        },
                        onToggleStatus: () {},
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
