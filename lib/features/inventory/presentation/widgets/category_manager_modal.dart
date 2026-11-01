import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/app_theme.dart';
import 'package:shop_sync_app/core/widgets/glass_container.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

class CategoryManagerModal extends StatefulWidget {
  const CategoryManagerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const CategoryManagerModal(),
    );
  }

  static Future<void> showEditCategoryDialog(
    BuildContext context,
    AppStateProvider appState,
    String categoryName,
  ) async {
    if (!appState.canManageCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Permission Restricted: Only Shop Owner and Full Access Staff can edit categories.',
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

    final editController = TextEditingController(text: categoryName);
    final formKey = GlobalKey<FormState>();

    // Count how many items currently use this category
    final affectedItemCount = appState.inventoryList
        .where((i) => i.category.trim().toLowerCase() == categoryName.trim().toLowerCase())
        .length;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                              Icons.edit_note_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Category Name',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Rename "$categoryName"',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 18),

                    // Information banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryLight),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              affectedItemCount > 0
                                  ? '$affectedItemCount inventory item(s) will automatically update to the new category name.'
                                  : 'No products are currently assigned to this category.',
                              style: GoogleFonts.outfit(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Category Name *',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: editController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Smartphones, Fresh Produce',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Category name cannot be empty';
                        if (trimmed.length < 2) return 'Category name is too short';
                        final conflict = appState.allProductCategories.any(
                          (c) =>
                              c.toLowerCase() == trimmed.toLowerCase() &&
                              c.toLowerCase() != categoryName.trim().toLowerCase(),
                        );
                        if (conflict) {
                          return 'Another category with this name already exists';
                        }
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
                                final newName = editController.text.trim();
                                final success = appState.editCategory(categoryName, newName);
                                Navigator.pop(dialogCtx);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Category renamed to "$newName" successfully!'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Save Changes',
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
        ),
      );
    },
  );
  }

  @override
  State<CategoryManagerModal> createState() => _CategoryManagerModalState();
}

class _CategoryManagerModalState extends State<CategoryManagerModal> {
  final _newCategoryController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();
  bool _isAddingMode = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _handleAddCategory(AppStateProvider appState) {
    if (_addFormKey.currentState?.validate() ?? false) {
      final name = _newCategoryController.text.trim();
      final added = appState.addCategory(name);
      if (added) {
        _newCategoryController.clear();
        setState(() => _isAddingMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" created successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.isCategoryLimitReached
                  ? 'Limit reached: Maximum ${appState.maxCategories} categories allowed.'
                  : 'Unable to add category.',
            ),
            backgroundColor: AppColors.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final categories = appState.allProductCategories;
    final canManage = appState.canManageCategories;
    final isLimitReached = appState.isCategoryLimitReached;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
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
                            child: const Icon(
                              Icons.category_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Categories',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLimitReached
                                        ? AppColors.accentAmber.withValues(alpha: 0.2)
                                        : AppColors.accentEmerald.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${categories.length}/${appState.maxCategories} Categories',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isLimitReached
                                          ? AppColors.accentAmber
                                          : AppColors.accentEmerald,
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
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

              // Limit notice banner when limit is reached
              if (isLimitReached) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.accentAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Maximum limit of 5 categories reached. You can edit any category name below.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Inline Add Category Form if adding
              if (_isAddingMode && !isLimitReached && canManage) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Form(
                    key: _addFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'New Category Name',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _newCategoryController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Footwear, Beverages',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          validator: (val) {
                            final trimmed = val?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Enter a category name';
                            if (trimmed.length < 2) return 'Too short';
                            if (categories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
                              return 'Category already exists';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isAddingMode = false),
                              child: Text('Cancel', style: GoogleFonts.outfit()),
                            ),
                            const SizedBox(width: 8),
                            GlowingGlassButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              onPressed: () => _handleAddCategory(appState),
                              child: Text(
                                'Save Category',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Categories List
              Text(
                'Available Categories (Max ${appState.maxCategories})',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final itemCount = appState.inventoryList
                      .where((i) => i.category.trim().toLowerCase() == cat.trim().toLowerCase())
                      .length;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.label_rounded,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                itemCount == 1 ? '1 product' : '$itemCount products',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canManage) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            color: AppColors.primaryLight,
                            tooltip: 'Edit Category Name',
                            onPressed: () {
                              CategoryManagerModal.showEditCategoryDialog(
                                context,
                                appState,
                                cat,
                              );
                            },
                          ),
                          if (categories.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: AppColors.accentRose,
                              tooltip: 'Delete Category',
                              onPressed: () {
                                _confirmDeleteCategory(context, appState, cat, itemCount);
                              },
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Bottom Actions
              Row(
                children: [
                  if (!isLimitReached && canManage && !_isAddingMode) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Add (${appState.remainingCategorySlots} left)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => setState(() => _isAddingMode = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: GlowingGlassButton(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
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
  }

  void _confirmDeleteCategory(
    BuildContext context,
    AppStateProvider appState,
    String categoryName,
    int itemCount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$categoryName"?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          itemCount > 0
              ? 'There are $itemCount product(s) in this category. Deleting it will reassign these products to another category.'
              : 'Are you sure you want to delete this category?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
            onPressed: () {
              Navigator.pop(ctx);
              appState.deleteCategory(categoryName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "$categoryName" deleted.'),
                  backgroundColor: AppColors.accentRose,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
