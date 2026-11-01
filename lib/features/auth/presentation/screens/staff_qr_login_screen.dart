import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/services/firestore_service.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';
import 'staff_details_input_screen.dart';

class StaffQrLoginScreen extends StatefulWidget {
  const StaffQrLoginScreen({super.key});

  @override
  State<StaffQrLoginScreen> createState() => _StaffQrLoginScreenState();
}

class _StaffQrLoginScreenState extends State<StaffQrLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  MobileScannerController? _scannerController;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _hasScanned = false;
  bool _isProcessing = false;

  bool get _isTesting {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (!_isTesting) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  String _extractShopId(String raw) {
    try {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.queryParameters.containsKey('shop')) {
        return uri.queryParameters['shop']!;
      }
    } catch (_) {}
    if (raw.contains('shop=')) {
      final parts = raw.split('shop=');
      if (parts.length > 1) {
        return parts[1].split('&').first;
      }
    }
    return raw.trim();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _hasScanned = true;
          _isProcessing = true;
        });
        await _processScannedCode(code);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String rawCode) async {
    try {
      await _scannerController?.stop();
    } catch (_) {}

    if (!mounted) return;

    final shopId = _extractShopId(rawCode);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    String resolvedName = 'Shop $shopId';

    try {
      final shop = await FirestoreService.instance.getShop(shopId);
      if (shop != null && shop['name'] != null) {
        resolvedName = shop['name'] as String;
      } else if (appState.shopId.toUpperCase() == shopId.toUpperCase() && appState.shopName.isNotEmpty) {
        resolvedName = appState.shopName;
      }
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.accentEmerald,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scanned: $resolvedName ($shopId)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffDetailsInputScreen(
          scannedShopId: shopId,
          shopName: resolvedName,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _hasScanned = false;
        _isProcessing = false;
      });
      try {
        await _scannerController?.start();
      } catch (_) {}
    }
  }

  void _proceedWithScannedData() async {
    try {
      await _scannerController?.stop();
    } catch (_) {}

    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffDetailsInputScreen(
          scannedShopId: appState.shopId,
          shopName: appState.shopName,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _hasScanned = false;
        _isProcessing = false;
      });
      try {
        await _scannerController?.start();
      } catch (_) {}
    }
  }

  void _openManualShopIdDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        bool isChecking = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Enter Shop ID Manually',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask your shop owner for their unique Shop ID code.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. SHOP-SYNC-XXXX',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isChecking
                      ? null
                      : () async {
                          final code = controller.text.trim().toUpperCase();
                          if (code.isEmpty) return;

                          setDialogState(() => isChecking = true);
                          final currentShopId = Provider.of<AppStateProvider>(context, listen: false).shopId;
                          final currentShopName = Provider.of<AppStateProvider>(context, listen: false).shopName;
                          String resolvedName = 'Shop $code';

                          try {
                            final shop = await FirestoreService.instance.getShop(code);
                            if (shop != null && shop['name'] != null) {
                              resolvedName = shop['name'] as String;
                            } else if (currentShopId.toUpperCase() == code && currentShopName.isNotEmpty) {
                              resolvedName = currentShopName;
                            }
                          } catch (_) {}

                          if (ctx.mounted) {
                            Navigator.pop(ctx, {'shopId': code, 'shopName': resolvedName});
                          }
                        },
                  child: isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Join Shop',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      try {
        await _scannerController?.stop();
      } catch (_) {}
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StaffDetailsInputScreen(
            scannedShopId: result['shopId']!,
            shopName: result['shopName']!,
          ),
        ),
      );
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _isProcessing = false;
        });
        try {
          await _scannerController?.start();
        } catch (_) {}
      }
    }
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
          'Staff QR Onboarding',
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Step 1 of 2: Scan Owner Code',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Point Camera at Owner\'s QR Code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan the dynamic rotating QR code displayed on the shop owner\'s dashboard.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Scanner Viewport Box with Live Camera Preview
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isTesting)
                            Container(
                              color: isDark ? Colors.black45 : Colors.black12,
                              child: Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 110,
                                  color: isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                            )
                          else
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) {
                                return Container(
                                  color: Colors.black87,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.videocam_off_rounded,
                                        color: Colors.amber,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Camera Inactive / Denied',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Please allow camera permission or use manual ID entry below.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Animated scanning laser line
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 20 + (220 * _scanAnimation.value),
                                left: 20,
                                right: 20,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.secondary,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondary.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Corner brackets
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _CornerBracket(isTop: true, isLeft: true),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _CornerBracket(isTop: true, isLeft: false),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: _CornerBracket(isTop: false, isLeft: true),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: _CornerBracket(isTop: false, isLeft: false),
                          ),

                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Camera Control Actions (Flashlight & Camera Flip)
                  if (!_isTesting) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          tooltip: _isFlashOn ? 'Turn Flashlight Off' : 'Turn Flashlight On',
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            size: 20,
                            color: _isFlashOn ? Colors.amber : null,
                          ),
                          onPressed: () {
                            _scannerController?.toggleTorch();
                            setState(() => _isFlashOn = !_isFlashOn);
                          },
                        ),
                        const SizedBox(width: 14),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          tooltip: 'Switch Camera',
                          icon: const Icon(Icons.flip_camera_ios_rounded, size: 20),
                          onPressed: () {
                            _scannerController?.switchCamera();
                            setState(() => _isFrontCamera = !_isFrontCamera);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    const SizedBox(height: 18),
                  ],

                  GlowingGlassButton(
                    onPressed: _proceedWithScannedData,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Scan Verified QR Code',
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

                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppStateProvider>(context);
                      return Text(
                        'Detected: ${appState.shopName} (${appState.shopId})',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.accentEmerald,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openManualShopIdDialog,
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 16, color: AppColors.secondary),
                    label: Text(
                      'Enter Shop ID Manually',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
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

class _CornerBracket extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerBracket({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.secondary, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.secondary, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.secondary, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.secondary, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
