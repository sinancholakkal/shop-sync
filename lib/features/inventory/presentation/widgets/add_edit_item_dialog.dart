import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late TextEditingController _costPriceController;
  late TextEditingController _marginController;
  late TextEditingController _priceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _wholesaleMarginController;
  late TextEditingController _quantityController;
  late TextEditingController _minThresholdController;
  late TextEditingController _searchKeywordController;
  late List<String> _searchKeywords;
  String _selectedCategory = 'Electronics';
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _searchKeywordController = TextEditingController();
    _searchKeywords = List<String>.from(item?.searchKeywords ?? []);
    _costPriceController = TextEditingController(
      text: item != null ? (item.costPrice > 0 ? item.costPrice.toStringAsFixed(2) : '') : '',
    );
    _priceController = TextEditingController(
      text: item != null ? (item.price > 0 ? item.price.toStringAsFixed(2) : '') : '',
    );
    _wholesalePriceController = TextEditingController(
      text: item != null ? (item.wholesalePrice > 0 ? item.wholesalePrice.toStringAsFixed(2) : '') : '',
    );

    double initialMargin = 20.0;
    if (item != null) {
      if (item.marginPercent != null) {
        initialMargin = item.marginPercent!;
      } else if (item.costPrice > 0 && item.price > 0) {
        initialMargin = item.calculatedMarginPercent;
      }
    }
    _marginController = TextEditingController(
      text: initialMargin.toStringAsFixed(initialMargin.truncateToDouble() == initialMargin ? 0 : 1),
    );

    double initialWholesaleMargin = 15.0;
    if (item != null) {
      if (item.wholesaleMarginPercent != null) {
        initialWholesaleMargin = item.wholesaleMarginPercent!;
      } else if (item.costPrice > 0 && item.wholesalePrice > 0) {
        initialWholesaleMargin = item.calculatedWholesaleMarginPercent;
      }
    }
    _wholesaleMarginController = TextEditingController(
      text: initialWholesaleMargin.toStringAsFixed(
        initialWholesaleMargin.truncateToDouble() == initialWholesaleMargin ? 0 : 1,
      ),
    );

    _quantityController = TextEditingController(text: item != null ? item.quantity.toString() : '10');
    _minThresholdController = TextEditingController(text: item != null ? item.minThreshold.toString() : '5');
    if (item != null && item.category.isNotEmpty) {
      _selectedCategory = item.category;
    }

    if (item == null) {
      SharedPreferences.getInstance().then((prefs) {
        final savedMargin = prefs.getDouble('preferred_margin_percent');
        if (savedMargin != null && mounted && _marginController.text == '20') {
          setState(() {
            _marginController.text = savedMargin.toStringAsFixed(
              savedMargin.truncateToDouble() == savedMargin ? 0 : 1,
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _costPriceController.dispose();
    _marginController.dispose();
    _priceController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMarginController.dispose();
    _quantityController.dispose();
    _minThresholdController.dispose();
    _searchKeywordController.dispose();
    super.dispose();
  }

  void _addSearchKeyword() {
    final keyword = _searchKeywordController.text.trim();
    if (keyword.isNotEmpty) {
      if (!_searchKeywords.any((k) => k.toLowerCase() == keyword.toLowerCase())) {
        setState(() {
          _searchKeywords.add(keyword);
          _searchKeywordController.clear();
        });
      } else {
        _searchKeywordController.clear();
      }
    }
  }

  void _removeSearchKeyword(String keyword) {
    setState(() {
      _searchKeywords.remove(keyword);
    });
  }

  void _onCostPriceChanged(String val) {
    if (_isCalculating) return;
    final cost = double.tryParse(val.trim());
    final margin = double.tryParse(_marginController.text.trim());
    final wsMargin = double.tryParse(_wholesaleMarginController.text.trim());
    if (cost != null && cost >= 0) {
      _isCalculating = true;
      if (margin != null) {
        final retail = cost + (cost * (margin / 100.0));
        _priceController.text = retail > 0 ? retail.toStringAsFixed(2) : '';
      }
      if (wsMargin != null) {
        final ws = cost + (cost * (wsMargin / 100.0));
        _wholesalePriceController.text = ws > 0 ? ws.toStringAsFixed(2) : '';
      }
      _isCalculating = false;
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _onMarginChanged(String val) {
    if (_isCalculating) return;
    final margin = double.tryParse(val.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    if (cost != null && cost >= 0 && margin != null) {
      _isCalculating = true;
      final retail = cost + (cost * (margin / 100.0));
      _priceController.text = retail > 0 ? retail.toStringAsFixed(2) : '';
      _isCalculating = false;
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _setMarginPreset(double percent) {
    _isCalculating = true;
    _marginController.text = percent.truncateToDouble() == percent
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
    final cost = double.tryParse(_costPriceController.text.trim());
    if (cost != null && cost >= 0) {
      final retail = cost + (cost * (percent / 100.0));
      _priceController.text = retail > 0 ? retail.toStringAsFixed(2) : '';
    }
    _isCalculating = false;
    setState(() {});
  }

  void _onRetailPriceChanged(String val) {
    if (_isCalculating) return;
    final retail = double.tryParse(val.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    if (retail != null && cost != null && cost > 0) {
      _isCalculating = true;
      final margin = ((retail - cost) / cost) * 100.0;
      if (margin >= 0) {
        _marginController.text = margin.truncateToDouble() == margin
            ? margin.toStringAsFixed(0)
            : margin.toStringAsFixed(1);
      }
      _isCalculating = false;
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _onWholesaleMarginChanged(String val) {
    if (_isCalculating) return;
    final margin = double.tryParse(val.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    if (cost != null && cost >= 0 && margin != null) {
      _isCalculating = true;
      final ws = cost + (cost * (margin / 100.0));
      _wholesalePriceController.text = ws > 0 ? ws.toStringAsFixed(2) : '';
      _isCalculating = false;
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _setWholesaleMarginPreset(double percent) {
    _isCalculating = true;
    _wholesaleMarginController.text = percent.truncateToDouble() == percent
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
    final cost = double.tryParse(_costPriceController.text.trim());
    if (cost != null && cost >= 0) {
      final ws = cost + (cost * (percent / 100.0));
      _wholesalePriceController.text = ws > 0 ? ws.toStringAsFixed(2) : '';
    }
    _isCalculating = false;
    setState(() {});
  }

  void _onWholesalePriceChanged(String val) {
    if (_isCalculating) return;
    final ws = double.tryParse(val.trim());
    final cost = double.tryParse(_costPriceController.text.trim());
    if (ws != null && cost != null && cost > 0) {
      _isCalculating = true;
      final margin = ((ws - cost) / cost) * 100.0;
      if (margin >= 0) {
        _wholesaleMarginController.text = margin.truncateToDouble() == margin
            ? margin.toStringAsFixed(0)
            : margin.toStringAsFixed(1);
      }
      _isCalculating = false;
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void _submit() {
    AppStateProvider? appState;
    try {
      appState = Provider.of<AppStateProvider>(context, listen: false);
    } catch (_) {}

    final canViewCost = appState?.canViewCostPrice ?? true;
    final existingItem = widget.item;

    final name = _nameController.text.trim();
    final sku = _skuController.text.trim().toUpperCase();

    // Preserve confidential cost price and margin if staff does not have cost permission
    final costPrice = canViewCost
        ? (double.tryParse(_costPriceController.text.trim()) ?? 0.0)
        : (existingItem?.costPrice ?? 0.0);

    final marginPercent = canViewCost
        ? (double.tryParse(_marginController.text.trim()) ?? 20.0)
        : existingItem?.marginPercent;

    final wholesaleMarginPercent = canViewCost
        ? (double.tryParse(_wholesaleMarginController.text.trim()) ?? 15.0)
        : existingItem?.wholesaleMarginPercent;

    var price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0 && costPrice > 0 && marginPercent != null) {
      price = costPrice + (costPrice * (marginPercent / 100.0));
    }

    var wholesalePrice = double.tryParse(_wholesalePriceController.text.trim()) ?? 0.0;
    if (wholesalePrice <= 0 && costPrice > 0 && wholesaleMarginPercent != null) {
      wholesalePrice = costPrice + (costPrice * (wholesaleMarginPercent / 100.0));
    } else if (wholesalePrice <= 0 && price > 0) {
      wholesalePrice = price;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final minThreshold = int.tryParse(_minThresholdController.text.trim()) ?? 5;

    if (name.isEmpty || sku.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid product name, SKU, and retail price.')),
      );
      return;
    }

    // Save preferred margin locally if permitted
    if (canViewCost && marginPercent != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('preferred_margin_percent', marginPercent);
      });
    }

    final now = DateTime.now();
    final priceChanged = (existingItem != null) &&
        (existingItem.price != price ||
         existingItem.wholesalePrice != wholesalePrice ||
         existingItem.costPrice != costPrice);
    final stockChanged = (existingItem != null) && (existingItem.quantity != quantity);

    List<PriceHistoryEntry> history;
    if (existingItem != null && existingItem.priceHistory.isNotEmpty) {
      history = List.from(existingItem.priceHistory);
      if (priceChanged) {
        history.add(
          PriceHistoryEntry(
            timestamp: now,
            price: price,
            wholesalePrice: wholesalePrice,
            costPrice: costPrice,
            marginPercent: marginPercent,
            wholesaleMarginPercent: wholesaleMarginPercent,
            note: 'Price modified via Edit',
          ),
        );
      }
    } else {
      history = [
        PriceHistoryEntry(
          timestamp: now,
          price: price,
          wholesalePrice: wholesalePrice,
          costPrice: costPrice,
          marginPercent: marginPercent,
          wholesaleMarginPercent: wholesaleMarginPercent,
          note: 'Initial Price',
        ),
      ];
    }

    final item = InventoryItem(
      id: existingItem?.id ?? 'inv_${now.millisecondsSinceEpoch}',
      itemNumber: (existingItem != null && existingItem.itemNumber > 0)
          ? existingItem.itemNumber
          : (appState?.nextItemNumber ?? 1),
      searchKeywords: _searchKeywords,
      name: name,
      sku: sku,
      category: _selectedCategory,
      price: price,
      wholesalePrice: wholesalePrice,
      costPrice: costPrice,
      marginPercent: marginPercent,
      wholesaleMarginPercent: wholesaleMarginPercent,
      quantity: quantity,
      minThreshold: minThreshold,
      lastUpdated: now,
      priceLastUpdated: priceChanged ? now : (existingItem?.priceLastUpdated ?? now),
      stockLastUpdated: stockChanged ? now : (existingItem?.stockLastUpdated ?? now),
      createdAt: existingItem?.createdAt ?? now,
      priceHistory: history,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
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
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    'Item #${(widget.item != null && widget.item!.itemNumber > 0) ? widget.item!.itemNumber : (appState?.nextItemNumber ?? 1)} (Auto-Assigned)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
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

                // Suggested Search Keys / Aliases
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Suggested Search Keys / Aliases',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Add alternative names or keywords (e.g. "Sieve", "Filter") so staff can find this item quickly in search.',
                      child: Icon(Icons.info_outline_rounded, size: 15, color: isDark ? Colors.white60 : Colors.black45),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Alternative search keywords or aliases (e.g. Filter, Mesh, Sieve).',
                  style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black45),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchKeywordController,
                        onSubmitted: (_) => _addSearchKeyword(),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Type keyword (e.g. Sieve) & tap +',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primaryLight),
                            tooltip: 'Add Keyword',
                            onPressed: _addSearchKeyword,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_searchKeywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _searchKeywords.map((keyword) {
                      return Chip(
                        label: Text(
                          keyword,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 15),
                        deleteIconColor: AppColors.accentRose,
                        onDeleted: () => _removeSearchKeyword(keyword),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
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

                    final canViewCost = appState?.canViewCostPrice ?? true;
                    final costVal = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
                    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    final wholesaleVal = double.tryParse(_wholesalePriceController.text.trim()) ?? 0.0;
                    final profitPerUnit = priceVal - costVal;
                    final wsProfitPerUnit = wholesaleVal - costVal;
                    final currentMargin = double.tryParse(_marginController.text.trim());
                    final currentWsMargin = double.tryParse(_wholesaleMarginController.text.trim());

                    final costField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost Price (\$)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _onCostPriceChanged,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.price_change_outlined),
                          ),
                        ),
                      ],
                    );

                    final marginField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Retail Margin (%)',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (costVal > 0 && profitPerUnit > 0) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '+\$${profitPerUnit.toStringAsFixed(2)} profit',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentEmerald,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _marginController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _onMarginChanged,
                          decoration: InputDecoration(
                            hintText: '20',
                            prefixIcon: const Icon(Icons.percent_rounded),
                            suffixText: '%',
                            suffixStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    );

                    final presetChips = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [10.0, 15.0, 20.0, 25.0, 30.0, 50.0].map((preset) {
                        final isSelected = currentMargin != null && (currentMargin - preset).abs() < 0.01;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _setMarginPreset(preset),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
                              ),
                            ),
                            child: Text(
                              '+${preset.toInt()}%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );

                    final priceField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Retail Price (\$)',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(Selling)',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _onRetailPriceChanged,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                        ),
                      ],
                    );

                    final wholesaleMarginField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Wholesale Margin (%)',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (costVal > 0 && wsProfitPerUnit > 0) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '+\$${wsProfitPerUnit.toStringAsFixed(2)} profit',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentEmerald,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _wholesaleMarginController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _onWholesaleMarginChanged,
                          decoration: InputDecoration(
                            hintText: '15',
                            prefixIcon: const Icon(Icons.percent_rounded),
                            suffixText: '%',
                            suffixStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentIndigo,
                            ),
                          ),
                        ),
                      ],
                    );

                    final wholesalePresetChips = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((preset) {
                        final isSelected = currentWsMargin != null && (currentWsMargin - preset).abs() < 0.01;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _setWholesaleMarginPreset(preset),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentIndigo.withValues(alpha: 0.25)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentIndigo
                                    : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
                              ),
                            ),
                            child: Text(
                              '+${preset.toInt()}%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.accentIndigo
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );

                    final wholesalePriceField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Wholesale Price (\$)',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(Bulk / B2B)',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _wholesalePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _onWholesalePriceChanged,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.storefront_rounded),
                          ),
                        ),
                      ],
                    );

                    Widget? costRestrictedNotice;
                    if (!canViewCost) {
                      costRestrictedNotice = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.accentIndigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cost price and profit margins are confidential to Shop Owner & Full Access Staff.',
                                style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.accentIndigo),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget? summaryBanner;
                    if (canViewCost && costVal > 0 && priceVal > 0) {
                      final isProfit = profitPerUnit >= 0;
                      final badgeColor = isProfit ? AppColors.accentEmerald : AppColors.accentRose;
                      final effectiveMargin = ((priceVal - costVal) / costVal) * 100.0;
                      final wsProfit = wholesaleVal > 0 ? wholesaleVal - costVal : 0.0;

                      summaryBanner = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 18,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isProfit
                                        ? 'Retail Profit: \$${profitPerUnit.toStringAsFixed(2)} per item (${effectiveMargin.toStringAsFixed(1)}% margin)'
                                        : 'Warning: Retail selling at loss of \$${(-profitPerUnit).toStringAsFixed(2)} per item',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (wholesaleVal > 0) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  'Wholesale Profit: \$${wsProfit.toStringAsFixed(2)} per item (${costVal > 0 ? ((wsProfit / costVal) * 100).toStringAsFixed(1) : '0'}% margin)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          skuField,
                          const SizedBox(height: 16),
                          categoryField,
                          const SizedBox(height: 16),
                          if (canViewCost) ...[
                            costField,
                            const SizedBox(height: 16),
                            marginField,
                            const SizedBox(height: 8),
                            presetChips,
                            const SizedBox(height: 16),
                          ] else if (costRestrictedNotice != null) ...[
                            costRestrictedNotice,
                            const SizedBox(height: 16),
                          ],
                          priceField,
                          const SizedBox(height: 16),
                          if (canViewCost) ...[
                            wholesaleMarginField,
                            const SizedBox(height: 8),
                            wholesalePresetChips,
                            const SizedBox(height: 16),
                          ],
                          wholesalePriceField,
                          if (summaryBanner != null) ...[
                            const SizedBox(height: 12),
                            summaryBanner,
                          ],
                          const SizedBox(height: 16),
                          qtyField,
                          const SizedBox(height: 16),
                          thresholdField,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: skuField),
                            const SizedBox(width: 16),
                            Expanded(child: categoryField),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (canViewCost) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: costField),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    marginField,
                                    const SizedBox(height: 6),
                                    presetChips,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ] else if (costRestrictedNotice != null) ...[
                          costRestrictedNotice,
                          const SizedBox(height: 16),
                        ],
                        priceField,
                        if (canViewCost) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              wholesaleMarginField,
                              const SizedBox(height: 6),
                              wholesalePresetChips,
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        wholesalePriceField,
                        if (summaryBanner != null) ...[
                          const SizedBox(height: 12),
                          summaryBanner,
                        ],
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
