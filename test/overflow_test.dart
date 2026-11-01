import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_sync_app/core/theme/theme_provider.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_auth_screen.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/owner_dashboard_qr_screen.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/staff_details_input_screen.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/staff_pending_approval_screen.dart';
import 'package:shop_sync_app/features/auth/presentation/screens/staff_qr_login_screen.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/add_edit_item_dialog.dart';
import 'package:shop_sync_app/features/staff/domain/models/staff_model.dart';
import 'package:shop_sync_app/features/staff/presentation/widgets/permission_modal.dart';
import 'package:shop_sync_app/main.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

Widget _buildTestApp({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Zero Overflow Tests Across All Screens & Viewports', () {
    const viewports = [
      Size(320, 568), // Ultra-compact mobile (iPhone SE 1st gen)
      Size(360, 640), // Standard small Android
      Size(390, 844), // Modern iPhone / Android
      Size(768, 1024), // Tablet
      Size(1280, 800), // Desktop Web
    ];

    for (final size in viewports) {
      testWidgets('AppShell tabs no overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final appState = AppStateProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: appState),
            ],
            child: const ShopSyncApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Check Tab 0: Dashboard
        expect(find.byType(ShopSyncApp), findsOneWidget);

        // Switch to Tab 1: Inventory
        appState.setActiveNavIndex(1);
        await tester.pumpAndSettle();
        expect(find.byType(ShopSyncApp), findsOneWidget);

        // Switch to Tab 2: Staff
        appState.setActiveNavIndex(2);
        await tester.pumpAndSettle();
        expect(find.byType(ShopSyncApp), findsOneWidget);

        // Switch to Tab 3: Transactions
        appState.setActiveNavIndex(3);
        await tester.pumpAndSettle();
        expect(find.byType(ShopSyncApp), findsOneWidget);
      });
    }

    testWidgets('OwnerAuthScreen & Email Verification no overflow on ultra-compact mobile (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestApp(child: const OwnerAuthScreen()));
      await tester.pumpAndSettle();

      // Ensure Sign In button is visible
      expect(find.text('Sign In to Dashboard'), findsOneWidget);

      // Switch to Register Shop
      await tester.tap(find.text('Register Shop'));
      await tester.pumpAndSettle();

      // Ensure button is visible & tap Send Verification Link
      await tester.ensureVisible(find.text('Send Verification Link'));
      await tester.tap(find.text('Send Verification Link'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text("I've Verified My Email"), findsOneWidget);
    });

    testWidgets('StaffOnboarding screens no overflow on compact mobile (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Staff QR Scanner Screen (uses repeating animation controller, pump instead of settle)
      await tester.pumpWidget(_buildTestApp(child: const StaffQrLoginScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(StaffQrLoginScreen), findsOneWidget);

      // Staff Details Input Screen
      await tester.pumpWidget(_buildTestApp(
        child: const StaffDetailsInputScreen(
          scannedShopId: 'SHOP-SYNC-8821',
          shopName: 'Apex Retail & Tech Hub',
        ),
      ));
      await tester.pumpAndSettle();

      // Fill in required staff details
      await tester.enterText(find.byType(TextField).at(0), 'Jordan Brooks');
      await tester.enterText(find.byType(TextField).at(1), 'jordan@apexretail.io');
      await tester.pumpAndSettle();

      // Submit registration on staff screen (navigates to screen with repeating pulse animation)
      await tester.ensureVisible(find.text('Submit for Owner Approval'));
      await tester.tap(find.text('Submit for Owner Approval'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StaffPendingApprovalScreen), findsOneWidget);
    });

    testWidgets('OwnerDashboardQrScreen no overflow on compact mobile (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildTestApp(child: const OwnerDashboardQrScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Staff Invitation QR Code'), findsOneWidget);
    });

    testWidgets('PermissionAssignmentModal no overflow on compact mobile (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyStaff = StaffMember(
        id: 'stf_test',
        name: 'Sarah Jenkins With Very Long Name',
        email: 'sarah.jenkins.enterprise@apexretail.io',
        permission: StaffPermission.fullAccess,
        joinedDate: DateTime.now(),
      );

      await tester.pumpWidget(_buildTestApp(
        child: PermissionAssignmentModal(
          staff: dummyStaff,
          onSavePermission: (_) {},
          onToggleStatus: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Manage Staff Permissions'), findsOneWidget);
    });

    testWidgets('AddEditItemDialog no overflow on compact mobile (320x568)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyItem = InventoryItem(
        id: 'inv_test',
        name: 'HyperX Wireless Noise-Cancelling Headphones Pro Edition',
        sku: 'AUD-HX-001',
        category: 'Electronics',
        price: 199.99,
        costPrice: 120.00,
        quantity: 24,
        minThreshold: 10,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(_buildTestApp(
        child: AddEditItemDialog(
          item: dummyItem,
          onSave: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Inventory Product'), findsOneWidget);
    });
  });
}
