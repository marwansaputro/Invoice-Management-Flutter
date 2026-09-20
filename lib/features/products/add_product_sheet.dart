import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';

/// Bottom sheet for creating or editing a saved product/service. Returns a
/// map of field values via Navigator.pop for the caller to persist.
class AddProductSheet extends ConsumerStatefulWidget {
  final Product? existing;
  final VoidCallback? onDelete;
  const AddProductSheet({super.key, this.existing, this.onDelete});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e != null ? _trim(e.price) : '');
  }

  String _trim(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'price': (double.tryParse(_price.text.replaceAll(',', '')) ?? 0).toString(),
    });
  }

  Future<void> _delete() async {
    final confirm = await showScaleFadeDialog<bool>(
      context,
      child: _ConfirmDeleteProductDialog(productName: widget.existing!.name),
    );
    if (confirm == true && mounted) {
      widget.onDelete?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing != null ? l10n.editProductTitle : l10n.newProductTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          AppTextField(
              label: l10n.productNameLabel,
              controller: _name,
              hint: l10n.productNameHint),
          const SizedBox(height: 14),
          AppTextField(
            label: l10n.priceLabel,
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text('Rp', style: TextStyle(color: AppColors.textSecondary))),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: widget.existing != null ? l10n.saveChanges : l10n.addProduct,
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _submit,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: l10n.deleteProduct,
              type: AppButtonStyleType.danger,
              icon: Icons.delete_outline_rounded,
              expand: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmDeleteProductDialog extends ConsumerWidget {
  final String productName;
  const _ConfirmDeleteProductDialog({required this.productName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.solidSurface(context),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 36),
              const SizedBox(height: 14),
              Text(l10n.confirmDeleteProductTitle(productName),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Text(l10n.confirmDeleteProductMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.cancel,
                      type: AppButtonStyleType.outline,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: l10n.delete,
                      type: AppButtonStyleType.danger,
                      onPressed: () => Navigator.pop(context, true),
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
