import 'package:flutter/material.dart';
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
  final String _shopId = MockDataRepository.defaultShopId;
  final String _shopName = MockDataRepository.defaultShopName;
  StaffMember? _currentStaff;

  // Domain Data Lists
  List<StaffMember> _staffList = [];
  List<InventoryItem> _inventoryList = [];
  List<ShopTransaction> _transactionList = [];

  // Active navigation index in app shell
  int _activeNavIndex = 0;

  AppStateProvider({bool initialAuth = true}) : _isAuthenticated = initialAuth {
    _initializeData();
  }

  void _initializeData() {
    _staffList = MockDataRepository.getInitialStaff();
    _inventoryList = MockDataRepository.getInitialInventory();
    _transactionList = MockDataRepository.getInitialTransactions();
    // Default current staff member for demo if switched to staff
    _currentStaff = _staffList.first;
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
      _staffList.where((staff) => staff.isActive).length;

  // Auth Operations
  void loginAsOwner(String email) {
    _isAuthenticated = true;
    _currentUserRole = UserRole.owner;
    _ownerEmail = email;
    _currentStaff = null;
    notifyListeners();
  }

  void loginAsStaff(StaffMember staff) {
    _isAuthenticated = true;
    _currentUserRole = UserRole.staff;
    _currentStaff = staff;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
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
      notifyListeners();
    }
  }

  void toggleStaffStatus(String staffId) {
    final index = _staffList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      final current = _staffList[index];
      _staffList[index] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  void addStaffMemberFromQR({
    required String name,
    required String email,
    StaffPermission permission = StaffPermission.stockCounting,
  }) {
    final newStaff = StaffMember(
      id: 'stf_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      permission: permission,
      isActive: true,
      joinedDate: DateTime.now(),
      shopId: _shopId,
    );
    _staffList.insert(0, newStaff);
    _currentStaff = newStaff;
    _currentUserRole = UserRole.staff;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Inventory Management Actions
  void addInventoryItem(InventoryItem item) {
    _inventoryList.insert(0, item);
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem updatedItem) {
    final index = _inventoryList.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _inventoryList[index] = updatedItem;
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
      notifyListeners();
    }
  }

  void deleteInventoryItem(String itemId) {
    _inventoryList.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  // Transaction Actions
  void addTransaction(ShopTransaction tx) {
    _transactionList.insert(0, tx);
    notifyListeners();
  }
}
