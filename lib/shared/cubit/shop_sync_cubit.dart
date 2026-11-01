import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/repositories/mock_data_repository.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../core/services/session_storage_service.dart';
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
      staffList.where((staff) => staff.isActive && staff.isApproved).length;

  List<StaffMember> get pendingStaffList =>
      staffList.where((s) => !s.isApproved).toList();

  List<StaffMember> get approvedStaffList =>
      staffList.where((s) => s.isApproved).toList();

  int get pendingStaffCount => pendingStaffList.length;

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
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<StaffMember>>? _staffSubscription;
  StreamSubscription<List<ShopTransaction>>? _transactionSubscription;

  ShopSyncCubit({bool isAuthenticated = true})
      : super(ShopSyncState(isAuthenticated: isAuthenticated)) {
    initializeData();
    if (isAuthenticated) {
      _bindFirestoreStreams(state.shopId);
    }
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

  void _bindFirestoreStreams(String targetShopId) {
    _cancelFirestoreStreams();

    try {
      _inventorySubscription = FirestoreService.instance
          .streamInventory(targetShopId)
          .listen((items) {
        if (items.isNotEmpty && !isClosed) {
          emit(state.copyWith(inventoryList: items));
        }
      }, onError: (e) {
        debugPrint('ShopSyncCubit: inventory stream error: $e');
      });

      _staffSubscription = FirestoreService.instance
          .streamStaff(targetShopId)
          .listen((staff) {
        if (staff.isNotEmpty && !isClosed) {
          StaffMember? updatedCurrent = state.currentStaff;
          if (updatedCurrent != null) {
            final matching = staff.where((s) => s.id == updatedCurrent!.id);
            if (matching.isNotEmpty) {
              updatedCurrent = matching.first;
            }
          }
          emit(state.copyWith(
            staffList: staff,
            currentStaff: updatedCurrent,
          ));
        }
      }, onError: (e) {
        debugPrint('ShopSyncCubit: staff stream error: $e');
      });

      _transactionSubscription = FirestoreService.instance
          .streamTransactions(targetShopId)
          .listen((txs) {
        if (txs.isNotEmpty && !isClosed) {
          emit(state.copyWith(transactionList: txs));
        }
      }, onError: (e) {
        debugPrint('ShopSyncCubit: transaction stream error: $e');
      });
    } catch (e) {
      debugPrint('ShopSyncCubit: _bindFirestoreStreams notice: $e');
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

  void loginAsOwner(String email, {String? shopId, String? shopName}) {
    final activeShopId = shopId ?? state.shopId;
    final activeShopName = shopName ?? state.shopName;
    emit(state.copyWith(
      isAuthenticated: true,
      currentUserRole: UserRole.owner,
      ownerEmail: email,
      shopId: activeShopId,
      shopName: activeShopName,
      clearCurrentStaff: true,
    ));
    _bindFirestoreStreams(activeShopId);
    SessionStorageService.instance.saveOwnerSession(
      email: email,
      shopId: activeShopId,
      shopName: activeShopName,
    );
  }

  void loginAsStaff(StaffMember staff, {String? shopId, String? shopName}) {
    final activeShopId = shopId ?? state.shopId;
    final activeShopName = shopName ?? state.shopName;
    emit(state.copyWith(
      isAuthenticated: true,
      currentUserRole: UserRole.staff,
      currentStaff: staff,
      shopId: activeShopId,
      shopName: activeShopName,
    ));
    _bindFirestoreStreams(activeShopId);
    SessionStorageService.instance.saveStaffSession(
      staff: staff,
      shopId: activeShopId,
      shopName: activeShopName,
    );
  }

  void logout() {
    _cancelFirestoreStreams();
    FirebaseAuthService.instance.signOut();
    SessionStorageService.instance.clearSession();
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

    FirestoreService.instance.updateStaffPermission(state.shopId, staffId, newPermission);

    emit(state.copyWith(
      staffList: updatedList,
      currentStaff: updatedCurrent,
    ));
  }

  void toggleStaffStatus(String staffId) {
    bool nextActive = true;
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        nextActive = !s.isActive;
        return s.copyWith(isActive: nextActive);
      }
      return s;
    }).toList();

    FirestoreService.instance.toggleStaffStatus(state.shopId, staffId, nextActive);

    emit(state.copyWith(staffList: updatedList));
  }

  void approveStaff(String staffId, StaffPermission permission) {
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(isApproved: true, isActive: true, permission: permission);
      }
      return s;
    }).toList();

    StaffMember? updatedCurrent = state.currentStaff;
    if (updatedCurrent?.id == staffId) {
      updatedCurrent = updatedCurrent?.copyWith(
        isApproved: true,
        isActive: true,
        permission: permission,
      );
    }

    FirestoreService.instance.approveStaffMember(state.shopId, staffId, permission);

    emit(state.copyWith(
      staffList: updatedList,
      currentStaff: updatedCurrent,
    ));
  }

  void rejectStaff(String staffId) {
    final updatedList = state.staffList.where((s) => s.id != staffId).toList();
    StaffMember? updatedCurrent = state.currentStaff;
    bool auth = state.isAuthenticated;
    if (updatedCurrent?.id == staffId) {
      updatedCurrent = null;
      auth = false;
    }

    FirestoreService.instance.rejectStaffMember(state.shopId, staffId);

    emit(state.copyWith(
      staffList: updatedList,
      currentStaff: updatedCurrent,
      isAuthenticated: auth,
      clearCurrentStaff: updatedCurrent == null,
    ));
  }

  StaffMember addStaffMemberFromQR({
    required String name,
    required String email,
    String? shopId,
    String? shopName,
    StaffPermission permission = StaffPermission.stockCounting,
    bool isApproved = false,
  }) {
    final effectiveShopId = (shopId != null && shopId.isNotEmpty) ? shopId : state.shopId;
    final effectiveShopName = (shopName != null && shopName.isNotEmpty) ? shopName : state.shopName;
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
    final updatedList = [newStaff, ...state.staffList];

    _bindFirestoreStreams(effectiveShopId);
    FirestoreService.instance.addStaffMember(effectiveShopId, newStaff);

    emit(state.copyWith(
      shopId: effectiveShopId,
      shopName: effectiveShopName,
      staffList: updatedList,
      currentStaff: newStaff,
      currentUserRole: UserRole.staff,
      isAuthenticated: isApproved,
    ));
    return newStaff;
  }

  void syncStaffMemberFromQR(StaffMember newStaff, {String? shopName}) {
    final effectiveShopId = newStaff.shopId ?? state.shopId;
    final effectiveShopName = (shopName != null && shopName.isNotEmpty) ? shopName : state.shopName;
    final updatedList = [newStaff, ...state.staffList.where((s) => s.id != newStaff.id)];

    _bindFirestoreStreams(effectiveShopId);

    emit(state.copyWith(
      shopId: effectiveShopId,
      shopName: effectiveShopName,
      staffList: updatedList,
      currentStaff: newStaff,
      currentUserRole: UserRole.staff,
      isAuthenticated: newStaff.isApproved,
    ));
  }

  void addInventoryItem(InventoryItem item) {
    final updatedList = [item, ...state.inventoryList];
    FirestoreService.instance.addInventoryItem(state.shopId, item);
    emit(state.copyWith(inventoryList: updatedList));
  }

  void updateInventoryItem(InventoryItem updatedItem) {
    final updatedList = state.inventoryList.map((i) {
      return i.id == updatedItem.id ? updatedItem : i;
    }).toList();
    FirestoreService.instance.updateInventoryItem(state.shopId, updatedItem);
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
    FirestoreService.instance.updateStockQuantity(state.shopId, itemId, newQuantity);
    emit(state.copyWith(inventoryList: updatedList));
  }

  void deleteInventoryItem(String itemId) {
    final updatedList = state.inventoryList.where((i) => i.id != itemId).toList();
    FirestoreService.instance.deleteInventoryItem(state.shopId, itemId);
    emit(state.copyWith(inventoryList: updatedList));
  }

  void addTransaction(ShopTransaction tx) {
    final updatedList = [tx, ...state.transactionList];
    FirestoreService.instance.addTransaction(state.shopId, tx);
    emit(state.copyWith(transactionList: updatedList));
  }

  @override
  Future<void> close() {
    _cancelFirestoreStreams();
    return super.close();
  }
}
