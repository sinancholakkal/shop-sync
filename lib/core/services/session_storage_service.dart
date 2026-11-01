import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/staff/domain/models/staff_model.dart';

class SessionStorageService {
  SessionStorageService._internal();
  static final SessionStorageService instance = SessionStorageService._internal();

  static const String _keyRole = 'shopsync_session_role';
  static const String _keyShopId = 'shopsync_session_shop_id';
  static const String _keyShopName = 'shopsync_session_shop_name';
  static const String _keyOwnerEmail = 'shopsync_session_owner_email';
  static const String _keyStaffData = 'shopsync_session_staff_data';

  Future<void> saveOwnerSession({
    required String email,
    required String shopId,
    required String shopName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRole, 'owner');
      await prefs.setString(_keyOwnerEmail, email);
      await prefs.setString(_keyShopId, shopId);
      await prefs.setString(_keyShopName, shopName);
      await prefs.remove(_keyStaffData);
    } catch (e) {
      debugPrint('SessionStorageService: saveOwnerSession notice: $e');
    }
  }

  Future<void> saveStaffSession({
    required StaffMember staff,
    required String shopId,
    required String shopName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRole, 'staff');
      await prefs.setString(_keyShopId, shopId);
      await prefs.setString(_keyShopName, shopName);
      await prefs.setString(_keyStaffData, jsonEncode(staff.toMap()..['id'] = staff.id));
      await prefs.remove(_keyOwnerEmail);
    } catch (e) {
      debugPrint('SessionStorageService: saveStaffSession notice: $e');
    }
  }

  Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_keyRole);
      if (role == null) return null;

      final shopId = prefs.getString(_keyShopId) ?? '';
      final shopName = prefs.getString(_keyShopName) ?? '';

      if (role == 'staff') {
        final rawStaff = prefs.getString(_keyStaffData);
        if (rawStaff != null && rawStaff.isNotEmpty) {
          final map = jsonDecode(rawStaff) as Map<String, dynamic>;
          final staffId = map['id'] as String? ?? '';
          if (staffId.isNotEmpty) {
            final staff = StaffMember.fromMap(map, staffId);
            return {
              'role': 'staff',
              'shopId': shopId,
              'shopName': shopName,
              'staff': staff,
            };
          }
        }
      } else if (role == 'owner') {
        final email = prefs.getString(_keyOwnerEmail) ?? '';
        return {
          'role': 'owner',
          'shopId': shopId,
          'shopName': shopName,
          'email': email,
        };
      }
    } catch (e) {
      debugPrint('SessionStorageService: getSavedSession notice: $e');
    }
    return null;
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRole);
      await prefs.remove(_keyOwnerEmail);
      await prefs.remove(_keyShopId);
      await prefs.remove(_keyShopName);
      await prefs.remove(_keyStaffData);
    } catch (e) {
      debugPrint('SessionStorageService: clearSession notice: $e');
    }
  }
}
