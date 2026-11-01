import '../../features/auth/domain/models/user_role.dart';
import '../../features/inventory/domain/models/inventory_item.dart';
import '../../features/staff/domain/models/staff_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

class MockDataRepository {
  static const String defaultShopId = 'SHOP-SYNC-8821';
  static const String defaultShopName = 'Apex Retail & Tech Hub';
  static const String defaultOwnerEmail = 'owner@apexretail.io';

  static List<StaffMember> getInitialStaff() {
    return [
      StaffMember(
        id: 'stf_01',
        name: 'Sarah Jenkins',
        email: 'sarah.j@apexretail.io',
        permission: StaffPermission.fullAccess,
        isActive: true,
        isApproved: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 45)),
        shopId: defaultShopId,
      ),
      StaffMember(
        id: 'stf_02',
        name: 'Alex Rivera',
        email: 'alex.r@apexretail.io',
        permission: StaffPermission.stockCounting,
        isActive: true,
        isApproved: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 20)),
        shopId: defaultShopId,
      ),
      StaffMember(
        id: 'stf_03',
        name: 'David Kim',
        email: 'david.k@apexretail.io',
        permission: StaffPermission.readOnly,
        isActive: true,
        isApproved: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 8)),
        shopId: defaultShopId,
      ),
      StaffMember(
        id: 'stf_04',
        name: 'Emma Watson',
        email: 'emma.w@apexretail.io',
        permission: StaffPermission.stockCounting,
        isActive: false, // inactive/suspended
        isApproved: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 2)),
        shopId: defaultShopId,
      ),
    ];
  }

  static List<InventoryItem> getInitialInventory() {
    final now = DateTime.now();
    return [
      InventoryItem(
        id: 'inv_01',
        name: 'HyperX Wireless Noise-Cancelling Headphones',
        sku: 'AUD-HX-001',
        category: 'Electronics',
        price: 199.99,
        costPrice: 120.00,
        quantity: 24,
        minThreshold: 10,
        lastUpdated: now.subtract(const Duration(hours: 3)),
      ),
      InventoryItem(
        id: 'inv_02',
        name: 'Ultra-Fast 65W GaN Dual Charger',
        sku: 'PWR-GN-065',
        category: 'Accessories',
        price: 49.50,
        costPrice: 22.00,
        quantity: 6, // Low stock!
        minThreshold: 15,
        lastUpdated: now.subtract(const Duration(hours: 5)),
      ),
      InventoryItem(
        id: 'inv_03',
        name: 'Ergonomic Mechanical Keyboard RGB',
        sku: 'PER-MK-104',
        category: 'Electronics',
        price: 129.00,
        costPrice: 75.00,
        quantity: 18,
        minThreshold: 8,
        lastUpdated: now.subtract(const Duration(days: 1)),
      ),
      InventoryItem(
        id: 'inv_04',
        name: 'Precision Optical Gaming Mouse',
        sku: 'PER-GM-089',
        category: 'Electronics',
        price: 59.99,
        costPrice: 30.00,
        quantity: 3, // Very low stock!
        minThreshold: 12,
        lastUpdated: now.subtract(const Duration(hours: 12)),
      ),
      InventoryItem(
        id: 'inv_05',
        name: 'Braided Type-C Thunderbolt Cable 2m',
        sku: 'CBL-TB-002',
        category: 'Accessories',
        price: 24.99,
        costPrice: 8.50,
        quantity: 45,
        minThreshold: 20,
        lastUpdated: now.subtract(const Duration(days: 2)),
      ),
      InventoryItem(
        id: 'inv_06',
        name: 'Aluminum Laptop Stand 360 Rotating',
        sku: 'ACC-LS-360',
        category: 'Accessories',
        price: 39.00,
        costPrice: 18.00,
        quantity: 0, // Out of stock!
        minThreshold: 5,
        lastUpdated: now.subtract(const Duration(days: 3)),
      ),
      InventoryItem(
        id: 'inv_07',
        name: 'Smart 4K Web Camera w/ Dual Mics',
        sku: 'CAM-4K-022',
        category: 'Electronics',
        price: 89.99,
        costPrice: 48.00,
        quantity: 14,
        minThreshold: 6,
        lastUpdated: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }

  static List<ShopTransaction> getInitialTransactions() {
    final now = DateTime.now();
    return [
      ShopTransaction(
        id: 'tx_01',
        invoiceNo: 'INV-2026-1089',
        timestamp: now.subtract(const Duration(minutes: 18)),
        staffName: 'Sarah Jenkins',
        customerName: 'Marcus Bell',
        totalAmount: 249.49,
        paymentMethod: PaymentMethod.card,
        itemsCount: 2,
      ),
      ShopTransaction(
        id: 'tx_02',
        invoiceNo: 'INV-2026-1088',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 22)),
        staffName: 'Alex Rivera',
        customerName: 'Elena Rostova',
        totalAmount: 74.49,
        paymentMethod: PaymentMethod.upi,
        itemsCount: 2,
      ),
      ShopTransaction(
        id: 'tx_03',
        invoiceNo: 'INV-2026-1087',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 45)),
        staffName: 'Sarah Jenkins',
        customerName: 'Kenji Sato',
        totalAmount: 199.99,
        paymentMethod: PaymentMethod.qrPay,
        itemsCount: 1,
      ),
      ShopTransaction(
        id: 'tx_04',
        invoiceNo: 'INV-2026-1086',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 10)),
        staffName: 'Owner Admin',
        customerName: 'Priya Sharma',
        totalAmount: 168.99,
        paymentMethod: PaymentMethod.cash,
        itemsCount: 3,
      ),
      ShopTransaction(
        id: 'tx_05',
        invoiceNo: 'INV-2026-1085',
        timestamp: now.subtract(const Duration(hours: 6)),
        staffName: 'David Kim',
        customerName: 'Liam O\'Connor',
        totalAmount: 49.50,
        paymentMethod: PaymentMethod.card,
        itemsCount: 1,
      ),
    ];
  }
}
