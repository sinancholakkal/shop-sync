import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../core/services/session_storage_service.dart';
import '../../features/staff/domain/models/staff_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

class AppStateProvider extends ChangeNotifier {
  // Authentication & Session
  bool _isAuthenticated;
  UserRole _currentUserRole = UserRole.owner;
  String _ownerEmail = '';
  String _shopId = '';
  String _shopName = '';
  StaffMember? _currentStaff;

  // Domain Data Lists - Clean, real records (no dummy/mock data)
  List<StaffMember> _staffList = [];
  List<InventoryItem> _inventoryList = [];
  List<ShopTransaction> _transactionList = [];

  // Category limits & defaults
  static const int maxCategoryLimit = 5;
  static const List<String> defaultProductCategories = [
    'Electronics',
    'Accessories',
    'Groceries',
  ];

  // Active product categories list (capped at maxCategoryLimit = 5)
  List<String> _categories = [
    'Electronics',
    'Accessories',
    'Groceries',
  ];

  // Active navigation index in app shell
  int _activeNavIndex = 0;
  String _inventoryFilterCategory = 'All';

  // Real-time Firestore Stream Subscriptions
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<StaffMember>>? _staffSubscription;
  StreamSubscription<List<ShopTransaction>>? _transactionSubscription;
  StreamSubscription<List<String>>? _categoriesSubscription;

  AppStateProvider({
    bool initialAuth = false,
    String? shopId,
    String? shopName,
    String? ownerEmail,
  })  : _isAuthenticated = initialAuth,
        _shopId = shopId ?? '',
        _shopName = shopName ?? '',
        _ownerEmail = ownerEmail ?? '' {
    if (_isAuthenticated && _shopId.isNotEmpty) {
      _bindFirestoreStreams(_shopId);
    }
  }

  void _bindFirestoreStreams(String targetShopId) {
    _cancelFirestoreStreams();
    if (targetShopId.isEmpty) return;

    try {
      _inventorySubscription = FirestoreService.instance
          .streamInventory(targetShopId)
          .listen((items) {
        _inventoryList = items;
        notifyListeners();
      }, onError: (err) {
        debugPrint('AppStateProvider: Inventory stream error: $err');
      });

      _staffSubscription = FirestoreService.instance
          .streamStaff(targetShopId)
          .listen((staff) {
        _staffList = staff;
        if (_currentStaff != null) {
          final matching = staff.where((s) => s.id == _currentStaff!.id);
          _currentStaff = matching.isNotEmpty ? matching.first : null;
        }
        notifyListeners();
      }, onError: (err) {
        debugPrint('AppStateProvider: Staff stream error: $err');
      });

      _transactionSubscription = FirestoreService.instance
          .streamTransactions(targetShopId)
          .listen((txs) {
        _transactionList = txs;
        notifyListeners();
      }, onError: (err) {
        debugPrint('AppStateProvider: Transaction stream error: $err');
      });

      _categoriesSubscription = FirestoreService.instance
          .streamCategories(targetShopId)
          .listen((cats) {
        if (cats.isNotEmpty) {
          final list = <String>[];
          for (final c in cats) {
            final trimmed = c.trim();
            if (trimmed.isNotEmpty && !list.any((x) => x.toLowerCase() == trimmed.toLowerCase())) {
              list.add(trimmed);
              if (list.length >= maxCategoryLimit) break;
            }
          }
          if (list.isNotEmpty) {
            _categories = list;
            notifyListeners();
          }
        }
      }, onError: (err) {
        debugPrint('AppStateProvider: Categories stream error: $err');
      });
    } catch (e) {
      debugPrint('AppStateProvider: _bindFirestoreStreams notice: $e');
    }
  }

  void _cancelFirestoreStreams() {
    _inventorySubscription?.cancel();
    _inventorySubscription = null;
    _staffSubscription?.cancel();
    _staffSubscription = null;
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
  }

