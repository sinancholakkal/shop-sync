import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_dashboard_qr_screen.dart';
import 'package:shop_sync_app/features/staff/domain/models/staff_model.dart';
import 'package:shop_sync_app/features/staff/presentation/widgets/permission_modal.dart';
import 'package:shop_sync_app/shared/cubit/shop_sync_cubit.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final isOwner = appState.isOwner;

    final filteredStaff = appState.staffList.where((staff) {
      final query = _searchQuery.toLowerCase();
      return staff.name.toLowerCase().contains(query) ||
          staff.email.toLowerCase().contains(query);
    }).toList();

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
            // Header & Actions
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
                                'Staff Management',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Onboard and assign role permissions to shop team members',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 12),
                          GlowingGlassButton(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                                const Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Invite QR',
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
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatChip(
                            label: 'Total Staff',
                            value: '${appState.staffList.length}',
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'Active',
                            value: '${appState.activeStaffCount}',
                            color: AppColors.accentEmerald,
                          ),
                          if (appState.pendingStaffCount > 0) ...[
                            const SizedBox(width: 12),
                            _StatChip(
                              label: 'Pending Approvals',
                              value: '${appState.pendingStaffCount}',
                              color: Colors.amber,
                            ),
                          ],
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'Suspended',
                            value: '${appState.staffList.length - appState.activeStaffCount - appState.pendingStaffCount}',
                            color: AppColors.accentRose,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search input
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search staff by name or email...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),

                    // Pending Approval Section (Option 1)
                    if (isOwner && appState.pendingStaffCount > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Awaiting Owner Approval (${appState.pendingStaffCount})',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...appState.pendingStaffList.map((st) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _StaffPendingApprovalTile(staff: st, appState: appState),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Staff List
            filteredStaff.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 56,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No staff members found',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final staff = filteredStaff[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _StaffCard(
                              staff: staff,
                              isOwner: isOwner,
                              onTapManage: () {
                                if (isOwner) {
                                  PermissionAssignmentModal.show(
                                    context,
                                    staff: staff,
                                    isApprovalMode: !staff.isApproved,
                                    onSavePermission: (newPerm) {
                                      if (!staff.isApproved) {
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
                                      } else {
                                        appState.updateStaffPermission(staff.id, newPerm);
                                      }
                                    },
                                    onToggleStatus: () {
                                      appState.toggleStaffStatus(staff.id);
                                    },
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Only the Shop Owner can modify staff permissions.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                        childCount: filteredStaff.length,
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember staff;
  final bool isOwner;
  final VoidCallback onTapManage;

  const _StaffCard({
    required this.staff,
    required this.isOwner,
    required this.onTapManage,
  });

  Color _getPermissionColor(StaffPermission perm) {
    switch (perm) {
      case StaffPermission.fullAccess:
        return AppColors.accentPurple;
      case StaffPermission.stockCounting:
        return AppColors.primaryLight;
      case StaffPermission.readOnly:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permColor = _getPermissionColor(staff.permission);
    final joinedStr = DateFormat('MMM dd, yyyy').format(staff.joinedDate);

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: permColor.withValues(alpha: 0.18),
            child: Text(
              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: permColor,
              ),
            ),
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
                        staff.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: !staff.isApproved
                            ? Colors.amber.withValues(alpha: 0.2)
                            : (staff.isActive
                                ? AppColors.accentEmerald.withValues(alpha: 0.15)
                                : AppColors.accentRose.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        !staff.isApproved
                            ? 'Pending Approval'
                            : (staff.isActive ? 'Active' : 'Suspended'),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: !staff.isApproved
                              ? Colors.amber
                              : (staff.isActive ? AppColors.accentEmerald : AppColors.accentRose),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  staff.email,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: permColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: permColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: permColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              staff.permission.title,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: permColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Joined $joinedStr',
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
          if (isOwner) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: staff.isApproved ? 'Configure Permissions' : 'Review & Approve',
              onPressed: onTapManage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: !staff.isApproved
                      ? Colors.amber.withValues(alpha: 0.2)
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !staff.isApproved ? Icons.verified_user_rounded : Icons.tune_rounded,
                  size: 18,
                  color: !staff.isApproved ? Colors.amber : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffPendingApprovalTile extends StatelessWidget {
  final StaffMember staff;
  final AppStateProvider appState;

  const _StaffPendingApprovalTile({
    required this.staff,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            radius: 16,
            backgroundColor: Colors.amber.withValues(alpha: 0.2),
            child: Text(
              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.accentRose),
            tooltip: 'Decline',
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_rounded, size: 14),
            label: Text(
              'Approve',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
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
  }
}
