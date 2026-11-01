import '../../../auth/domain/models/user_role.dart';

class StaffMember {
  final String id;
  final String name;
  final String email;
  final StaffPermission permission;
  final bool isActive;
  final bool isApproved;
  final DateTime joinedDate;
  final String? shopId;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.permission,
    this.isActive = true,
    this.isApproved = false,
    required this.joinedDate,
    this.shopId,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    StaffPermission? permission,
    bool? isActive,
    bool? isApproved,
    DateTime? joinedDate,
    String? shopId,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      permission: permission ?? this.permission,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      joinedDate: joinedDate ?? this.joinedDate,
      shopId: shopId ?? this.shopId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'permission': permission.name,
      'isActive': isActive,
      'isApproved': isApproved,
      'joinedDate': joinedDate.toIso8601String(),
      'shopId': shopId,
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map, String docId) {
    StaffPermission perm = StaffPermission.readOnly;
    if (map['permission'] != null) {
      try {
        perm = StaffPermission.values.byName(map['permission'] as String);
      } catch (_) {}
    }

    return StaffMember(
      id: docId,
      name: map['name'] as String? ?? 'Staff Member',
      email: map['email'] as String? ?? '',
      permission: perm,
      isActive: map['isActive'] as bool? ?? true,
      isApproved: map['isApproved'] as bool? ?? false,
      joinedDate: map['joinedDate'] != null
          ? DateTime.tryParse(map['joinedDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      shopId: map['shopId'] as String?,
    );
  }
}