  Future<void> refreshAllData() async {
    _bindFirestoreStreams(_shopId);
    await Future.delayed(const Duration(milliseconds: 600));
    notifyListeners();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  UserRole get currentUserRole => _currentUserRole;
  bool get isOwner => _currentUserRole == UserRole.owner;
  String get ownerEmail => _ownerEmail;
  String get shopId => _shopId;
  String get shopName => _shopName;
  StaffMember? get currentStaff => _currentStaff;
  int get activeNavIndex => _activeNavIndex;
  String get inventoryFilterCategory => _inventoryFilterCategory;

  /// Whether current session was authenticated as a Shop Owner / Admin
  bool get isRealOwner => _ownerEmail.isNotEmpty;

  /// Whether the Shop Owner is currently testing/previewing a Staff role
  bool get isRolePreviewMode => isRealOwner && _currentUserRole == UserRole.staff;

  void setInventoryFilterCategory(String category) {
    _inventoryFilterCategory = category;
    notifyListeners();
  }

  List<StaffMember> get staffList => List.unmodifiable(_staffList);
  List<InventoryItem> get inventoryList => List.unmodifiable(_inventoryList);
  List<ShopTransaction> get transactionList => List.unmodifiable(_transactionList);
  List<String> get customCategories => List.unmodifiable(_categories);

  int get maxCategories => maxCategoryLimit;
  bool get isCategoryLimitReached => allProductCategories.length >= maxCategoryLimit;
  int get remainingCategorySlots => (maxCategoryLimit - allProductCategories.length).clamp(0, maxCategoryLimit);

  StaffPermission get effectivePermission {
    if (isOwner) return StaffPermission.fullAccess;
    return _currentStaff?.permission ?? StaffPermission.readOnly;
  }

  /// Role-based permission check:
  /// Shop Owner and Staff with Full Access (canModifyItems) can add/edit/delete product categories.
  /// Staff with Stock Counting Only or Read-Only are restricted.
  bool get canManageCategories => isOwner || effectivePermission.canModifyItems;

  /// Aggregated list of all available product categories (capped at maxCategoryLimit = 5)
  List<String> get allProductCategories {
    for (final item in _inventoryList) {
      final trimmed = item.category.trim();
      if (trimmed.isNotEmpty &&
          _categories.length < maxCategoryLimit &&
          !_categories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
        _categories.add(trimmed);
      }
    }
    return List.unmodifiable(_categories);
  }

  /// Adds a new product category (maximum 5 categories allowed per shop)
  bool addCategory(String category) {
    if (!canManageCategories) {
      debugPrint('AppStateProvider: Unauthorized category add attempt by non-permitted user/staff');
      return false;
    }

    final trimmed = category.trim();
    if (trimmed.isEmpty) return false;

    // Check if category already exists (case-insensitive)
    final exists = allProductCategories.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return true;

    // Hard Limit Check: Maximum 5 categories allowed
    if (allProductCategories.length >= maxCategoryLimit) {
      debugPrint('AppStateProvider: Category limit ($maxCategoryLimit) reached. Cannot add "$trimmed".');
      return false;
    }

    _categories.add(trimmed);
    FirestoreService.instance.addCategory(_shopId, trimmed);
    notifyListeners();
    return true;
  }

  /// Edits / Renames an existing product category and updates all associated inventory items
  bool editCategory(String oldName, String newName) {
    if (!canManageCategories) {
      debugPrint('AppStateProvider: Unauthorized category edit attempt by non-permitted user/staff');
      return false;
    }

    final trimmedOld = oldName.trim();
    final trimmedNew = newName.trim();

    if (trimmedOld.isEmpty || trimmedNew.isEmpty) return false;
    if (trimmedOld.toLowerCase() == trimmedNew.toLowerCase()) return true;

    // Check if target name conflicts with another existing category
    final conflict = allProductCategories.any(
      (c) => c.toLowerCase() == trimmedNew.toLowerCase() && c.toLowerCase() != trimmedOld.toLowerCase(),
    );
    if (conflict) {
      debugPrint('AppStateProvider: Category name already in use: $trimmedNew');
      return false;
    }

    // 1. Rename category in _categories list
    final idx = _categories.indexWhere((c) => c.toLowerCase() == trimmedOld.toLowerCase());
    if (idx != -1) {
      _categories[idx] = trimmedNew;
    } else {
      _categories.add(trimmedNew);
    }

    // 2. Cascade rename to all inventory items
    for (int i = 0; i < _inventoryList.length; i++) {
      if (_inventoryList[i].category.trim().toLowerCase() == trimmedOld.toLowerCase()) {
        final updatedItem = _inventoryList[i].copyWith(
          category: trimmedNew,
          lastUpdated: DateTime.now(),
        );
        _inventoryList[i] = updatedItem;
        FirestoreService.instance.updateInventoryItem(_shopId, updatedItem);
      }
    }

    // 3. Update active filter category if needed
    if (_inventoryFilterCategory.toLowerCase() == trimmedOld.toLowerCase()) {
      _inventoryFilterCategory = trimmedNew;
    }

    // 4. Update Firestore category doc
    FirestoreService.instance.renameCategory(_shopId, trimmedOld, trimmedNew);

    notifyListeners();
    return true;
  }

  /// Deletes a product category (if more than 1 category exists) and reassigns any items
  bool deleteCategory(String categoryName) {
    if (!canManageCategories) {
      debugPrint('AppStateProvider: Unauthorized category delete attempt by non-permitted user/staff');
      return false;
    }

    if (allProductCategories.length <= 1) {
      debugPrint('AppStateProvider: Cannot delete the only remaining category');
      return false;
    }

    final trimmed = categoryName.trim();
    final idx = _categories.indexWhere((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (idx == -1) return false;

    _categories.removeAt(idx);
    final fallbackCategory = _categories.first;

    // Reassign any inventory items that were using the deleted category
    for (int i = 0; i < _inventoryList.length; i++) {
      if (_inventoryList[i].category.trim().toLowerCase() == trimmed.toLowerCase()) {
        final updatedItem = _inventoryList[i].copyWith(
          category: fallbackCategory,
          lastUpdated: DateTime.now(),
        );
        _inventoryList[i] = updatedItem;
        FirestoreService.instance.updateInventoryItem(_shopId, updatedItem);
      }
    }

    if (_inventoryFilterCategory.toLowerCase() == trimmed.toLowerCase()) {
      _inventoryFilterCategory = 'All';
    }

    FirestoreService.instance.deleteCategory(_shopId, trimmed);
    notifyListeners();
    return true;
  }

  // Dashboard Aggregates
  double get totalRevenue =>
      _transactionList.fold(0.0, (sum, item) => sum + item.totalAmount);

  int get totalStockQuantity =>
      _inventoryList.fold(0, (sum, item) => sum + item.quantity);

  int get lowStockItemCount =>
      _inventoryList.where((item) => item.isLowStock).length;

  int get outOfStockItemCount =>
      _inventoryList.where((item) => item.isOutOfStock).length;

  int get activeStaffCount =>
      _staffList.where((staff) => staff.isActive && staff.isApproved).length;

  List<StaffMember> get pendingStaffList =>
      _staffList.where((s) => !s.isApproved).toList();

  List<StaffMember> get approvedStaffList =>
      _staffList.where((s) => s.isApproved).toList();

  int get pendingStaffCount => pendingStaffList.length;

  // Auth Operations
  /// Automatically restores session if user (Owner or Staff) was previously logged in
  Future<bool> tryRestoreSession() async {
    try {
      // 1. Check local persistent session storage first (for both Staff & Owner)
      final savedSession = await SessionStorageService.instance.getSavedSession();
      if (savedSession != null) {
        final role = savedSession['role'] as String;
        final shopId = savedSession['shopId'] as String;
        final shopName = savedSession['shopName'] as String;

        if (role == 'staff') {
          final savedStaff = savedSession['staff'] as StaffMember;
          StaffMember effectiveStaff = savedStaff;
          try {
            final freshStaff = await FirestoreService.instance.getStaffMember(shopId, savedStaff.id);
            if (freshStaff != null) {
              if (!freshStaff.isApproved || !freshStaff.isActive) {
                // If owner revoked access, clear session and return false
                await SessionStorageService.instance.clearSession();
                return false;
              }
              effectiveStaff = freshStaff;
            }
          } catch (_) {}

          if (effectiveStaff.isApproved) {
            loginAsStaff(effectiveStaff, shopId: shopId, shopName: shopName);
            return true;
          }
        } else if (role == 'owner') {
          final email = savedSession['email'] as String;
          loginAsOwner(email, shopId: shopId, shopName: shopName);
          return true;
        }
      }

      // 2. Fallback to Firebase Auth user
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        final profile = await FirestoreService.instance.getUserProfile(user.uid);
        final shopId = profile?['shopId'] as String? ??
            'SHOP-SYNC-${user.uid.length >= 6 ? user.uid.substring(0, 6).toUpperCase() : user.uid.toUpperCase()}';
        final shopName = profile?['name'] as String? ?? '';
        final roleStr = profile?['role'] as String? ?? 'owner';

        if (roleStr == 'staff') {
          final staffMember = StaffMember(
            id: user.uid,
            name: profile?['name'] as String? ?? (user.displayName ?? 'Staff Member'),
            email: user.email ?? '',
            permission: StaffPermission.stockCounting,
            isActive: true,
            isApproved: true,
            joinedDate: DateTime.now(),
            shopId: shopId,
          );
          loginAsStaff(staffMember, shopId: shopId, shopName: shopName);
        } else {
          loginAsOwner(user.email ?? '', shopId: shopId, shopName: shopName);
        }
        return true;
      }
    } catch (e) {
      debugPrint('AppStateProvider: tryRestoreSession notice: $e');
    }
    return false;
  }

  void loginAsOwner(String email, {String? shopId, String? shopName}) {
    _isAuthenticated = true;
    _currentUserRole = UserRole.owner;
    _ownerEmail = email;
    if (shopId != null && shopId.isNotEmpty) {
      _shopId = shopId;
    }
    if (shopName != null && shopName.isNotEmpty) {
      _shopName = shopName;
    }
    _currentStaff = null;
    _bindFirestoreStreams(_shopId);
    SessionStorageService.instance.saveOwnerSession(
      email: _ownerEmail,
      shopId: _shopId,
      shopName: _shopName,
    );
    notifyListeners();
  }

  void loginAsStaff(StaffMember staff, {String? shopId, String? shopName}) {
    _isAuthenticated = true;
    _currentUserRole = UserRole.staff;
    _currentStaff = staff;
    if (shopId != null && shopId.isNotEmpty) {
      _shopId = shopId;
    }
    if (shopName != null && shopName.isNotEmpty) {
      _shopName = shopName;
    }
    _bindFirestoreStreams(_shopId);
    SessionStorageService.instance.saveStaffSession(
      staff: staff,
      shopId: _shopId,
      shopName: _shopName,
    );
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUserRole = UserRole.owner;
    _ownerEmail = '';
    _shopId = '';
    _shopName = '';
    _currentStaff = null;
    _staffList = [];
    _inventoryList = [];
    _transactionList = [];
    _categories = List.from(defaultProductCategories);
    _inventoryFilterCategory = 'All';
    _cancelFirestoreStreams();
    FirebaseAuthService.instance.signOut();
    SessionStorageService.instance.clearSession();
    notifyListeners();
  }

  void setActiveNavIndex(int index) {
    _activeNavIndex = index;
    notifyListeners();
  }

  // Safe role switcher for Admin to preview Staff visibility (RBAC)
  // Strictly restricted to Shop Owner / Admin
  void switchDemoRole(UserRole role, [StaffPermission? permission]) {
    // Real staff members can NEVER switch roles or elevate permissions
    if (!isRealOwner) return;

    _currentUserRole = role;
    if (role == UserRole.staff) {
      final perm = permission ?? StaffPermission.fullAccess;
      final matching = _staffList.where((s) => s.permission == perm);
      if (matching.isNotEmpty) {
        _currentStaff = matching.first;
      } else {
        _currentStaff = StaffMember(
          id: 'preview_staff_rbac',
          name: 'Staff Preview (${perm.title})',
          email: 'preview@staff.local',
          permission: perm,
          isActive: true,
          isApproved: true,
          joinedDate: DateTime.now(),
          shopId: _shopId,
        );
      }
    } else {
      _currentStaff = null;
    }
    notifyListeners();
  }

  // Staff Management Actions (Owner only)
  void updateStaffPermission(String staffId, StaffPermission newPermission) {
    final index = _staffList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      _staffList[index] = _staffList[index].copyWith(permission: newPermission);
      if (_currentStaff?.id == staffId) {
        _currentStaff = _staffList[index];
      }
      FirestoreService.instance.updateStaffPermission(_shopId, staffId, newPermission);
      notifyListeners();
    }
  }

  void toggleStaffStatus(String staffId) {
    final index = _staffList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final current = _staffList[index];
      final updated = current.copyWith(isActive: !current.isActive);
      _staffList[index] = updated;
      FirestoreService.instance.toggleStaffStatus(_shopId, staffId, updated.isActive);
      notifyListeners();
    }
  }

