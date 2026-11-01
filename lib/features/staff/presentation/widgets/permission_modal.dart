import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/staff/domain/models/staff_model.dart';

class PermissionAssignmentModal extends StatefulWidget {
  final StaffMember staff;
  final Function(StaffPermission) onSavePermission;
  final VoidCallback onToggleStatus;
  final bool isApprovalMode;

  const PermissionAssignmentModal({
    super.key,
    required this.staff,
    required this.onSavePermission,
    required this.onToggleStatus,
    this.isApprovalMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffMember staff,
    required Function(StaffPermission) onSavePermission,
    required VoidCallback onToggleStatus,
    bool isApprovalMode = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => PermissionAssignmentModal(
        staff: staff,
        onSavePermission: onSavePermission,
        onToggleStatus: onToggleStatus,
        isApprovalMode: isApprovalMode,
      ),
    );
  }

  @override
  State<PermissionAssignmentModal> createState() =>
      _PermissionAssignmentModalState();
}

class _PermissionAssignmentModalState extends State<PermissionAssignmentModal> {
  late StaffPermission _selectedPermission;

  @override
  void initState() {
    super.initState();
    _selectedPermission = widget.staff.permission;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isApprovalMode
                                      ? 'Approve Staff & Assign Role'
                                      : 'Manage Staff Permissions',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                               Text(
                                 widget.staff.name,
                                 style: GoogleFonts.outfit(
                                   fontSize: 13,
                                   color: isDark ? Colors.white70 : Colors.black54,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.close_rounded),
                     onPressed: () => Navigator.pop(context),
                   ),
                 ],
               ),
                const SizedBox(height: 20),

                // Staff Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          widget.staff.name.isNotEmpty
                              ? widget.staff.name[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.staff.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.staff.email,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.isApprovalMode
                            ? null
                            : () {
                                widget.onToggleStatus();
                                Navigator.pop(context);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isApprovalMode || !widget.staff.isApproved
                                ? Colors.amber.withValues(alpha: 0.15)
                                : (widget.staff.isActive
                                    ? AppColors.accentEmerald.withValues(alpha: 0.15)
                                    : AppColors.accentRose.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.isApprovalMode || !widget.staff.isApproved
                                  ? Colors.amber.withValues(alpha: 0.4)
                                  : (widget.staff.isActive
                                      ? AppColors.accentEmerald.withValues(alpha: 0.4)
                                      : AppColors.accentRose.withValues(alpha: 0.4)),
                            ),
                          ),
                          child: Text(
                            widget.isApprovalMode || !widget.staff.isApproved
                                ? 'Pending'
                                : (widget.staff.isActive ? 'Active' : 'Suspended'),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.isApprovalMode || !widget.staff.isApproved
                                  ? Colors.amber
                                  : (widget.staff.isActive
                                      ? AppColors.accentEmerald
                                      : AppColors.accentRose),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Select Role Permission Level',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Option 1: Full Access
                _PermissionOptionTile(
                  title: StaffPermission.fullAccess.title,
                  description: StaffPermission.fullAccess.description,
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.accentPurple,
                  isSelected: _selectedPermission == StaffPermission.fullAccess,
                  onSelect: () =>
                      setState(() => _selectedPermission = StaffPermission.fullAccess),
                ),
                const SizedBox(height: 10),

                // Option 2: Item & Inventory Manager (No Cost/Margin)
                _PermissionOptionTile(
                  title: StaffPermission.inventoryManager.title,
                  description: StaffPermission.inventoryManager.description,
                  icon: Icons.edit_note_rounded,
                  iconColor: AppColors.accentIndigo,
                  isSelected:
                      _selectedPermission == StaffPermission.inventoryManager,
                  onSelect: () => setState(
                      () => _selectedPermission = StaffPermission.inventoryManager),
                ),
                const SizedBox(height: 10),

                // Option 3: Stock Counting
                _PermissionOptionTile(
                  title: StaffPermission.stockCounting.title,
                  description: StaffPermission.stockCounting.description,
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppColors.primaryLight,
                  isSelected:
                      _selectedPermission == StaffPermission.stockCounting,
                  onSelect: () => setState(
                      () => _selectedPermission = StaffPermission.stockCounting),
                ),
                const SizedBox(height: 10),

                // Option 3: Read Only
                _PermissionOptionTile(
                  title: StaffPermission.readOnly.title,
                  description: StaffPermission.readOnly.description,
                  icon: Icons.visibility_rounded,
                  iconColor: AppColors.secondary,
                  isSelected: _selectedPermission == StaffPermission.readOnly,
                  onSelect: () =>
                      setState(() => _selectedPermission = StaffPermission.readOnly),
                ),

                const SizedBox(height: 24),

                GlowingGlassButton(
                  onPressed: () {
                    widget.onSavePermission(_selectedPermission);
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.isApprovalMode
                              ? 'Approve & Grant Access'
                              : 'Apply Permission',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _PermissionOptionTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PermissionOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryLight : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
