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

  void _showRoleSwitcherDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                        'Switch Active Demo Role',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Experience the app interface and RBAC permissions from different perspectives:',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _RoleOption(
                    title: 'Shop Owner (Admin)',
                    subtitle: 'Full admin rights, staff QR onboarding, staff permissions',
                    isSelected: appState.isOwner,
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      appState.switchDemoRole(UserRole.owner);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _RoleOption(
                    title: 'Staff (Full Access)',
                    subtitle: 'Manage and update products, categories, and inventory',
                    isSelected: !appState.isOwner &&
                        appState.effectivePermission == StaffPermission.fullAccess,
                    icon: Icons.shield_rounded,
                    color: AppColors.accentPurple,
                    onTap: () {
                      appState.switchDemoRole(
                          UserRole.staff, StaffPermission.fullAccess);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _RoleOption(
                    title: 'Staff (Stock Counting)',
                    subtitle: 'Update and adjust quantities only; cannot edit items',
                    isSelected: !appState.isOwner &&
                        appState.effectivePermission == StaffPermission.stockCounting,
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primaryLight,
                    onTap: () {
                      appState.switchDemoRole(
                          UserRole.staff, StaffPermission.stockCounting);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _RoleOption(
                    title: 'Staff (Read-Only)',
                    subtitle: 'Browse stock and transactions with no modification rights',
                    isSelected: !appState.isOwner &&
                        appState.effectivePermission == StaffPermission.readOnly,
                    icon: Icons.visibility_rounded,
                    color: AppColors.secondary,
                    onTap: () {
                      appState.switchDemoRole(
                          UserRole.staff, StaffPermission.readOnly);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
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
                              _showRoleSwitcherDialog(context, appState),
                          child: Row(
                            mainAxisAlignment: isDesktop
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                appState.isOwner
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.badge_rounded,
                                size: 18,
                                color: appState.isOwner
                                    ? AppColors.primaryLight
                                    : AppColors.secondary,
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.isOwner
                                            ? 'Owner View'
                                            : 'Staff: ${appState.effectivePermission.title}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Click to switch role',
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
                                const Icon(Icons.swap_horiz_rounded, size: 16),
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
                                            _showRoleSwitcherDialog(context, appState),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                appState.isOwner ? 'Owner' : 'Staff',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryLight,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(Icons.swap_vert_rounded,
                                                  size: 13, color: AppColors.primaryLight),
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
                if (context.isMobile)
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

class _RoleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