  void approveStaff(String staffId, StaffPermission permission) {
    final index = _staffList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final updated = _staffList[index].copyWith(
        isApproved: true,
        isActive: true,
        permission: permission,
      );
      _staffList[index] = updated;
      if (_currentStaff?.id == staffId) {
        _currentStaff = updated;
      }
      FirestoreService.instance.approveStaffMember(_shopId, staffId, permission);
      notifyListeners();
    }
  }

  void rejectStaff(String staffId) {
    _staffList.removeWhere((s) => s.id == staffId);
    if (_currentStaff?.id == staffId) {
      _currentStaff = null;
      _isAuthenticated = false;
    }
    FirestoreService.instance.rejectStaffMember(_shopId, staffId);
    notifyListeners();
  }

  StaffMember addStaffMemberFromQR({
    required String name,
    required String email,
    String? shopId,
    String? shopName,
    StaffPermission permission = StaffPermission.stockCounting,
    bool isApproved = false,
  }) {
    final effectiveShopId = (shopId != null && shopId.isNotEmpty) ? shopId : _shopId;
    final effectiveShopName = (shopName != null && shopName.isNotEmpty) ? shopName : _shopName;
    _shopId = effectiveShopId;
    _shopName = effectiveShopName;

    final newStaff = StaffMember(
      id: 'stf_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      permission: permission,
      isActive: true,
      isApproved: isApproved,
      joinedDate: DateTime.now(),
      shopId: effectiveShopId,
    );
    _staffList.insert(0, newStaff);
    _currentStaff = newStaff;
    _currentUserRole = UserRole.staff;
    _isAuthenticated = isApproved;

    _bindFirestoreStreams(effectiveShopId);
    FirestoreService.instance.addStaffMember(effectiveShopId, newStaff);
    notifyListeners();
    return newStaff;
  }

  // Inventory Management Actions
  void addInventoryItem(InventoryItem item) {
    _inventoryList.insert(0, item);
    FirestoreService.instance.addInventoryItem(_shopId, item);
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem updatedItem) {
    final index = _inventoryList.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _inventoryList[index] = updatedItem;
      FirestoreService.instance.updateInventoryItem(_shopId, updatedItem);
      notifyListeners();
    }
  }

  void updateStockQuantity(String itemId, int newQuantity) {
    final index = _inventoryList.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _inventoryList[index] = _inventoryList[index].copyWith(
        quantity: newQuantity,
        lastUpdated: DateTime.now(),
      );
      FirestoreService.instance.updateStockQuantity(_shopId, itemId, newQuantity);
      notifyListeners();
    }
  }

  void deleteInventoryItem(String itemId) {
    _inventoryList.removeWhere((i) => i.id == itemId);
    FirestoreService.instance.deleteInventoryItem(_shopId, itemId);
    notifyListeners();
  }

  // Transaction Actions
  void addTransaction(ShopTransaction tx) {
    _transactionList.insert(0, tx);
    FirestoreService.instance.addTransaction(_shopId, tx);
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelFirestoreStreams();
    super.dispose();
  }
}
