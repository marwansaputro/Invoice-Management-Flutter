import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../invoice_create/create_invoice_screen.dart';
import '../invoice_preview/invoice_preview_screen.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceRepositoryProvider);
    final invoice = invoices.where((i) => i.id == invoiceId).cast<Invoice?>().firstOrNull;
    final l10n = AppStrings(ref.watch(localeProvider));

    if (invoice == null) {
      return Scaffold(body: Center(child: Text(l10n.invoiceNotFound)));
    }

    final customer = ref.watch(customerRepositoryProvider.notifier).byId(invoice.customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: l10n.duplicateTooltip,
            onPressed: () {
              final copy = ref.read(invoiceRepositoryProvider.notifier).duplicate(invoice);
              AppSnackbar.show(context, message: l10n.invoiceDuplicatedAs(copy.invoiceNumber));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: l10n.editTooltip,
            onPressed: () => Navigator.of(context)
                .push(SlideFadeRoute(page: CreateInvoiceScreen(existingInvoiceId: invoice.id))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
          children: [
            Hero(
              tag: 'invoice-${invoice.id}',
              child: Material(
                type: MaterialType.transparency,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(customer?.name ?? l10n.walkInCustomer,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          ),
                          StatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.issuedOn(_fmt(invoice.invoiceDate)),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      const SizedBox(height: 14),
                      MoneyText(value: invoice.total, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.themedPrimary(context))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedEntry(
              delay: const Duration(milliseconds: 80),
              child: Text(l10n.itemsTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            ...invoice.items.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AnimatedEntry(
                      delay: Duration(milliseconds: 100 + 50 * e.key),
                      child: InvoiceItemRow(item: e.value),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            AnimatedEntry(
              delay: const Duration(milliseconds: 200),
              child: TotalSummary(
                subtotal: invoice.subtotal,
                discount: invoice.discount,
                tax: invoice.tax,
                shipping: invoice.shipping,
                total: invoice.total,
                animateTotal: false,
              ),
            ),
            const SizedBox(height: 18),
            AnimatedEntry(
              delay: const Duration(milliseconds: 260),
              child: Text(l10n.updateStatus, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            AnimatedEntry(
              delay: const Duration(milliseconds: 300),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InvoiceStatus.values.map((s) {
                  final selected = s == invoice.status;
                  return PressableScale(
                    onTap: () => ref.read(invoiceRepositoryProvider.notifier).setStatus(invoice.id, s),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
                      ),
                      child: Text(l10n.statusLabel(s),
                          style: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedEntry(
              delay: const Duration(milliseconds: 340),
              child: AppButton(
                label: l10n.deleteInvoice,
                type: AppButtonStyleType.danger,
                icon: Icons.delete_outline_rounded,
                expand: true,
                onPressed: () async {
                  final confirm = await showScaleFadeDialog<bool>(
                    context,
                    child: _ConfirmDeleteDialog(invoiceNumber: invoice.invoiceNumber),
                  );
                  if (confirm == true && context.mounted) {
                    ref.read(invoiceRepositoryProvider.notifier).delete(invoice.id);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(SlideFadeRoute(page: InvoicePreviewScreen(invoiceId: invoice.id))),
        icon: const Icon(Icons.visibility_rounded),
        label: Text(l10n.preview),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ConfirmDeleteDialog extends ConsumerWidget {
  final String invoiceNumber;
  const _ConfirmDeleteDialog({required this.invoiceNumber});

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
              Text(l10n.confirmDeleteInvoiceTitle(invoiceNumber), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Text(l10n.confirmDeleteInvoiceMessage,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
