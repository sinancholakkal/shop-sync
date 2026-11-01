import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/staff_pending_approval_screen.dart';
import 'package:shop_sync_app/shared/cubit/shop_sync_cubit.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class StaffDetailsInputScreen extends StatefulWidget {
  final String scannedShopId;
  final String shopName;

  const StaffDetailsInputScreen({
    super.key,
    required this.scannedShopId,
    required this.shopName,
  });

  @override
  State<StaffDetailsInputScreen> createState() => _StaffDetailsInputScreenState();
}

class _StaffDetailsInputScreenState extends State<StaffDetailsInputScreen> {
  // Start with clean, empty inputs so staff member fills in their real profile
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController(text: 'Floor Staff / Cashier');
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _nameError = name.isEmpty
          ? 'Please enter your full name'
          : (name.length < 2 ? 'Name must be at least 2 characters' : null);

      if (email.isEmpty) {
        _emailError = 'Please enter your email address';
      } else {
        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
        _emailError = emailRegex.hasMatch(email) ? null : 'Please enter a valid email address';
      }
    });

    if (_nameError != null || _emailError != null) {
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isLoading = false);
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final newStaff = appState.addStaffMemberFromQR(
          name: name,
          email: email,
          shopId: widget.scannedShopId,
          shopName: widget.shopName,
        );
        try {
          context.read<ShopSyncCubit?>()?.syncStaffMemberFromQR(
            newStaff,
            shopName: widget.shopName,
          );
        } catch (_) {}

        // Navigate to the Pending Approval screen and pop prior scanner screens
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => StaffPendingApprovalScreen(
              staffId: newStaff.id,
              staffName: newStaff.name,
              scannedShopId: widget.scannedShopId,
              shopName: widget.shopName,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Staff Registration',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Linked Shop Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shopName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Shop ID: ${widget.scannedShopId}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.accentEmerald),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Enter Staff Identity Details',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Provide your details to submit your onboarding application to the shop owner.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Full Name *',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    onChanged: (val) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Jordan Brooks',
                      prefixIcon: const Icon(Icons.person_rounded),
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email Address *',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. jordan.b@company.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Requested Role / Department',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cashier / Floor Staff',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlowingGlassButton(
                    isLoading: _isLoading,
                    onPressed: _submitRegistration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Submit for Owner Approval',
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
