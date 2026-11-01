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
  inventoryManager,
  stockCounting,
  readOnly;

  String get title {
    switch (this) {
      case StaffPermission.fullAccess:
        return 'Full Access / Admin';
      case StaffPermission.inventoryManager:
        return 'Item & Inventory Manager';
      case StaffPermission.stockCounting:
        return 'Stock Counting Only';
      case StaffPermission.readOnly:
        return 'Read-Only Access';
    }
  }

  String get description {
    switch (this) {
      case StaffPermission.fullAccess:
        return 'Full permission to add, edit, delete items, stock counts, and view confidential cost/margin details.';
      case StaffPermission.inventoryManager:
        return 'Permission to add, edit, delete items and manage stock counts without access to cost price or profit margins.';
      case StaffPermission.stockCounting:
        return 'Permission to update specific item counts and inventory quantities only.';
      case StaffPermission.readOnly:
        return 'Permission to view shop data and items without any modification rights.';
    }
  }

  bool get canModifyItems =>
      this == StaffPermission.fullAccess || this == StaffPermission.inventoryManager;
  bool get canUpdateStockCount =>
      this == StaffPermission.fullAccess ||
      this == StaffPermission.inventoryManager ||
      this == StaffPermission.stockCounting;
  bool get canViewCostPrice => this == StaffPermission.fullAccess;
  bool get canManageStaff => false; // Only owner can manage staff
}
