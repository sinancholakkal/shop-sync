import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/mock_data_repository.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../features/staff/domain/models/staff_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------
  // Shop & User Profiles
  // ----------------------------------------------------

  Future<void> createShop({
    required String shopId,
    required String shopName,
    required String ownerEmail,
  }) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final docRef = firestore.collection('shops').doc(shopId);
      await docRef.set({
        'shopId': shopId,
        'name': shopName,
        'ownerEmail': ownerEmail,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await seedInitialDataIfEmpty(shopId);
    } catch (e) {
      debugPrint('FirestoreService: createShop notice: $e');
    }
  }

  Future<Map<String, dynamic>?> getShop(String shopId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return null;

      final doc = await firestore.collection('shops').doc(shopId).get();
      return doc.data();
    } catch (e) {
      debugPrint('FirestoreService: getShop notice: $e');
      return null;
    }
  }

  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String role,
    required String shopId,
    required String name,
  }) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role,
        'shopId': shopId,
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: saveUserProfile notice: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return null;

      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('FirestoreService: getUserProfile notice: $e');
      return null;
    }
  }

  // ----------------------------------------------------
  // Auto-seed Demo Data for Newly Registered Shops
  // ----------------------------------------------------

  Future<void> seedInitialDataIfEmpty(String shopId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final inventorySnapshot = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isEmpty) {
        final batch = firestore.batch();

        for (final item in MockDataRepository.getInitialInventory()) {
          final doc = firestore
              .collection('shops')
              .doc(shopId)
              .collection('inventory')
              .doc(item.id);
          batch.set(doc, item.toMap());
        }

        for (final staff in MockDataRepository.getInitialStaff()) {
          final doc = firestore
              .collection('shops')
              .doc(shopId)
              .collection('staff')
              .doc(staff.id);
          batch.set(doc, staff.toMap());
        }

        for (final tx in MockDataRepository.getInitialTransactions()) {
          final doc = firestore
              .collection('shops')
              .doc(shopId)
              .collection('transactions')
              .doc(tx.id);
          batch.set(doc, tx.toMap());
        }

        await batch.commit();
        debugPrint('FirestoreService: Initial demo catalog seeded successfully for shop $shopId');
      }
    } catch (e) {
      debugPrint('FirestoreService: seedInitialDataIfEmpty notice: $e');
    }
  }

  // ----------------------------------------------------
  // Inventory Real-time Streams & CRUD
  // ----------------------------------------------------

  Stream<List<InventoryItem>> streamInventory(String shopId) {
    try {
      final firestore = _firestore;
      if (firestore == null) return const Stream.empty();

      return firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint('FirestoreService: streamInventory notice: $e');
      return const Stream.empty();
    }
  }

  Future<void> addInventoryItem(String shopId, InventoryItem item) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final docRef = item.id.isNotEmpty
          ? firestore.collection('shops').doc(shopId).collection('inventory').doc(item.id)
          : firestore.collection('shops').doc(shopId).collection('inventory').doc();

      await docRef.set(item.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: addInventoryItem notice: $e');
    }
  }

  Future<void> updateInventoryItem(String shopId, InventoryItem item) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: updateInventoryItem notice: $e');
    }
  }

  Future<void> updateStockQuantity(String shopId, String itemId, int newQuantity) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc(itemId)
          .update({
        'quantity': newQuantity,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('FirestoreService: updateStockQuantity notice: $e');
    }
  }

  Future<void> deleteInventoryItem(String shopId, String itemId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('inventory')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreService: deleteInventoryItem notice: $e');
    }
  }

  // ----------------------------------------------------
  // Staff Real-time Streams & CRUD
  // ----------------------------------------------------

  Stream<List<StaffMember>> streamStaff(String shopId) {
    try {
      final firestore = _firestore;
      if (firestore == null) return const Stream.empty();

      return firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StaffMember.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint('FirestoreService: streamStaff notice: $e');
      return const Stream.empty();
    }
  }

  Stream<StaffMember?> streamStaffMember(String shopId, String staffId) {
    try {
      final firestore = _firestore;
      if (firestore == null) return const Stream.empty();

      return firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return StaffMember.fromMap(doc.data()!, doc.id);
      });
    } catch (e) {
      debugPrint('FirestoreService: streamStaffMember notice: $e');
      return const Stream.empty();
    }
  }

  Future<StaffMember?> getStaffMember(String shopId, String staffId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return null;

      final doc = await firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return StaffMember.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('FirestoreService: getStaffMember notice: $e');
      return null;
    }
  }

  Future<void> addStaffMember(String shopId, StaffMember staff) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final docRef = staff.id.isNotEmpty
          ? firestore.collection('shops').doc(shopId).collection('staff').doc(staff.id)
          : firestore.collection('shops').doc(shopId).collection('staff').doc();

      await docRef.set(staff.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: addStaffMember notice: $e');
    }
  }

  Future<void> updateStaffPermission(
    String shopId,
    String staffId,
    StaffPermission permission,
  ) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .update({'permission': permission.name});
    } catch (e) {
      debugPrint('FirestoreService: updateStaffPermission notice: $e');
    }
  }

  Future<void> toggleStaffStatus(
    String shopId,
    String staffId,
    bool isActive,
  ) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .update({'isActive': isActive});
    } catch (e) {
      debugPrint('FirestoreService: toggleStaffStatus notice: $e');
    }
  }

  Future<void> approveStaffMember(
    String shopId,
    String staffId,
    StaffPermission permission,
  ) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .update({
        'isApproved': true,
        'isActive': true,
        'permission': permission.name,
      });
    } catch (e) {
      debugPrint('FirestoreService: approveStaffMember notice: $e');
    }
  }

  Future<void> rejectStaffMember(
    String shopId,
    String staffId,
  ) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('staff')
          .doc(staffId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreService: rejectStaffMember notice: $e');
    }
  }

  // ----------------------------------------------------
  // Transactions Real-time Streams & CRUD
  // ----------------------------------------------------

  Stream<List<ShopTransaction>> streamTransactions(String shopId) {
    try {
      final firestore = _firestore;
      if (firestore == null) return const Stream.empty();

      return firestore
          .collection('shops')
          .doc(shopId)
          .collection('transactions')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ShopTransaction.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint('FirestoreService: streamTransactions notice: $e');
      return const Stream.empty();
    }
  }

  Future<void> addTransaction(String shopId, ShopTransaction tx) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final docRef = tx.id.isNotEmpty
          ? firestore.collection('shops').doc(shopId).collection('transactions').doc(tx.id)
          : firestore.collection('shops').doc(shopId).collection('transactions').doc();

      await docRef.set(tx.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: addTransaction notice: $e');
    }
  }
}
