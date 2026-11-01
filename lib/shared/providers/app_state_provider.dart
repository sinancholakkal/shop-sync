import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/repositories/mock_data_repository.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../features/staff/domain/models/staff_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

class AppStateProvider extends ChangeNotifier {
  // Authentication & Session
  bool _isAuthenticated;
  UserRole _currentUserRole = UserRole.owner;
  String _ownerEmail = MockDataRepository.defaultOwnerEmail;
  String _shopId = MockDataRepository.defaultShopId;
  String _shopName = MockDataRepository.defaultShopName;
  StaffMember? _currentStaff;

  // Domain Data Lists
  List<StaffMember> _staffList = [];
  List<InventoryItem> _inventoryList = [];
  List<ShopTransaction> _transactionList = [];

  // Active navigation index in app shell
  int _activeNavIndex = 0;

  // Real-time Firestore Stream Subscriptions
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<StaffMember>>? _staffSubscription;
  StreamSubscription<List<ShopTransaction>>? _transactionSubscription;

  AppStateProvider({bool initialAuth = true}) : _isAuthenticated = initialAuth {
    _initializeData();
    if (_isAuthenticated) {
      _bindFirestoreStreams(_shopId);
    }
  }

  void _initializeData() {
    _staffList = MockDataRepository.getInitialStaff();
    _inventoryList = MockDataRepository.getInitialInventory();
    _transactionList = MockDataRepository.getInitialTransactions();
    // Default current staff member for demo if switched to staff
    _currentStaff = _staffList.first;
  }

  void _bindFirestoreStreams(String targetShopId) {
    _cancelFirestoreStreams();

    try {
      _inventorySubscription = FirestoreService.instance
          .streamInventory(targetShopId)
          .listen((items) {
        if (items.isNotEmpty) {
          _inventoryList = items;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('AppStateProvider: Inventory stream error: $err');
      });

      _staffSubscription = FirestoreService.instance
          .streamStaff(targetShopId)
          .listen((staff) {
        if (staff.isNotEmpty) {
          _staffList = staff;
          if (_currentStaff != null) {
            final matching = staff.where((s) => s.id == _currentStaff!.id);
            if (matching.isNotEmpty) {
              _currentStaff = matching.first;
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('AppStateProvider: Staff stream error: $err');
      });

      _transactionSubscription = FirestoreService.instance
          .streamTransactions(targetShopId)
          .listen((txs) {
        if (txs.isNotEmpty) {
          _transactionList = txs;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('AppStateProvider: Transaction stream error: $err');
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

  List<StaffMember> get staffList => List.unmodifiable(_staffList);
  List<InventoryItem> get inventoryList => List.unmodifiable(_inventoryList);
  List<ShopTransaction> get transactionList => List.unmodifiable(_transactionList);

  StaffPermission get effectivePermission {
    if (isOwner) return StaffPermission.fullAccess;
    return _currentStaff?.permission ?? StaffPermission.readOnly;
  }

  // Dashboard Aggregates
  double get totalRevenue =>
      _transactionList.fold(0.0, (sum, item) => sum + item.totalAmount);

  int get totalStockQuantity =>
      _inventoryList.fold(0, (sum, item) => sum + item.quantity);

  int get lowStockItemCount =>
      _inventoryList.where((item) => item.isLowStock).length;

  int get activeStaffCount =>
      _staffList.where((staff) => staff.isActive && staff.isApproved).length;

  List<StaffMember> get pendingStaffList =>
      _staffList.where((s) => !s.isApproved).toList();

  List<StaffMember> get approvedStaffList =>
      _staffList.where((s) => s.isApproved).toList();

  int get pendingStaffCount => pendingStaffList.length;

  // Auth Operations
  /// Automatically restores session if Firebase user is already logged in
  Future<bool> tryRestoreSession() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        final profile = await FirestoreService.instance.getUserProfile(user.uid);
        final shopId = profile?['shopId'] as String? ??
            'SHOP-SYNC-${user.uid.length >= 6 ? user.uid.substring(0, 6).toUpperCase() : user.uid.toUpperCase()}';
        final shopName = profile?['name'] as String? ?? 'Apex Retail & Tech Hub';
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
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _cancelFirestoreStreams();
    FirebaseAuthService.instance.signOut();
    notifyListeners();
  }

  void setActiveNavIndex(int index) {
    _activeNavIndex = index;
    notifyListeners();
  }

  // Demo Switcher: easily switch role / staff permission to test RBAC live!
  void switchDemoRole(UserRole role, [StaffPermission? permission]) {
    _currentUserRole = role;
    if (role == UserRole.staff) {
      final perm = permission ?? StaffPermission.fullAccess;
      final found = _staffList.firstWhere(
        (s) => s.permission == perm,
        orElse: () => _staffList.first,
      );
      _currentStaff = found.copyWith(permission: perm);
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
