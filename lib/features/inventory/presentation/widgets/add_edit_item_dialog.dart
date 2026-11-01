import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';
import 'package:shop_sync_app/features/inventory/presentation/widgets/category_manager_modal.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class AddEditItemDialog extends StatefulWidget {
  final InventoryItem? item;
  final Function(InventoryItem) onSave;

  const AddEditItemDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    InventoryItem? item,
    required Function(InventoryItem) onSave,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AddEditItemDialog(item: item, onSave: onSave),
    );
  }

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _minThresholdController;
  String _selectedCategory = 'Electronics';

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _priceController = TextEditingController(text: item != null ? item.price.toString() : '');
    _costPriceController = TextEditingController(text: item != null ? item.costPrice.toString() : '');
    _quantityController = TextEditingController(text: item != null ? item.quantity.toString() : '10');
    _minThresholdController = TextEditingController(text: item != null ? item.minThreshold.toString() : '5');
    if (item != null && item.category.isNotEmpty) {
      _selectedCategory = item.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _minThresholdController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim().toUpperCase();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final costPrice = double.tryParse(_costPriceController.text) ?? (price * 0.6);
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final minThreshold = int.tryParse(_minThresholdController.text) ?? 5;

    if (name.isEmpty || sku.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid product name, SKU, and retail price.')),
      );
      return;
    }

    final item = InventoryItem(
      id: widget.item?.id ?? 'inv_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sku: sku,
      category: _selectedCategory,
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      minThreshold: minThreshold,
      lastUpdated: DateTime.now(),
    );

    widget.onSave(item);
    Navigator.pop(context);
  }

  Future<void> _showAddCategoryDialog(BuildContext context, AppStateProvider? appState) async {
    if (appState != null && !appState.canManageCategories) {
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

    if (appState != null && appState.isCategoryLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum limit of ${appState.maxCategories} categories reached. Please edit an existing category.'),
          backgroundColor: AppColors.accentAmber,
          behavior: SnackBarBehavior.floating,
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
                                if (appState != null) {
                                  appState.addCategory(newCat);
                                }
                                setState(() {
                                  _selectedCategory = newCat;
                                });
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
    final isEditing = widget.item != null;

    AppStateProvider? appState;
    try {
      appState = Provider.of<AppStateProvider>(context);
    } catch (_) {}

    final canManageCategories = appState?.canManageCategories ?? true;
    final availableCategories = List<String>.from(
      appState?.allProductCategories ?? AppStateProvider.defaultProductCategories,
    );
    if (!availableCategories.contains(_selectedCategory) && _selectedCategory.isNotEmpty) {
      availableCategories.insert(0, _selectedCategory);
    }

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Inventory Product' : 'Add New Inventory Product',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Product Name', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Mechanical RGB Keyboard',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 400;

                    final skuField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SKU Code', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. PER-MK-104',
                            prefixIcon: Icon(Icons.qr_code_rounded),
                          ),
                        ),
                      ],
                    );

                    final categoryField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Category',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (canManageCategories) ...[
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    if (appState?.isCategoryLimitReached ?? false) {
                                      CategoryManagerModal.show(context);
                                    } else {
                                      _showAddCategoryDialog(context, appState);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          (appState?.isCategoryLimitReached ?? false)
                                              ? Icons.tune_rounded
                                              : Icons.add_circle_outline_rounded,
                                          size: 14,
                                          color: AppColors.primaryLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (appState?.isCategoryLimitReached ?? false)
                                              ? 'Manage (5/5)'
                                              : '+ Add',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedCategory),
                          isExpanded: true,
                          initialValue: availableCategories.contains(_selectedCategory) ? _selectedCategory : availableCategories.firstOrNull,
                          items: [
                            ...availableCategories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: GoogleFonts.outfit(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            if (canManageCategories) ...[
                              if (appState == null || !appState.isCategoryLimitReached)
                                DropdownMenuItem(
                                  value: '__ADD_NEW__',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                                      const SizedBox(width: 6),
                                      Text(
                                        '+ Add New Category...',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              DropdownMenuItem(
                                value: '__MANAGE_CATEGORIES__',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.accentEmerald),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Manage / Edit Categories...',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          onChanged: (val) {
                            if (val == '__ADD_NEW__') {
                              _showAddCategoryDialog(context, appState);
                            } else if (val == '__MANAGE_CATEGORIES__') {
                              CategoryManagerModal.show(context);
                            } else if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    );

                    final priceField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retail Price (\$)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                        ),
                      ],
                    );

                    final costField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost Price (\$)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.price_change_outlined),
                          ),
                        ),
                      ],
                    );

                    final qtyField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Quantity', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.inventory_rounded),
                          ),
                        ),
                      ],
                    );

                    final thresholdField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Low Stock Alert At', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _minThresholdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '5',
                            prefixIcon: Icon(Icons.warning_amber_rounded),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          skuField,
                          const SizedBox(height: 16),
                          categoryField,
                          const SizedBox(height: 16),
                          priceField,
                          const SizedBox(height: 16),
                          costField,
                          const SizedBox(height: 16),
                          qtyField,
                          const SizedBox(height: 16),
                          thresholdField,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: skuField),
                            const SizedBox(width: 16),
                            Expanded(child: categoryField),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: priceField),
                            const SizedBox(width: 16),
                            Expanded(child: costField),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: qtyField),
                            const SizedBox(width: 16),
                            Expanded(child: thresholdField),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                GlowingGlassButton(
                  onPressed: _submit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.save_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isEditing ? 'Save Product Changes' : 'Create Inventory Item',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
