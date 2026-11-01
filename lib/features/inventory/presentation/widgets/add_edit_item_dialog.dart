import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/features/inventory/domain/models/inventory_item.dart';

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

  final List<String> _categories = [
    'Electronics',
    'Accessories',
    'Apparel',
    'Groceries',
    'Office Supplies',
  ];

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
    if (item != null && _categories.contains(item.category)) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.item != null;

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
                        Text('Category', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedCategory,
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: GoogleFonts.outfit(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
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
