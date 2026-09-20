import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import 'add_item_sheet.dart';

/// Dedicated page listing the invoice's line items, pushed from Create
/// Invoice's "Add Item" row instead of showing the list inline in the
/// (already long) invoice form. Mutates [items] in place so the caller's
/// list is up to date as soon as this screen is popped.
class InvoiceItemsScreen extends ConsumerStatefulWidget {
  final List<InvoiceItem> items;
  const InvoiceItemsScreen({super.key, required this.items});

  @override
  ConsumerState<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends ConsumerState<InvoiceItemsScreen> {
  double get _subtotal => widget.items.fold(0.0, (sum, i) => sum + i.lineSubtotal);

  Future<void> _addItem() async {
    final item = await showAppBottomSheet<InvoiceItem>(context, child: const AddItemSheet());
    if (item != null) setState(() => widget.items.add(item));
  }

  Future<void> _editItem(InvoiceItem item) async {
    final updated = await showAppBottomSheet<InvoiceItem>(context, child: AddItemSheet(existing: item));
    if (updated != null) {
      setState(() {
        final index = widget.items.indexWhere((i) => i.id == item.id);
        if (index != -1) widget.items[index] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemsTitle)),
      body: SafeArea(
        child: widget.items.isEmpty
            ? EmptyState(
                title: l10n.noItemsYetTitle,
                message: l10n.addItemsMessage,
                actionLabel: l10n.addItem,
                onAction: _addItem,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  ...widget.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InvoiceItemRow(
                        item: item,
                        onTap: () => _editItem(item),
                        onDelete: () => setState(() => widget.items.removeWhere((i) => i.id == item.id)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.subtotal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        MoneyText(value: _subtotal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: widget.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addItem),
            ),
    );
  }
}
