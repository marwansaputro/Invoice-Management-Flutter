import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import 'add_product_sheet.dart';

/// Manage the saved product/service catalog used to pre-fill invoice line
/// items (name + price) instead of retyping them every time.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final result = await showAppBottomSheet<Map<String, String>>(context, child: const AddProductSheet());
    if (result != null) {
      ref.read(productRepositoryProvider.notifier).add(
            name: result['name']!,
            price: double.tryParse(result['price'] ?? '') ?? 0,
          );
      if (mounted) {
        AppSnackbar.show(context, message: AppStrings(ref.read(localeProvider)).productAdded);
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    bool deleted = false;
    final result = await showAppBottomSheet<Map<String, String>>(
      context,
      child: AddProductSheet(
        existing: product,
        onDelete: () {
          ref.read(productRepositoryProvider.notifier).delete(product.id);
          deleted = true;
        },
      ),
    );
    if (deleted || !mounted) return;
    if (result != null) {
      product.name = result['name']!;
      product.price = double.tryParse(result['price'] ?? '') ?? product.price;
      ref.read(productRepositoryProvider.notifier).update(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productRepositoryProvider);
    final l10n = AppStrings(ref.watch(localeProvider));

    final filtered = products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsAndServices),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addProduct),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.productsSubtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CollapsibleSearchBar(
                controller: _searchController,
                expanded: _searching,
                hintText: l10n.searchProductHint,
                onToggle: () {
                  setState(() {
                    _searching = !_searching;
                    if (!_searching) {
                      _searchController.clear();
                      _query = '';
                    }
                  });
                },
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: products.isEmpty ? l10n.noProductsYetTitle : l10n.noProductsFoundTitle,
                      message: products.isEmpty
                          ? l10n.addFirstProductMessage
                          : l10n.tryDifferentSearchTerm,
                      actionLabel: products.isEmpty ? l10n.addProduct : null,
                      onAction: products.isEmpty ? _addProduct : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final product = filtered[i];
                        return AnimatedEntry(
                          delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                          child: AppCard(
                            onTap: () => _editProduct(product),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.themedPrimary(context).withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.inventory_2_rounded,
                                      color: AppColors.themedPrimary(context), size: 19),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                ),
                                MoneyText(
                                    value: product.price,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
