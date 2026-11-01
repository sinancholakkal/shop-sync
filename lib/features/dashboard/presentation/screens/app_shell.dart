import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/theme/theme_provider.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/core/widgets/responsive_layout.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_auth_screen.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_dashboard_qr_screen.dart';
import 'package:shop_sync_app/features/dashboard/presentation/cubit/nav_bar_cubit.dart';
import 'package:shop_sync_app/features/dashboard/presentation/screens/owner_main_dashboard.dart';
import 'package:shop_sync_app/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:shop_sync_app/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:shop_sync_app/features/transactions/presentation/screens/transaction_dashboard_screen.dart';
import 'package:shop_sync_app/shared/cubit/shop_sync_cubit.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isNavBarCompact = false;

  void _updateNavBarCompact(bool isCompact) {
    if (_isNavBarCompact != isCompact) {
      setState(() {
        _isNavBarCompact = isCompact;
      });
      try {
        context.read<NavBarCubit?>()?.setCompact(isCompact);
      } catch (_) {}
    }
  }

  void _handleLogout(BuildContext context, AppStateProvider appState) {
    appState.logout();
    try {
      context.read<ShopSyncCubit?>()?.logout();
    } catch (_) {}
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OwnerAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  final List<Widget> _screens = const [
    OwnerMainDashboard(),
    InventoryScreen(),
    StaffListScreen(),
    TransactionDashboardScreen(),
  ];

  void _showAccountInfoDialog(BuildContext context, AppStateProvider appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with vibrant icon & close button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role & Access Control',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appState.isRealOwner
                                    ? 'RBAC • Staff Visibility Engine'
                                    : 'Staff Profile & Assigned Rights',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            ),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Account Profile Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appState.shopName.isNotEmpty ? appState.shopName : 'My Shop',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appState.shopId.isNotEmpty ? appState.shopId : 'SHOP',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appState.isRealOwner
                                      ? appState.ownerEmail
                                      : (appState.currentStaff?.email ?? 'N/A'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (appState.isRolePreviewMode
                                          ? AppColors.accentAmber
                                          : (appState.isRealOwner ? AppColors.accentEmerald : AppColors.secondary))
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (appState.isRolePreviewMode
                                            ? AppColors.accentAmber
                                            : (appState.isRealOwner ? AppColors.accentEmerald : AppColors.secondary))
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      appState.isRolePreviewMode
                                          ? Icons.visibility_rounded
                                          : (appState.isRealOwner ? Icons.verified_rounded : Icons.badge_rounded),
                                      size: 11,
                                      color: appState.isRolePreviewMode
                                          ? AppColors.accentAmber
                                          : (appState.isRealOwner ? AppColors.accentEmerald : AppColors.secondary),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appState.isRolePreviewMode
                                          ? 'Preview Active'
                                          : (appState.isRealOwner ? 'Owner HQ' : 'Staff'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: appState.isRolePreviewMode
                                            ? AppColors.accentAmber
                                            : (appState.isRealOwner ? AppColors.accentEmerald : AppColors.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Staff Visibility Simulator Section (Admin Only)
                    if (appState.isRealOwner) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.visibility_rounded,
                              size: 15,
                              color: AppColors.accentAmber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Staff Visibility Preview',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any role below to simulate what staff will see in inventory, sales, and catalog in real-time:',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModernRoleCard(
                        title: 'Shop Owner HQ (Full Admin)',
                        badge: 'Default • All Access',
                        description: 'Complete management, staff approvals, and revenue analytics.',
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                        isSelected: !appState.isRolePreviewMode,
                        isDark: isDark,
                        onTap: () {
                          appState.switchDemoRole(UserRole.owner);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModernRoleCard(
                        title: 'Staff: Full Access',
                        badge: 'Catalog & Stock Control',
                        description: 'Can manage catalog and adjust stock. Cannot manage other staff.',
                        icon: Icons.verified_user_rounded,
                        color: AppColors.accentEmerald,
                        isSelected: appState.isRolePreviewMode &&
                            appState.effectivePermission == StaffPermission.fullAccess,
                        isDark: isDark,
                        onTap: () {
                          appState.switchDemoRole(UserRole.staff, StaffPermission.fullAccess);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModernRoleCard(
                        title: 'Staff: Item & Inventory Manager',
                        badge: 'Add/Edit Items • No Cost/Margin',
                        description: 'Can add, edit, delete items and manage counts. Cost price and profit margins are hidden.',
                        icon: Icons.edit_note_rounded,
                        color: AppColors.accentIndigo,
                        isSelected: appState.isRolePreviewMode &&
                            appState.effectivePermission == StaffPermission.inventoryManager,
                        isDark: isDark,
                        onTap: () {
                          appState.switchDemoRole(UserRole.staff, StaffPermission.inventoryManager);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModernRoleCard(
                        title: 'Staff: Stock Counting Only',
                        badge: 'Stock Count Only',
                        description: 'Can only update stock quantities (+ / -). Modifying items is locked.',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.accentAmber,
                        isSelected: appState.isRolePreviewMode &&
                            appState.effectivePermission == StaffPermission.stockCounting,
                        isDark: isDark,
                        onTap: () {
                          appState.switchDemoRole(UserRole.staff, StaffPermission.stockCounting);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildModernRoleCard(
                        title: 'Staff: Read-Only Access',
                        badge: 'View Only',
                        description: 'Can view shop catalog & sales. All modifications disabled.',
                        icon: Icons.visibility_rounded,
                        color: AppColors.accentPurple,
                        isSelected: appState.isRolePreviewMode &&
                            appState.effectivePermission == StaffPermission.readOnly,
                        isDark: isDark,
                        onTap: () {
                          appState.switchDemoRole(UserRole.staff, StaffPermission.readOnly);
                          Navigator.pop(context);
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primaryLight),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Role: Staff Member (${appState.effectivePermission.title})',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your permissions are strictly managed by your Shop Owner. Staff cannot switch roles.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernRoleCard({
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
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
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? color : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? color : (isDark ? Colors.white30 : Colors.black26),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);

    // If logged out, render OwnerAuthScreen
    if (!appState.isAuthenticated) {
      return const OwnerAuthScreen();
    }

    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          // Desktop / Tablet Sidebar
          if (isDesktop || isTablet)
            Container(
              width: isDesktop ? 260 : 88,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.85),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.lightGlassBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo & Brand Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Row(
                      mainAxisAlignment: isDesktop
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 22),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ShopSync',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  appState.shopName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Nav Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _SidebarNavItem(
                          icon: Icons.dashboard_rounded,
                          title: 'Dashboard',
                          isSelected: appState.activeNavIndex == 0,
                          isCollapsed: !isDesktop,
                          onTap: () => appState.setActiveNavIndex(0),
                        ),
                        _SidebarNavItem(
                          icon: Icons.inventory_2_rounded,
                          title: 'Inventory',
                          isSelected: appState.activeNavIndex == 1,
                          isCollapsed: !isDesktop,
                          onTap: () => appState.setActiveNavIndex(1),
                        ),
                        _SidebarNavItem(
                          icon: Icons.people_alt_rounded,
                          title: 'Staff Team',
                          isSelected: appState.activeNavIndex == 2,
                          isCollapsed: !isDesktop,
                          onTap: () => appState.setActiveNavIndex(2),
                        ),
                        _SidebarNavItem(
                          icon: Icons.receipt_long_rounded,
                          title: 'Transactions',
                          isSelected: appState.activeNavIndex == 3,
                          isCollapsed: !isDesktop,
                          onTap: () => appState.setActiveNavIndex(3),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Controls (Role demo switcher, Theme toggle, Logout)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Demo Role Switcher Trigger
                        GlassContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          onTap: () =>
                              _showAccountInfoDialog(context, appState),
                          child: Row(
                            mainAxisAlignment: isDesktop
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                appState.isRealOwner && !appState.isRolePreviewMode
                                    ? Icons.admin_panel_settings_rounded
                                    : (appState.isRolePreviewMode
                                        ? Icons.visibility_rounded
                                        : Icons.badge_rounded),
                                size: 18,
                                color: appState.isRealOwner && !appState.isRolePreviewMode
                                    ? AppColors.primaryLight
                                    : (appState.isRolePreviewMode
                                        ? AppColors.accentAmber
                                        : AppColors.secondary),
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.isRealOwner
                                            ? (appState.isRolePreviewMode
                                                ? '👁️ Preview: ${appState.effectivePermission.title}'
                                                : 'Shop Owner HQ')
                                            : 'Staff: ${appState.effectivePermission.title}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: appState.isRolePreviewMode
                                              ? AppColors.accentAmber
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        appState.isRealOwner
                                            ? 'Click to switch role preview'
                                            : 'Assigned by Store Owner',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (appState.isRealOwner)
                                  const Icon(Icons.swap_horiz_rounded, size: 16)
                                else
                                  const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Theme & Logout Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Toggle Light/Dark Theme',
                              icon: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: isDark
                                    ? Colors.amber
                                    : AppColors.primary,
                              ),
                              onPressed: () => themeProvider.toggleTheme(),
                            ),
                            if (isDesktop) ...[
                              IconButton(
                                tooltip: 'Staff Onboarding QR',
                                icon: const Icon(Icons.qr_code_2_rounded,
                                    color: AppColors.secondary),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OwnerDashboardQrScreen(),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Log Out',
                                icon: const Icon(Icons.logout_rounded,
                                    color: AppColors.accentRose),
                                onPressed: () => _handleLogout(context, appState),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main View Content
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is UserScrollNotification) {
                      if (scrollNotification.direction == ScrollDirection.reverse) {
                        // User scrolls down (content moves up) -> Instagram compact mode
                        _updateNavBarCompact(true);
                      } else if (scrollNotification.direction == ScrollDirection.forward) {
                        // User scrolls up (content moves down) -> Expand with titles
                        _updateNavBarCompact(false);
                      }
                    } else if (scrollNotification is ScrollUpdateNotification) {
                      // If user scrolls back to the very top, auto-expand
                      if (scrollNotification.metrics.pixels <= 20) {
                        _updateNavBarCompact(false);
                      }
                    }
                    return false;
                  },
                  child: Column(
                    children: [
                      // Mobile Top Bar with Status Bar Safe Inset
                      if (context.isMobile)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.88),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? AppColors.darkGlassBorder
                                    : AppColors.lightGlassBorder,
                              ),
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.secondary
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.storefront_rounded,
                                              color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'ShopSync',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Mobile Role Chip
                                      GestureDetector(
                                        onTap: () =>
                                            _showAccountInfoDialog(context, appState),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (appState.isRolePreviewMode
                                                    ? AppColors.accentAmber
                                                    : AppColors.primary)
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: appState.isRolePreviewMode
                                                ? Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4))
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                appState.isRealOwner
                                                    ? (appState.isRolePreviewMode ? '👁️ Preview' : 'Owner HQ')
                                                    : 'Staff',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: appState.isRolePreviewMode
                                                      ? AppColors.accentAmber
                                                      : AppColors.primaryLight,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                appState.isRealOwner
                                                    ? Icons.swap_horiz_rounded
                                                    : Icons.info_outline_rounded,
                                                size: 13,
                                                color: appState.isRolePreviewMode
                                                    ? AppColors.accentAmber
                                                    : AppColors.primaryLight,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          isDark
                                              ? Icons.light_mode_rounded
                                              : Icons.dark_mode_rounded,
                                          size: 18,
                                          color: isDark
                                              ? Colors.amber
                                              : AppColors.primary,
                                        ),
                                        onPressed: () => themeProvider.toggleTheme(),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.logout_rounded,
                                            size: 18, color: AppColors.accentRose),
                                        onPressed: () => _handleLogout(context, appState),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Role Preview Banner when Shop Owner is testing as Staff
                      if (appState.isRolePreviewMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: isDark ? 0.25 : 0.18),
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.accentAmber.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_rounded, color: AppColors.accentAmber, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Owner Preview: Viewing as ${appState.effectivePermission.title}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => appState.switchDemoRole(UserRole.owner),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentAmber,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Exit Preview',
                                      style: GoogleFonts.outfit(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // View Switcher (remove top padding on mobile since top bar handles status bar inset)
                      Expanded(
                        child: context.isMobile
                            ? MediaQuery.removePadding(
                                context: context,
                                removeTop: true,
                                child: IndexedStack(
                                  index: appState.activeNavIndex,
                                  children: _screens,
                                ),
                              )
                            : IndexedStack(
                                index: appState.activeNavIndex,
                                children: _screens,
                              ),
                      ),
                    ],
                  ),
                ),

                // Mobile Floating Liquid Glass Pill Navigation Bar (Instagram-style shrink on scroll)
                // Automatically hidden when keyboard is open to prevent covering search/inputs
                if (context.isMobile && MediaQuery.of(context).viewInsets.bottom == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _FloatingGlassPillNavBar(
                      selectedIndex: appState.activeNavIndex,
                      isCompact: _isNavBarCompact,
                      onItemSelected: (idx) {
                        appState.setActiveNavIndex(idx);
                        _updateNavBarCompact(false);
                      },
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingGlassPillNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDark;
  final bool isCompact;

  const _FloatingGlassPillNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: isCompact ? 64 : 80,
        padding: EdgeInsets.fromLTRB(
          isCompact ? 28 : 16,
          0,
          isCompact ? 28 : 16,
          isCompact ? 8 : 10,
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(maxWidth: isCompact ? 320 : 440),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: isCompact ? 50 : 66,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 6,
                    vertical: isCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(38),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF252C3A).withValues(alpha: 0.58),
                              const Color(0xFF0F131D).withValues(alpha: 0.42),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.68),
                              Colors.white.withValues(alpha: 0.38),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.24)
                          : Colors.white.withValues(alpha: 0.78),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        label: 'Overview',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.inventory_2_outlined,
                        selectedIcon: Icons.inventory_2_rounded,
                        label: 'Inventory',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.people_alt_outlined,
                        selectedIcon: Icons.people_alt_rounded,
                        label: 'Staff',
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.receipt_long_outlined,
                        selectedIcon: Icons.receipt_long_rounded,
                        label: 'Sales',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF0F172A);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onItemSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 4 : 5,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.65))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: isCompact ? 22 : 21,
                color: isSelected ? activeColor : inactiveColor,
              ),
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      letterSpacing: 0.1,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: isCompact
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primaryLight
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primaryDark)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
