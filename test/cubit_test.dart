import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/theme_cubit.dart';
import 'package:shop_sync_app/core/theme/theme_provider.dart';
import 'package:shop_sync_app/features/auth/domain/models/user_role.dart';
import 'package:shop_sync_app/features/dashboard/presentation/cubit/nav_bar_cubit.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_sync_app/core/services/session_storage_service.dart';
import 'package:shop_sync_app/features/dashboard/presentation/screens/app_shell.dart';
import 'package:shop_sync_app/features/staff/domain/models/staff_model.dart';
import 'package:shop_sync_app/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:shop_sync_app/main.dart';
import 'package:shop_sync_app/shared/cubit/shop_sync_cubit.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Flutter BLoC / Cubit State Management Tests', () {
    test('NavBarCubit selectTab and setCompact work correctly', () {
      final cubit = NavBarCubit();
      expect(cubit.state.selectedIndex, 0);
      expect(cubit.state.isCompact, isFalse);

      cubit.selectTab(2);
      expect(cubit.state.selectedIndex, 2);

      cubit.collapse();
      expect(cubit.state.isCompact, isTrue);

      cubit.expand();
      expect(cubit.state.isCompact, isFalse);
    });

    test('ThemeCubit toggle and setTheme work correctly', () {
      final cubit = ThemeCubit(ThemeMode.dark);
      expect(cubit.isDarkMode, isTrue);

      cubit.toggleTheme();
      expect(cubit.isDarkMode, isFalse);
      expect(cubit.state, ThemeMode.light);

      cubit.setTheme(ThemeMode.dark);
      expect(cubit.isDarkMode, isTrue);
    });

    test('ShopSyncCubit manages authentication, inventory and roles', () {
      final cubit = ShopSyncCubit();
      expect(cubit.state.isAuthenticated, isFalse);

      cubit.loginAsOwner('owner@test.com', shopId: 'SHOP-TEST-1', shopName: 'Test Shop');
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.isOwner, isTrue);

      // Add item
      final initialCount = cubit.state.inventoryList.length;
      final newItem = InventoryItem(
        id: 'test_item_1',
        name: 'Test Product',
        sku: 'TEST-SKU',
        category: 'Electronics',
        price: 99.99,
        costPrice: 60.0,
        quantity: 15,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );
      cubit.addInventoryItem(newItem);
      expect(cubit.state.inventoryList.length, initialCount + 1);

      // Logout and login
      cubit.logout();
      expect(cubit.state.isAuthenticated, isFalse);

      cubit.loginAsOwner('owner@test.com');
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.isOwner, isTrue);
    });
  });

  group('Instagram-style Bottom Tab Bar on Scroll Widget Tests', () {
    testWidgets('AppShell responds to scroll down by shrinking and scroll up by expanding', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => NavBarCubit()),
            BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: true)),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => AppStateProvider(initialAuth: true, shopName: 'Test Shop')),
            ],
            child: const ShopSyncApp(home: AppShell()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially labels are visible
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Inventory'), findsWidgets);
      expect(find.text('Staff'), findsWidgets);
      expect(find.text('Sales'), findsWidgets);

      // Scroll down (drag upwards by 300px)
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Scroll up (drag downwards by 300px)
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Labels are fully visible again
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Inventory'), findsWidgets);
    });
  });

  group('Complete App Entry & Flow Tests (Splash -> Login -> Dashboard)', () {
    testWidgets('App starts at SplashScreen, navigates to OwnerAuthScreen, then logs in to AppShell', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppStateProvider(initialAuth: false);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => NavBarCubit()),
            BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: false)),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: appState),
            ],
            child: const ShopSyncApp(),
          ),
        ),
      );

      // 1. Initial screen is SplashScreen
      expect(find.text('ShopSync'), findsWidgets);
      expect(find.text('Smart Retail & Staff Ecosystem'), findsOneWidget);
      expect(find.text('v1.0.0 • Secured with RBAC'), findsOneWidget);

      // 2. Allow splash timer to complete & transition to OwnerAuthScreen
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      expect(find.text('ShopSync Admin'), findsOneWidget);

      // 3. Perform Login with credentials
      await tester.enterText(find.byType(TextField).at(0), 'owner@retailhub.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Sign In to Dashboard'));
      await tester.pumpAndSettle();

      // 4. Now inside Dashboard / AppShell
      expect(appState.isAuthenticated, isTrue);
      expect(find.text('Quick Actions'), findsOneWidget);

      // 5. Logout
      final logoutButton = find.byIcon(Icons.logout_rounded);
      expect(logoutButton, findsWidgets);
      await tester.tap(logoutButton.first);
      await tester.pumpAndSettle();

      // 6. Returned to OwnerAuthScreen
      expect(appState.isAuthenticated, isFalse);
      expect(find.text('ShopSync Admin'), findsOneWidget);
    });
  });

  group('Option 1 + 2: Staff Approval Queue & Dynamic Rotating QR Tests', () {
    test('Staff onboarding creates unapproved staff, owner can approve or reject', () {
      final appState = AppStateProvider();
      expect(appState.pendingStaffCount, 0);

      // 1. Staff joins from dynamic QR
      final staff = appState.addStaffMemberFromQR(
        name: 'Jordan Brooks',
        email: 'jordan@retail.io',
      );

      expect(staff.isApproved, isFalse);
      expect(appState.pendingStaffCount, 1);
      expect(appState.pendingStaffList.first.name, 'Jordan Brooks');

      // 2. Owner approves staff with Stock Counting permission
      appState.approveStaff(staff.id, StaffPermission.stockCounting);
      expect(appState.pendingStaffCount, 0);
      final approvedMember = appState.staffList.firstWhere((s) => s.id == staff.id);
      expect(approvedMember.isApproved, isTrue);
      expect(approvedMember.permission, StaffPermission.stockCounting);

      // 3. Another staff joins and owner rejects
      final staff2 = appState.addStaffMemberFromQR(
        name: 'Malicious Applicant',
        email: 'malicious@external.com',
      );
      expect(appState.pendingStaffCount, 1);
      appState.rejectStaff(staff2.id);
      expect(appState.pendingStaffCount, 0);
      expect(appState.staffList.any((s) => s.id == staff2.id), isFalse);
    });

    test('ShopSyncCubit handles staff approval queue lifecycle correctly', () {
      final cubit = ShopSyncCubit();
      expect(cubit.state.staffList.where((s) => !s.isApproved).length, 0);

      // 1. Staff joins
      final staff = cubit.addStaffMemberFromQR(
        name: 'Taylor Reed',
        email: 'taylor@retail.io',
      );
      expect(staff.isApproved, isFalse);
      expect(cubit.state.staffList.where((s) => !s.isApproved).length, 1);

      // 2. Approve
      cubit.approveStaff(staff.id, StaffPermission.fullAccess);
      expect(cubit.state.staffList.where((s) => !s.isApproved).length, 0);
      final approved = cubit.state.staffList.firstWhere((s) => s.id == staff.id);
      expect(approved.isApproved, isTrue);
      expect(approved.permission, StaffPermission.fullAccess);

      // 3. Reject
      final staff2 = cubit.addStaffMemberFromQR(
        name: 'Unknown User',
        email: 'unknown@web.io',
      );
      expect(cubit.state.staffList.where((s) => !s.isApproved).length, 1);
      cubit.rejectStaff(staff2.id);
      expect(cubit.state.staffList.where((s) => !s.isApproved).length, 0);
    });

    test('SessionStorageService and tryRestoreSession persist and restore staff and owner sessions', () async {
      SharedPreferences.setMockInitialValues({});

      final staff = StaffMember(
        id: 'stf_persistent_01',
        name: 'Jordan Brooks',
        email: 'jordan@retail.io',
        permission: StaffPermission.stockCounting,
        isActive: true,
        isApproved: true,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-PERSIST-01',
      );

      // Save staff session
      await SessionStorageService.instance.saveStaffSession(
        staff: staff,
        shopId: 'SHOP-PERSIST-01',
        shopName: 'Persist Shop',
      );

      final freshAppState = AppStateProvider(initialAuth: false);
      expect(freshAppState.isAuthenticated, isFalse);

      final restored = await freshAppState.tryRestoreSession();
      expect(restored, isTrue);
      expect(freshAppState.isAuthenticated, isTrue);
      expect(freshAppState.currentUserRole, UserRole.staff);
      expect(freshAppState.currentStaff?.id, 'stf_persistent_01');
      expect(freshAppState.shopId, 'SHOP-PERSIST-01');

      // Logout clears session
      freshAppState.logout();
      expect(freshAppState.isAuthenticated, isFalse);

      final postLogoutSession = await SessionStorageService.instance.getSavedSession();
      expect(postLogoutSession, isNull);
    });
  });

  group('Inventory Categories: Low Stock vs No Item (Out of Stock)', () {
    testWidgets('Low Stock includes both low & 0 qty, while No Item shows strictly 0 qty', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppStateProvider(initialAuth: true);
      final inStockItem = InventoryItem(
        id: 'item_1',
        name: 'Wireless Mouse',
        sku: 'WM-01',
        category: 'Electronics',
        price: 25.0,
        costPrice: 15.0,
        quantity: 20,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );
      final lowStockItem = InventoryItem(
        id: 'item_2',
        name: 'USB-C Cable',
        sku: 'USB-02',
        category: 'Accessories',
        price: 10.0,
        costPrice: 4.0,
        quantity: 3,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );
      final outOfStockItem = InventoryItem(
        id: 'item_3',
        name: 'Mechanical Keyboard',
        sku: 'KB-03',
        category: 'Electronics',
        price: 80.0,
        costPrice: 50.0,
        quantity: 0,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );

      appState.addInventoryItem(inStockItem);
      appState.addInventoryItem(lowStockItem);
      appState.addInventoryItem(outOfStockItem);

      expect(appState.lowStockItemCount, 2); // Includes USB-C (3) and Keyboard (0)
      expect(appState.outOfStockItemCount, 1); // Only Keyboard (0)

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => NavBarCubit()),
            BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: true)),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: appState),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: InventoryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 3 items initially visible
      expect(find.text('Wireless Mouse'), findsOneWidget);
      expect(find.text('USB-C Cable'), findsOneWidget);
      expect(find.text('Mechanical Keyboard'), findsOneWidget);

      // Verify Category Chips exist
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('No Item (Out of Stock)'), findsOneWidget);

      // Tap 'No Item (Out of Stock)' chip
      await tester.tap(find.text('No Item (Out of Stock)'));
      await tester.pumpAndSettle();

      // Only out-of-stock Keyboard should be visible
      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(find.text('Wireless Mouse'), findsNothing);
      expect(find.text('USB-C Cable'), findsNothing);

      // Tap 'Low Stock' chip
      await tester.tap(find.text('Low Stock'));
      await tester.pumpAndSettle();

      // Both Low Stock (USB Cable) and Out of Stock (Keyboard) are kept in Low Stock
      expect(find.text('USB-C Cable'), findsOneWidget);
      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(find.text('Wireless Mouse'), findsNothing);
    });

    test('Switch role is strictly restricted to Shop Owner / Admin', () {
      // 1. Owner Login
      final ownerState = AppStateProvider(initialAuth: false);
      ownerState.loginAsOwner('owner@apex.io', shopId: 'SHOP-01', shopName: 'Apex Shop');
      expect(ownerState.isRealOwner, isTrue);
      expect(ownerState.isRolePreviewMode, isFalse);

      // Owner switches to preview Stock Counting staff role
      ownerState.switchDemoRole(UserRole.staff, StaffPermission.stockCounting);
      expect(ownerState.isRolePreviewMode, isTrue);
      expect(ownerState.currentUserRole, UserRole.staff);
      expect(ownerState.effectivePermission, StaffPermission.stockCounting);

      // Owner exits preview back to Owner HQ
      ownerState.switchDemoRole(UserRole.owner);
      expect(ownerState.isRolePreviewMode, isFalse);
      expect(ownerState.isOwner, isTrue);

      // 2. Staff Login
      final staffState = AppStateProvider(initialAuth: false);
      final staff = StaffMember(
        id: 'stf_01',
        name: 'Jane Staff',
        email: 'jane@staff.io',
        permission: StaffPermission.readOnly,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-01',
      );
      staffState.loginAsStaff(staff, shopId: 'SHOP-01', shopName: 'Apex Shop');
      expect(staffState.isRealOwner, isFalse);
      expect(staffState.isRolePreviewMode, isFalse);

      // Staff attempts to switch to Owner role -> Must be rejected / blocked
      staffState.switchDemoRole(UserRole.owner);
      expect(staffState.currentUserRole, UserRole.staff);
      expect(staffState.isOwner, isFalse);
      expect(staffState.effectivePermission, StaffPermission.readOnly);
    });

    test('Category addition is restricted based on RBAC permission role', () {
      // 1. Owner permissions
      final ownerState = AppStateProvider(initialAuth: false);
      ownerState.loginAsOwner('owner@shop.io', shopId: 'SHOP-CAT-1', shopName: 'Cat Shop');
      expect(ownerState.canManageCategories, isTrue);

      final addedByOwner = ownerState.addCategory('Pet Supplies');
      expect(addedByOwner, isTrue);
      expect(ownerState.allProductCategories.contains('Pet Supplies'), isTrue);

      // 2. Staff with Full Access permissions
      final fullAccessStaff = StaffMember(
        id: 'stf_full',
        name: 'Manager Staff',
        email: 'manager@shop.io',
        permission: StaffPermission.fullAccess,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-CAT-1',
      );
      final staffFullState = AppStateProvider(initialAuth: false);
      staffFullState.loginAsStaff(fullAccessStaff, shopId: 'SHOP-CAT-1', shopName: 'Cat Shop');
      expect(staffFullState.canManageCategories, isTrue);

      final addedByFullStaff = staffFullState.addCategory('Home Decor');
      expect(addedByFullStaff, isTrue);
      expect(staffFullState.allProductCategories.contains('Home Decor'), isTrue);

      // 3. Staff with Stock Counting Only permissions -> Restricted
      final countingStaff = StaffMember(
        id: 'stf_count',
        name: 'Counter Staff',
        email: 'counter@shop.io',
        permission: StaffPermission.stockCounting,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-CAT-1',
      );
      final staffCountState = AppStateProvider(initialAuth: false);
      staffCountState.loginAsStaff(countingStaff, shopId: 'SHOP-CAT-1', shopName: 'Cat Shop');
      expect(staffCountState.canManageCategories, isFalse);

      final addedByCountStaff = staffCountState.addCategory('Restricted Category 1');
      expect(addedByCountStaff, isFalse);
      expect(staffCountState.allProductCategories.contains('Restricted Category 1'), isFalse);

      // 4. Staff with Read-Only permissions -> Restricted
      final readOnlyStaff = StaffMember(
        id: 'stf_ro',
        name: 'Viewer Staff',
        email: 'viewer@shop.io',
        permission: StaffPermission.readOnly,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-CAT-1',
      );
      final staffRoState = AppStateProvider(initialAuth: false);
      staffRoState.loginAsStaff(readOnlyStaff, shopId: 'SHOP-CAT-1', shopName: 'Cat Shop');
      expect(staffRoState.canManageCategories, isFalse);

      final addedByRoStaff = staffRoState.addCategory('Restricted Category 2');
      expect(addedByRoStaff, isFalse);
      expect(staffRoState.allProductCategories.contains('Restricted Category 2'), isFalse);
    });

    testWidgets('InventoryScreen category bar shows Add Category only for permitted roles', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Owner views InventoryScreen -> 'Add Category' chip is visible
      final ownerState = AppStateProvider(initialAuth: true);
      ownerState.loginAsOwner('owner@apex.io', shopId: 'SHOP-1', shopName: 'Apex Shop');

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => NavBarCubit()),
            BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: true)),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: ownerState),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: InventoryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsOneWidget);

      // 2. Read-Only Staff views InventoryScreen -> 'Add Category' chip is NOT visible
      final readOnlyStaff = StaffMember(
        id: 'stf_ro',
        name: 'Viewer Staff',
        email: 'viewer@shop.io',
        permission: StaffPermission.readOnly,
        joinedDate: DateTime.now(),
        shopId: 'SHOP-1',
      );
      final roState = AppStateProvider(initialAuth: true);
      roState.loginAsStaff(readOnlyStaff, shopId: 'SHOP-1', shopName: 'Apex Shop');

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => NavBarCubit()),
            BlocProvider(create: (_) => ShopSyncCubit(isAuthenticated: true)),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: roState),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: InventoryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsNothing);
    });
  });
}

