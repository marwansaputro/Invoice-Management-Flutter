import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../products/add_product_sheet.dart';

const _uuid = Uuid();

/// How the value typed into the Discount field should be interpreted:
/// a flat Rupiah amount, or a percentage of the item's line subtotal.
enum _DiscountType { flat, percent }

/// Bottom sheet form for adding or editing a single invoice item
/// (spec section 12): name, price, quantity, discount, tax.
class AddItemSheet extends ConsumerStatefulWidget {
  final InvoiceItem? existing;
  const AddItemSheet({super.key, this.existing});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _qty;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  _DiscountType _discountType = _DiscountType.flat;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e != null ? _trim(e.price) : '');
    _qty = TextEditingController(text: e != null ? _trim(e.quantity) : '1');
    _discount = TextEditingController(text: e != null ? _trim(e.discount) : '');
    _tax = TextEditingController(text: e != null ? _trim(e.tax) : '');
  }

  String _trim(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  double get _flatDiscount {
    final entered = double.tryParse(_discount.text.replaceAll(',', '')) ?? 0;
    if (_discountType == _DiscountType.flat) return entered;
    final price = double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
    final qty = double.tryParse(_qty.text.replaceAll(',', '')) ?? 1;
    return price * qty * entered / 100;
  }

  Future<void> _pickFromCatalog() async {
    final products = ref.read(productRepositoryProvider);
    final selected = await showAppBottomSheet<Object>(
      context,
      child: _ProductPickerSheet(products: products),
    );
    if (!mounted) return;
    if (selected == 'NEW') {
      final created = await showAppBottomSheet<Map<String, String>>(context, child: const AddProductSheet());
      if (created == null) return;
      final product = ref.read(productRepositoryProvider.notifier).add(
            name: created['name']!,
            price: double.tryParse(created['price'] ?? '') ?? 0,
          );
      _applyProduct(product);
    } else if (selected is Product) {
      _applyProduct(selected);
    }
  }

  void _applyProduct(Product product) {
    setState(() {
      _name.text = product.name;
      _price.text = _trim(product.price);
    });
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final item = InvoiceItem(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _name.text.trim(),
      price: double.tryParse(_price.text.replaceAll(',', '')) ?? 0,
      quantity: double.tryParse(_qty.text.replaceAll(',', '')) ?? 1,
      discount: _flatDiscount,
      tax: double.tryParse(_tax.text.replaceAll(',', '')) ?? 0,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing != null ? l10n.editItemTitle : l10n.addItemTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PressableScale(
            onTap: _pickFromCatalog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.themedPrimary(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.themedPrimary(context)),
                  const SizedBox(width: 6),
                  Text(l10n.chooseFromCatalog,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.themedPrimary(context))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(label: l10n.productNameLabel, controller: _name, hint: l10n.productNameHint),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: l10n.priceLabel,
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: const Padding(padding: EdgeInsets.only(left: 14), child: Text('Rp', style: TextStyle(color: AppColors.textSecondary))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: l10n.quantityLabel,
                controller: _qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: l10n.discount,
                controller: _discount,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: _DiscountTypeDropdown(
                  value: _discountType,
                  onChanged: (v) => setState(() => _discountType = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: l10n.tax,
                controller: _tax,
                hint: AppDatabase.settings.defaultTaxPercent > 0
                    ? l10n.defaultTaxHint(AppDatabase.settings.defaultTaxPercent.toStringAsFixed(0))
                    : '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AppButton(
          label: widget.existing != null ? l10n.saveItemChanges : l10n.addItemTitle,
          icon: Icons.check_rounded,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Compact "%" / "Rp" dropdown shown inside the Discount field, letting
/// the typed value be interpreted as a percentage of the line subtotal
/// or as a flat Rupiah amount.
class _DiscountTypeDropdown extends StatelessWidget {
  final _DiscountType value;
  final ValueChanged<_DiscountType> onChanged;
  const _DiscountTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DiscountType>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: _DiscountType.flat, child: Text('Rp')),
            DropdownMenuItem(value: _DiscountType.percent, child: Text('%')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Lets the user search the saved product catalog and either pick one
/// (returns the [Product]) or jump into creating a new one (returns the
/// string `'NEW'`), mirroring `_CustomerPickerSheet` in Create Invoice.
class _ProductPickerSheet extends ConsumerStatefulWidget {
  final List<Product> products;
  const _ProductPickerSheet({required this.products});

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _searchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final accent = AppColors.themedPrimary(context);
    final filtered = _query.isEmpty
        ? widget.products
        : widget.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectProduct, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        CollapsibleSearchBar(
          controller: _searchController,
          expanded: _searchExpanded,
          hintText: l10n.searchProductHint,
          onToggle: () => setState(() {
            _searchExpanded = !_searchExpanded;
            if (!_searchExpanded) {
              _searchController.clear();
              _query = '';
            }
          }),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(l10n.noProductsFoundInSearch,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: filtered
                        .map((p) => PressableScale(
                              scaleDown: 0.99,
                              onTap: () => Navigator.pop(context, p),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.inventory_2_rounded, color: accent, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(p.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700))),
                                    MoneyText(
                                        value: p.price,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        AppButton(
          label: l10n.newProduct,
          type: AppButtonStyleType.outline,
          expand: true,
          onPressed: () => Navigator.pop(context, 'NEW'),
        ),
      ],
    );
  }
}
