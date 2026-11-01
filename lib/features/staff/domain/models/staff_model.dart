import '../../../auth/domain/models/user_role.dart';

class StaffMember {
  final String id;
  final String name;
  final String email;
  final StaffPermission permission;
  final bool isActive;
  final DateTime joinedDate;
  final String? shopId;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.permission,
    this.isActive = true,
    required this.joinedDate,
    this.shopId,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    StaffPermission? permission,
    bool? isActive,
    DateTime? joinedDate,
    String? shopId,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      permission: permission ?? this.permission,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      shopId: shopId ?? this.shopId,
    );
  }
}
