import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/services/firestore_service.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/dashboard/presentation/screens/app_shell.dart';
import 'package:shop_sync_app/features/staff/domain/models/staff_model.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class StaffPendingApprovalScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String shopName;
  final String scannedShopId;

  const StaffPendingApprovalScreen({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.shopName,
    this.scannedShopId = 'SHOP-SYNC-8821',
  });

  @override
  State<StaffPendingApprovalScreen> createState() => _StaffPendingApprovalScreenState();
}

class _StaffPendingApprovalScreenState extends State<StaffPendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isChecking = false;
  bool _hasNavigated = false;
  StreamSubscription<StaffMember?>? _staffDocSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenToApprovalStream();
  }

  void _listenToApprovalStream() {
    if (widget.scannedShopId.isEmpty || widget.staffId.isEmpty) return;
    _staffDocSub = FirestoreService.instance
        .streamStaffMember(widget.scannedShopId, widget.staffId)
        .listen((staff) {
      if (staff != null && staff.isApproved && !_hasNavigated) {
        _handleApproved(staff);
      }
    });
  }

  @override
  void dispose() {
    _staffDocSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleApproved(StaffMember approvedStaff) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.loginAsStaff(
      approvedStaff,
      shopId: widget.scannedShopId,
      shopName: widget.shopName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.accentEmerald,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Approval Granted! Accessing ${widget.shopName}...',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  Future<void> _checkStatus() async {
    if (_isChecking || _hasNavigated) return;
    setState(() => _isChecking = true);

    try {
      // 1. Direct Firestore fetch
      final firestoreStaff = await FirestoreService.instance
          .getStaffMember(widget.scannedShopId, widget.staffId);

      if (firestoreStaff != null && firestoreStaff.isApproved) {
        if (mounted) setState(() => _isChecking = false);
        _handleApproved(firestoreStaff);
        return;
      }

      // 2. In-memory check in AppStateProvider
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final found = appState.staffList.firstWhere(
          (s) => (s.id == widget.staffId || s.name == widget.staffName) && s.isApproved,
          orElse: () => StaffMember(
            id: '',
            name: '',
            email: '',
            permission: StaffPermission.readOnly,
            isActive: false,
            isApproved: false,
            joinedDate: DateTime.now(),
            shopId: '',
          ),
        );

        if (found.id.isNotEmpty && found.isApproved) {
          setState(() => _isChecking = false);
          _handleApproved(found);
          return;
        }
      }

      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still awaiting shop owner approval. Please ask owner to review and approve your access.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);

    // Auto-navigate if approved via live stream or state
    final approvedStaff = appState.staffList.firstWhere(
      (s) => (s.id == widget.staffId || s.name == widget.staffName) && s.isApproved,
      orElse: () => StaffMember(
        id: '',
        name: '',
        email: '',
        permission: StaffPermission.readOnly,
        isActive: false,
        isApproved: false,
        joinedDate: DateTime.now(),
        shopId: '',
      ),
    );

    if (approvedStaff.id.isNotEmpty && approvedStaff.isApproved && !_hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleApproved(approvedStaff);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient orbs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Pending Icon
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orangeAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Approval Required',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Your registration request has been submitted for verification.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Staff & Shop Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.secondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Applicant: ${widget.staffName}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primaryLight),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Shop: ${widget.shopName}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 18, color: Colors.amber),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Status: Awaiting Owner Review',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'For shop security, new staff members cannot access store inventory or operations until the owner reviews and approves their identity on their dashboard.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      GlowingGlassButton(
                        isLoading: _isChecking,
                        onPressed: _checkStatus,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Check Approval Status',
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

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          appState.logout();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Text(
                          'Cancel & Return to Login',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
