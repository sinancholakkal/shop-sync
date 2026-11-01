enum UserRole {
  owner,
  staff;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Shop Owner (Admin)';
      case UserRole.staff:
        return 'Staff Member';
    }
  }
}

enum StaffPermission {
  fullAccess,
  stockCounting,
  readOnly;

  String get title {
    switch (this) {
      case StaffPermission.fullAccess:
        return 'Full Access / Item Management';
      case StaffPermission.stockCounting:
        return 'Stock Counting Only';
      case StaffPermission.readOnly:
        return 'Read-Only Access';
    }
  }

  String get description {
    switch (this) {
      case StaffPermission.fullAccess:
        return 'Permission to add, edit, delete, and update items & stock counts.';
      case StaffPermission.stockCounting:
        return 'Permission to update specific item counts and inventory quantities only.';
      case StaffPermission.readOnly:
        return 'Permission to view shop data and items without any modification rights.';
    }
  }

  bool get canModifyItems => this == StaffPermission.fullAccess;
  bool get canUpdateStockCount => this == StaffPermission.fullAccess || this == StaffPermission.stockCounting;
  bool get canViewCostPrice => this == StaffPermission.fullAccess;
  bool get canManageStaff => false; // Only owner can manage staff
}
