import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/mock_data_repository.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../features/staff/domain/models/staff_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

class ShopSyncState {
  final bool isAuthenticated;
  final UserRole currentUserRole;
  final String ownerEmail;
  final String shopId;
  final String shopName;
  final StaffMember? currentStaff;
  final List<StaffMember> staffList;
  final List<InventoryItem> inventoryList;
  final List<ShopTransaction> transactionList;

  const ShopSyncState({
    this.isAuthenticated = true,
    this.currentUserRole = UserRole.owner,
    this.ownerEmail = MockDataRepository.defaultOwnerEmail,
    this.shopId = MockDataRepository.defaultShopId,
    this.shopName = MockDataRepository.defaultShopName,
    this.currentStaff,
    this.staffList = const [],
    this.inventoryList = const [],
    this.transactionList = const [],
  });

  bool get isOwner => currentUserRole == UserRole.owner;

  StaffPermission get effectivePermission {
    if (isOwner) return StaffPermission.fullAccess;
    return currentStaff?.permission ?? StaffPermission.readOnly;
  }

  double get totalRevenue =>
      transactionList.fold(0.0, (sum, item) => sum + item.totalAmount);

  int get totalStockQuantity =>
      inventoryList.fold(0, (sum, item) => sum + item.quantity);

  int get lowStockItemCount =>
      inventoryList.where((item) => item.isLowStock).length;

  int get activeStaffCount =>
      staffList.where((staff) => staff.isActive).length;

  ShopSyncState copyWith({
    bool? isAuthenticated,
    UserRole? currentUserRole,
    String? ownerEmail,
    String? shopId,
    String? shopName,
    StaffMember? currentStaff,
    List<StaffMember>? staffList,
    List<InventoryItem>? inventoryList,
    List<ShopTransaction>? transactionList,
    bool clearCurrentStaff = false,
  }) {
    return ShopSyncState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      currentStaff: clearCurrentStaff ? null : (currentStaff ?? this.currentStaff),
      staffList: staffList ?? this.staffList,
      inventoryList: inventoryList ?? this.inventoryList,
      transactionList: transactionList ?? this.transactionList,
    );
  }
}

class ShopSyncCubit extends Cubit<ShopSyncState> {
  ShopSyncCubit({bool isAuthenticated = true})
      : super(ShopSyncState(isAuthenticated: isAuthenticated)) {
    initializeData();
  }

  void initializeData() {
    final staff = MockDataRepository.getInitialStaff();
    final inventory = MockDataRepository.getInitialInventory();
    final transactions = MockDataRepository.getInitialTransactions();

    emit(state.copyWith(
      staffList: staff,
      inventoryList: inventory,
      transactionList: transactions,
      currentStaff: staff.isNotEmpty ? staff.first : null,
    ));
  }

  void loginAsOwner(String email) {
    emit(state.copyWith(
      isAuthenticated: true,
      currentUserRole: UserRole.owner,
      ownerEmail: email,
      clearCurrentStaff: true,
    ));
  }

  void loginAsStaff(StaffMember staff) {
    emit(state.copyWith(
      isAuthenticated: true,
      currentUserRole: UserRole.staff,
      currentStaff: staff,
    ));
  }

  void logout() {
    emit(state.copyWith(isAuthenticated: false));
  }

  void switchDemoRole(UserRole role, [StaffPermission? permission]) {
    if (role == UserRole.staff) {
      final perm = permission ?? StaffPermission.fullAccess;
      final found = state.staffList.firstWhere(
        (s) => s.permission == perm,
        orElse: () => state.staffList.first,
      );
      emit(state.copyWith(
        currentUserRole: role,
        currentStaff: found.copyWith(permission: perm),
      ));
    } else {
      emit(state.copyWith(
        currentUserRole: role,
        clearCurrentStaff: true,
      ));
    }
  }

  void updateStaffPermission(String staffId, StaffPermission newPermission) {
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(permission: newPermission);
      }
      return s;
    }).toList();

    StaffMember? updatedCurrent = state.currentStaff;
    if (updatedCurrent?.id == staffId) {
      updatedCurrent = updatedCurrent?.copyWith(permission: newPermission);
    }

    emit(state.copyWith(
      staffList: updatedList,
      currentStaff: updatedCurrent,
    ));
  }

  void toggleStaffStatus(String staffId) {
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(isActive: !s.isActive);
      }
      return s;
    }).toList();

    emit(state.copyWith(staffList: updatedList));
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
      shopId: state.shopId,
    );
    final updatedList = [newStaff, ...state.staffList];

    emit(state.copyWith(
      staffList: updatedList,
      currentStaff: newStaff,
      currentUserRole: UserRole.staff,
      isAuthenticated: true,
    ));
  }

  void addInventoryItem(InventoryItem item) {
    final updatedList = [item, ...state.inventoryList];
    emit(state.copyWith(inventoryList: updatedList));
  }

  void updateInventoryItem(InventoryItem updatedItem) {
    final updatedList = state.inventoryList.map((i) {
      return i.id == updatedItem.id ? updatedItem : i;
    }).toList();
    emit(state.copyWith(inventoryList: updatedList));
  }

  void updateStockQuantity(String itemId, int newQuantity) {
    final updatedList = state.inventoryList.map((i) {
      if (i.id == itemId) {
        return i.copyWith(
          quantity: newQuantity,
          lastUpdated: DateTime.now(),
        );
      }
      return i;
    }).toList();
    emit(state.copyWith(inventoryList: updatedList));
  }

  void deleteInventoryItem(String itemId) {
    final updatedList = state.inventoryList.where((i) => i.id != itemId).toList();
    emit(state.copyWith(inventoryList: updatedList));
  }

  void addTransaction(ShopTransaction tx) {
    final updatedList = [tx, ...state.transactionList];
    emit(state.copyWith(transactionList: updatedList));
  }
}
