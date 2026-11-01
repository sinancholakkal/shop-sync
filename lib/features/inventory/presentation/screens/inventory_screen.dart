import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/core/widgets/responsive_layout.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';
import 'package:shop_sync_app/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/add_edit_item_dialog.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/category_manager_modal.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  Future<void> _showAddCategoryDialog(BuildContext context, AppStateProvider appState) async {
    if (!appState.canManageCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Permission Restricted: Only Shop Owner and Full Access Staff can add categories.',
                  style: GoogleFonts.outfit(),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (appState.isCategoryLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum limit of ${appState.maxCategories} categories reached. You can edit existing categories.'),
          backgroundColor: AppColors.accentAmber,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Manage',
            textColor: Colors.white,
            onPressed: () => CategoryManagerModal.show(context),
          ),
        ),
      );
      CategoryManagerModal.show(context);
      return;
    }

    final catController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: AppColors.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Category',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Role Authorized: Owner / Full Access Staff',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.accentEmerald,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category Name *',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: catController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Beverages, Furniture, Books',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Please enter a category name';
                        if (trimmed.length < 2) return 'Category name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlowingGlassButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                final newCat = catController.text.trim();
                                appState.addCategory(newCat);
                                setState(() {
                                  _selectedCategory = newCat;
                                });
                                appState.setInventoryFilterCategory(newCat);
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Category "$newCat" created successfully!'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Save Category',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final isOwner = appState.isOwner;
    final permission = appState.effectivePermission;
    final canAddEdit = isOwner || permission.canModifyItems;
    final canCount = isOwner || permission.canUpdateStockCount;

    // Sync selected category if preset externally (e.g. from dashboard banner)
    if (appState.inventoryFilterCategory != _selectedCategory && _searchQuery.isEmpty) {
      _selectedCategory = appState.inventoryFilterCategory;
    }

    final filteredItems = appState.inventoryList.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Low Stock') return item.isLowStock;
      if (_selectedCategory == 'No Item (Out of Stock)' ||
          _selectedCategory == 'No Item' ||
          _selectedCategory == 'Out of Stock') {
        return item.isOutOfStock;
      }
      return item.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          onRefresh: () => appState.refreshAllData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            // Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory & Stock',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track item quantities, unit prices, and replenishment alerts',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canAddEdit) ...[
                          const SizedBox(width: 12),
                          GlowingGlassButton(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            onPressed: () {
                              AddEditItemDialog.show(
                                context,
                                onSave: (newItem) {
                                  appState.addInventoryItem(newItem);
                                },
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Product',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Permission Banner for Staff
                    if (!isOwner) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: canAddEdit
                              ? AppColors.accentPurple.withValues(alpha: 0.15)
                              : (canCount
                                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                                  : AppColors.secondary.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: canAddEdit
                                ? AppColors.accentPurple.withValues(alpha: 0.3)
                                : (canCount
                                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                                    : AppColors.secondary.withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              canAddEdit
                                  ? Icons.security_rounded
                                  : (canCount ? Icons.inventory_2_rounded : Icons.lock_outline_rounded),
                              size: 18,
                              color: canAddEdit
                                  ? AppColors.accentPurple
                                  : (canCount ? AppColors.primaryLight : AppColors.secondary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Role Permission: ${permission.title} - ${permission.description}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Search & Filters Row
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search products by name or SKU...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category chips
                    Builder(
                      builder: (context) {
                        final filterCats = <String>[
                          'All',
                          'Low Stock',
                          'No Item (Out of Stock)',
                          ...appState.allProductCategories,
                        ];

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...filterCats.map((cat) {
                                final isSelected = _selectedCategory == cat;

                                Color selectedColor = AppColors.primary;
                                Color? badgeColor;
                                IconData? chipIcon;
                                String? countBadge;

                                if (cat == 'Low Stock') {
                                  chipIcon = Icons.warning_amber_rounded;
                                  selectedColor = AppColors.accentAmber;
                                  if (appState.lowStockItemCount > 0) {
                                    countBadge = '${appState.lowStockItemCount}';
                                    badgeColor = AppColors.accentAmber;
                                  }
                                } else if (cat == 'No Item (Out of Stock)') {
                                  chipIcon = Icons.remove_circle_outline_rounded;
                                  selectedColor = AppColors.accentRose;
                                  if (appState.outOfStockItemCount > 0) {
                                    countBadge = '${appState.outOfStockItemCount}';
                                    badgeColor = AppColors.accentRose;
                                  }
                                } else if (cat == 'All') {
                                  selectedColor = AppColors.primary;
                                  if (appState.inventoryList.isNotEmpty) {
                                    countBadge = '${appState.inventoryList.length}';
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    avatar: chipIcon != null
                                        ? Icon(
                                            chipIcon,
                                            size: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : (cat == 'No Item (Out of Stock)'
                                                    ? AppColors.accentRose
                                                    : (cat == 'Low Stock'
                                                        ? AppColors.accentAmber
                                                        : (isDark ? Colors.white70 : Colors.black54))),
                                          )
                                        : null,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          cat,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                        if (countBadge != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withValues(alpha: 0.25)
                                                  : (badgeColor ?? (isDark ? Colors.white12 : Colors.black12)).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              countBadge,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (badgeColor ?? (isDark ? Colors.white70 : Colors.black87)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() => _selectedCategory = cat);
                                      appState.setInventoryFilterCategory(cat);
                                    },
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    selectedColor: selectedColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? selectedColor
                                            : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
                                      ),
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              }),
                              if (appState.canManageCategories) ...[
                                if (!appState.isCategoryLimitReached)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ActionChip(
                                      avatar: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 16,
                                        color: AppColors.primaryLight,
                                      ),
                                      label: Text(
                                        'Add Category',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                      side: BorderSide(
                                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onPressed: () => _showAddCategoryDialog(context, appState),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    avatar: Icon(
                                      appState.isCategoryLimitReached
                                          ? Icons.tune_rounded
                                          : Icons.edit_note_rounded,
                                      size: 16,
                                      color: appState.isCategoryLimitReached
                                          ? AppColors.accentAmber
                                          : AppColors.accentEmerald,
                                    ),
                                    label: Text(
                                      'Manage (${appState.allProductCategories.length}/${appState.maxCategories})',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: appState.isCategoryLimitReached
                                            ? AppColors.accentAmber
                                            : AppColors.accentEmerald,
                                      ),
                                    ),
                                    backgroundColor: (appState.isCategoryLimitReached
                                            ? AppColors.accentAmber
                                            : AppColors.accentEmerald)
                                        .withValues(alpha: 0.12),
                                    side: BorderSide(
                                      color: (appState.isCategoryLimitReached
                                              ? AppColors.accentAmber
                                              : AppColors.accentEmerald)
                                          .withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onPressed: () => CategoryManagerModal.show(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid / List Responsive
            filteredItems.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedCategory == 'No Item (Out of Stock)'
                                  ? Icons.check_circle_outline_rounded
                                  : (_selectedCategory == 'Low Stock'
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.inventory_2_outlined),
                              size: 64,
                              color: (_selectedCategory == 'No Item (Out of Stock)' || _selectedCategory == 'Low Stock') &&
                                      appState.inventoryList.isNotEmpty
                                  ? AppColors.accentEmerald.withValues(alpha: 0.7)
                                  : (isDark ? Colors.white24 : Colors.black26),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appState.inventoryList.isEmpty
                                  ? 'No products in inventory yet.'
                                  : (_selectedCategory == 'No Item (Out of Stock)'
                                      ? 'No items are out of stock!'
                                      : (_selectedCategory == 'Low Stock'
                                          ? 'All items are well-stocked!'
                                          : 'No items match your search or filter.')),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              appState.inventoryList.isEmpty
                                  ? 'Tap "+ Add Product" at the top to add your first item.'
                                  : (_selectedCategory == 'No Item (Out of Stock)'
                                      ? 'All products in your shop currently have available stock.'
                                      : (_selectedCategory == 'Low Stock'
                                          ? 'No products have fallen below their minimum threshold.'
                                          : 'Try adjusting your search terms or selecting another category.')),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.isDesktop
                            ? 3
                            : (context.isTablet ? 2 : 1),
                        mainAxisExtent: 235,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];
                          return _InventoryCard(
                            item: item,
                            canModify: canAddEdit,
                            canCount: canCount,
                            onTap: () => ProductDetailScreen.push(context, item.id),
                            onEdit: () {
                              AddEditItemDialog.show(
                                context,
                                item: item,
                                onSave: (updated) {
                                  appState.updateInventoryItem(updated);
                                },
                              );
                            },
                            onDelete: () {
                              _confirmDelete(context, item, () {
                                appState.deleteInventoryItem(item.id);
                              });
                            },
                            onAdjustQuantity: (delta) {
                              final newQty = (item.quantity + delta).clamp(0, 99999);
                              appState.updateStockQuantity(item.id, newQty);
                            },
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    ),
  );
}

  void _confirmDelete(BuildContext context, InventoryItem item, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final bool canModify;
  final bool canCount;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int delta) onAdjustQuantity;

  const _InventoryCard({
    required this.item,
    required this.canModify,
    required this.canCount,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustQuantity,
  });

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: '\$');

    Color badgeColor;
    String badgeText;
    if (item.isOutOfStock) {
      badgeColor = AppColors.accentRose;
      badgeText = 'Out of Stock';
    } else if (item.isLowStock) {
      badgeColor = AppColors.accentAmber;
      badgeText = 'Low Stock (${item.quantity} left)';
    } else {
      badgeColor = AppColors.accentEmerald;
      badgeText = 'In Stock (${item.quantity})';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: category & status badge & menu
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    if (canModify) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (val) {
                          if (val == 'edit') onEdit();
                          if (val == 'delete') onDelete();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Item'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppColors.accentRose)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Title & SKU
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SKU: ${item.sku}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),

          // Price & Stock Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Price',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${_formatRelativeTime(item.priceLastUpdated)}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFmt.format(item.price),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              // Stock Stepper (Available for Full Access or Stock Counting)
              if (canCount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        onPressed: item.quantity > 0 ? () => onAdjustQuantity(-1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        onPressed: () => onAdjustQuantity(1),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${item.quantity} in stock',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
);
  }
}
