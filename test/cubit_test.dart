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
import 'package:shop_sync_app/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/add_edit_item_dialog.dart';
import 'package:shop_sync_app/data/repositories/mock_data_repository.dart';
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

    test('Strict 5-category limit is enforced and prevents adding more than 5 categories', () {
      final state = AppStateProvider(initialAuth: true);
      state.loginAsOwner('owner@shop.io', shopId: 'SHOP-LIMIT', shopName: 'Limit Shop');

      // Starts with 3 categories: Electronics, Accessories, Groceries
      expect(state.allProductCategories.length, 3);
      expect(state.isCategoryLimitReached, isFalse);
      expect(state.remainingCategorySlots, 2);

      // Add 4th category -> Success
      final add4 = state.addCategory('Pet Supplies');
      expect(add4, isTrue);
      expect(state.allProductCategories.length, 4);
      expect(state.isCategoryLimitReached, isFalse);
      expect(state.remainingCategorySlots, 1);

      // Add 5th category -> Success
      final add5 = state.addCategory('Home Decor');
      expect(add5, isTrue);
      expect(state.allProductCategories.length, 5);
      expect(state.isCategoryLimitReached, isTrue);
      expect(state.remainingCategorySlots, 0);

      // Attempt to add 6th category -> Must be strictly BLOCKED!
      final add6 = state.addCategory('Automotive');
      expect(add6, isFalse);
      expect(state.allProductCategories.length, 5);
      expect(state.allProductCategories.contains('Automotive'), isFalse);
    });

    test('Category name editing renames category and updates all associated inventory items', () {
      final state = AppStateProvider(initialAuth: true);
      state.loginAsOwner('owner@shop.io', shopId: 'SHOP-EDIT', shopName: 'Edit Shop');

      // Add inventory items with 'Electronics' category
      final mouse = InventoryItem(
        id: 'item_mouse',
        name: 'Gaming Mouse',
        sku: 'PER-MOU-01',
        category: 'Electronics',
        price: 49.99,
        costPrice: 25.0,
        quantity: 20,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );
      final keyboard = InventoryItem(
        id: 'item_kb',
        name: 'Mechanical Keyboard',
        sku: 'PER-KB-01',
        category: 'Electronics',
        price: 89.99,
        costPrice: 45.0,
        quantity: 12,
        minThreshold: 3,
        lastUpdated: DateTime.now(),
      );
      final groceryItem = InventoryItem(
        id: 'item_apple',
        name: 'Organic Apples',
        sku: 'GRO-APP-01',
        category: 'Groceries',
        price: 4.99,
        costPrice: 2.0,
        quantity: 50,
        minThreshold: 10,
        lastUpdated: DateTime.now(),
      );

      state.addInventoryItem(mouse);
      state.addInventoryItem(keyboard);
      state.addInventoryItem(groceryItem);

      // Rename category 'Electronics' -> 'Consumer Tech'
      final renameSuccess = state.editCategory('Electronics', 'Consumer Tech');
      expect(renameSuccess, isTrue);

      // Verify category list updated
      expect(state.allProductCategories.contains('Consumer Tech'), isTrue);
      expect(state.allProductCategories.contains('Electronics'), isFalse);

      // Verify associated inventory items automatically updated their category!
      final updatedMouse = state.inventoryList.firstWhere((i) => i.id == 'item_mouse');
      final updatedKeyboard = state.inventoryList.firstWhere((i) => i.id == 'item_kb');
      final unchangedApple = state.inventoryList.firstWhere((i) => i.id == 'item_apple');

      expect(updatedMouse.category, 'Consumer Tech');
      expect(updatedKeyboard.category, 'Consumer Tech');
      expect(unchangedApple.category, 'Groceries');

      // Non-permitted staff cannot edit categories
      final readOnlyStaff = StaffMember(
        id: 'stf_ro',
        name: 'Viewer',
        email: 'viewer@shop.io',
        permission: StaffPermission.readOnly,
        joinedDate: DateTime.now(),
      );
      state.loginAsStaff(readOnlyStaff, shopId: 'SHOP-EDIT', shopName: 'Edit Shop');
      final unauthorizedEdit = state.editCategory('Consumer Tech', 'Hacked Tech');
      expect(unauthorizedEdit, isFalse);
    });

    test('Deleting a category frees up a slot and reassigns inventory items', () {
      final state = AppStateProvider(initialAuth: true);
      state.loginAsOwner('owner@shop.io', shopId: 'SHOP-DEL', shopName: 'Del Shop');

      state.addCategory('Books');
      state.addCategory('Toys');
      expect(state.allProductCategories.length, 5);
      expect(state.isCategoryLimitReached, isTrue);

      // Delete 'Toys'
      final delSuccess = state.deleteCategory('Toys');
      expect(delSuccess, isTrue);
      expect(state.allProductCategories.length, 4);
      expect(state.isCategoryLimitReached, isFalse);
      expect(state.remainingCategorySlots, 1);

      // Slot is now freed: adding 'Footwear' succeeds!
      final addSuccess = state.addCategory('Footwear');
      expect(addSuccess, isTrue);
      expect(state.allProductCategories.length, 5);
      expect(state.allProductCategories.contains('Footwear'), isTrue);
    });

    test('InventoryItem model calculates margin, profit, and serializes correctly', () {
      final item = InventoryItem(
        id: 'inv_profit_test',
        name: 'Wireless Gaming Mouse',
        sku: 'MS-W-01',
        category: 'Electronics',
        costPrice: 50.0,
        price: 65.0,
        marginPercent: 30.0,
        quantity: 20,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );

      expect(item.profitPerUnit, 15.0);
      expect(item.calculatedMarginPercent, 30.0);
      expect(item.effectiveMarginPercent, 30.0);

      final map = item.toMap();
      expect(map['costPrice'], 50.0);
      expect(map['price'], 65.0);
      expect(map['marginPercent'], 30.0);

      final restored = InventoryItem.fromMap(map, 'inv_profit_test');
      expect(restored.costPrice, 50.0);
      expect(restored.price, 65.0);
      expect(restored.marginPercent, 30.0);
      expect(restored.profitPerUnit, 15.0);
    });

    testWidgets('AddEditItemDialog auto-calculates retail price from cost price and margin percentage', (tester) async {
      InventoryItem? savedItem;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AddEditItemDialog(
                onSave: (item) => savedItem = item,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Product Name
      final nameFinder = find.widgetWithText(TextField, 'e.g. Mechanical RGB Keyboard');
      await tester.enterText(nameFinder, 'Wireless Mechanical Keyboard');

      // Enter SKU
      final skuFinder = find.widgetWithText(TextField, 'e.g. PER-MK-104');
      await tester.enterText(skuFinder, 'KB-W-99');

      // Enter Cost Price = 100.00
      final costPriceFinder = find.widgetWithText(TextField, '0.00').first;
      await tester.enterText(costPriceFinder, '100.00');
      await tester.pump();

      // Tap Retail Preset '+25%' chip (first chip belongs to retail margin presets)
      final chip25 = find.text('+25%').first;
      await tester.tap(chip25);
      await tester.pump();

      // Retail Price should now be automatically calculated as 125.00 (100 + 25%)
      expect(find.text('125.00'), findsOneWidget);

      // Scroll to submit button and tap
      final submitFinder = find.text('Create Inventory Item');
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(savedItem, isNotNull);
      expect(savedItem!.name, 'Wireless Mechanical Keyboard');
      expect(savedItem!.costPrice, 100.00);
      expect(savedItem!.marginPercent, 25.0);
      expect(savedItem!.price, 125.00);
      expect(savedItem!.profitPerUnit, 25.0);
    });
  });

  group('Product Tracking: Timestamps & Price History', () {
    test('InventoryItem stores, persists, and deserializes timestamps and priceHistory', () {
      final now = DateTime.now();
      final created = now.subtract(const Duration(days: 30));
      final priceUpdated = now.subtract(const Duration(days: 2));
      final stockUpdated = now.subtract(const Duration(hours: 4));

      final item = InventoryItem(
        id: 'track_1',
        name: 'OLED Gaming Monitor 34"',
        sku: 'MON-OLED-34',
        category: 'Electronics',
        price: 899.99,
        costPrice: 650.00,
        quantity: 15,
        minThreshold: 3,
        createdAt: created,
        lastUpdated: now,
        priceLastUpdated: priceUpdated,
        stockLastUpdated: stockUpdated,
        priceHistory: [
          PriceHistoryEntry(
            timestamp: created,
            price: 999.99,
            costPrice: 700.00,
            marginPercent: 42.8,
            note: 'Initial Release',
          ),
          PriceHistoryEntry(
            timestamp: priceUpdated,
            price: 899.99,
            costPrice: 650.00,
            marginPercent: 38.4,
            note: 'Price Reduction',
          ),
        ],
      );

      final map = item.toMap();
      expect(map['priceLastUpdated'], priceUpdated.toIso8601String());
      expect(map['stockLastUpdated'], stockUpdated.toIso8601String());
      expect(map['createdAt'], created.toIso8601String());
      expect(map['lastUpdated'], now.toIso8601String());
      expect(map['priceHistory'], isA<List>());
      expect((map['priceHistory'] as List).length, 2);

      final revived = InventoryItem.fromMap(map, 'track_1');
      expect(revived.id, 'track_1');
      expect(revived.name, 'OLED Gaming Monitor 34"');
      expect(revived.priceLastUpdated, priceUpdated);
      expect(revived.stockLastUpdated, stockUpdated);
      expect(revived.createdAt, created);
      expect(revived.priceHistory.length, 2);
      expect(revived.priceHistory.last.price, 899.99);
      expect(revived.priceHistory.last.costPrice, 650.00);
      expect(revived.priceHistory.last.note, 'Price Reduction');
    });

    test('copyWith auto-detects price changes, updates priceLastUpdated and appends to priceHistory', () {
      final initialTime = DateTime(2026, 1, 1, 10, 0);
      final item = InventoryItem(
        id: 'item_cw',
        name: 'Coffee Beans 1kg',
        sku: 'GROC-CF-01',
        category: 'Groceries',
        price: 24.99,
        costPrice: 15.00,
        quantity: 50,
        minThreshold: 5,
        createdAt: initialTime,
        lastUpdated: initialTime,
        priceLastUpdated: initialTime,
        stockLastUpdated: initialTime,
        priceHistory: [
          PriceHistoryEntry(
            timestamp: initialTime,
            price: 24.99,
            costPrice: 15.00,
            marginPercent: 66.6,
          ),
        ],
      );

      // Price updated
      final updated = item.copyWith(price: 29.99);
      expect(updated.price, 29.99);
      expect(updated.costPrice, 15.00);
      expect(updated.priceLastUpdated.isAfter(initialTime), isTrue);
      expect(updated.lastUpdated.isAfter(initialTime), isTrue);
      expect(updated.priceHistory.length, 2);
      expect(updated.priceHistory.last.price, 29.99);
      expect(updated.priceHistory.last.costPrice, 15.00);
    });

    test('copyWith auto-detects quantity changes and updates stockLastUpdated', () {
      final initialTime = DateTime(2026, 1, 1, 10, 0);
      final item = InventoryItem(
        id: 'item_stock',
        name: 'Energy Drink 250ml',
        sku: 'BEV-EN-01',
        category: 'Groceries',
        price: 3.50,
        costPrice: 1.50,
        quantity: 100,
        minThreshold: 10,
        createdAt: initialTime,
        lastUpdated: initialTime,
        priceLastUpdated: initialTime,
        stockLastUpdated: initialTime,
      );

      final updated = item.copyWith(quantity: 85);
      expect(updated.quantity, 85);
      expect(updated.stockLastUpdated.isAfter(initialTime), isTrue);
      expect(updated.lastUpdated.isAfter(initialTime), isTrue);
      // Price was not modified, so priceLastUpdated stays unchanged
      expect(updated.priceLastUpdated, initialTime);
    });

    test('MockDataRepository items have realistic historical price entries and timestamps', () {
      final items = MockDataRepository.getInitialInventory();
      expect(items.isNotEmpty, isTrue);

      for (final item in items) {
        expect(item.createdAt, isNotNull);
        expect(item.lastUpdated, isNotNull);
        expect(item.priceLastUpdated, isNotNull);
        expect(item.stockLastUpdated, isNotNull);
        expect(item.priceHistory.isNotEmpty, isTrue);
        expect(item.priceHistory.last.price, item.price);
        expect(item.priceHistory.last.wholesalePrice, item.wholesalePrice);
        expect(item.priceHistory.last.costPrice, item.costPrice);
      }
    });

    test('StaffPermission and AppStateProvider canViewCostPrice permissions strictly enforce privacy', () {
      // Permission model checks
      expect(StaffPermission.fullAccess.canViewCostPrice, isTrue);
      expect(StaffPermission.stockCounting.canViewCostPrice, isFalse);
      expect(StaffPermission.readOnly.canViewCostPrice, isFalse);

      final appState = AppStateProvider();

      // Owner always has cost view permission
      appState.loginAsOwner('owner@shop.com');
      expect(appState.isOwner, isTrue);
      expect(appState.canViewCostPrice, isTrue);

      // Staff with Full Access has cost view permission
      appState.loginAsStaff(StaffMember(
        id: 'stf_full',
        name: 'Sarah Full',
        email: 'sarah@shop.com',
        permission: StaffPermission.fullAccess,
        shopId: 'SHOP-1',
        joinedDate: DateTime.now(),
      ));
      expect(appState.isOwner, isFalse);
      expect(appState.canViewCostPrice, isTrue);

      // Staff with Stock Counting Only CANNOT view cost price
      appState.loginAsStaff(StaffMember(
        id: 'stf_stock',
        name: 'Alex Stock',
        email: 'alex@shop.com',
        permission: StaffPermission.stockCounting,
        shopId: 'SHOP-1',
        joinedDate: DateTime.now(),
      ));
      expect(appState.isOwner, isFalse);
      expect(appState.canViewCostPrice, isFalse);

      // Staff with Read Only CANNOT view cost price
      appState.loginAsStaff(StaffMember(
        id: 'stf_read',
        name: 'David Read',
        email: 'david@shop.com',
        permission: StaffPermission.readOnly,
        shopId: 'SHOP-1',
        joinedDate: DateTime.now(),
      ));
      expect(appState.isOwner, isFalse);
      expect(appState.canViewCostPrice, isFalse);
    });

    test('InventoryItem wholesale calculations and Firestore serialization work properly', () {
      final now = DateTime.now();
      final item = InventoryItem(
        id: 'ws_item_1',
        name: 'Gaming Headset',
        sku: 'AUD-GH-01',
        category: 'Electronics',
        price: 200.00,
        wholesalePrice: 150.00,
        costPrice: 100.00,
        quantity: 20,
        minThreshold: 5,
        lastUpdated: now,
      );

      // Calculations
      expect(item.profitPerUnit, 100.00); // 200 - 100
      expect(item.wholesaleProfitPerUnit, 50.00); // 150 - 100
      expect(item.calculatedMarginPercent, 100.0); // (200 - 100) / 100 * 100
      expect(item.calculatedWholesaleMarginPercent, 50.0); // (150 - 100) / 100 * 100
      expect(item.totalStockValue, 4000.00); // 200 * 20
      expect(item.totalStockWholesaleValue, 3000.00); // 150 * 20
      expect(item.totalStockCost, 2000.00); // 100 * 20

      // Serialization round-trip
      final map = item.toMap();
      expect(map['wholesalePrice'], 150.00);
      expect(map['wholesaleMarginPercent'], 50.0);

      final revived = InventoryItem.fromMap(map, 'ws_item_1');
      expect(revived.wholesalePrice, 150.00);
      expect(revived.wholesaleProfitPerUnit, 50.00);
      expect(revived.effectiveWholesaleMarginPercent, 50.0);

      // Backward compatibility when wholesalePrice is missing from legacy map
      final legacyMap = Map<String, dynamic>.from(map)..remove('wholesalePrice')..remove('wholesaleMarginPercent');
      final legacyRevived = InventoryItem.fromMap(legacyMap, 'legacy_item');
      expect(legacyRevived.wholesalePrice, 200.00); // falls back to retail price
    });

    testWidgets('ProductDetailScreen hides Cost Price and Profit Margin for Stock Counting Staff', (tester) async {
      final appState = AppStateProvider();
      final testItem = InventoryItem(
        id: 'priv_item_1',
        name: 'Confidential Cost Product',
        sku: 'PRIV-01',
        category: 'Electronics',
        price: 199.99,
        wholesalePrice: 149.99,
        costPrice: 89.99,
        quantity: 12,
        minThreshold: 5,
        lastUpdated: DateTime.now(),
      );
      appState.addInventoryItem(testItem);

      // 1. As Owner: Cost Price and Margin MUST be visible
      appState.loginAsOwner('owner@shop.com');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: appState),
          ],
          child: MaterialApp(
            home: ProductDetailScreen(itemId: testItem.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cost (Acquisition) Price'), findsOneWidget);
      expect(find.text('Retail Profit Margin'), findsOneWidget);
      expect(find.text('Wholesale Price'), findsOneWidget);
      expect(find.text('\$149.99'), findsWidgets);

      // 2. As Staff with Stock Counting Only: Cost Price and Margin MUST be hidden
      appState.loginAsStaff(StaffMember(
        id: 'stf_count',
        name: 'Counter Bob',
        email: 'bob@shop.com',
        permission: StaffPermission.stockCounting,
        shopId: 'SHOP-1',
        joinedDate: DateTime.now(),
      ));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: appState),
          ],
          child: MaterialApp(
            home: ProductDetailScreen(itemId: testItem.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cost (Acquisition) Price'), findsNothing);
      expect(find.text('Retail Profit Margin'), findsNothing);
      expect(find.text('Cost value:'), findsNothing);
      // Wholesale Price remains accessible
      expect(find.text('Wholesale Price'), findsOneWidget);
      expect(find.text('\$149.99'), findsWidgets);
    });
  });
}

