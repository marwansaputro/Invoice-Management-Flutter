import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';
  bool _loading = true;

  final _filters = const ['All', 'Paid', 'Unpaid', 'Overdue', 'Draft'];

  String _filterLabel(String key, AppStrings l10n) {
    switch (key) {
      case 'Paid':
        return l10n.paid;
      case 'Unpaid':
        return l10n.filterUnpaid;
      case 'Overdue':
        return l10n.overdue;
      case 'Draft':
        return l10n.filterDraft;
      default:
        return l10n.filterAll;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Invoice invoice) {
    switch (_filter) {
      case 'Paid':
        return invoice.status == InvoiceStatus.paid;
      case 'Unpaid':
        return invoice.status == InvoiceStatus.unpaid ||
            invoice.status == InvoiceStatus.partial;
      case 'Overdue':
        return invoice.status == InvoiceStatus.overdue;
      case 'Draft':
        return invoice.status == InvoiceStatus.draft;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceRepositoryProvider);
    final customers = ref.watch(customerRepositoryProvider);
    final l10n = AppStrings(ref.watch(localeProvider));

    String customerName(String id) {
      try {
        return customers.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return l10n.walkInCustomer;
      }
    }

    final filtered = invoices.where((inv) {
      final matchesFilter = _matchesFilter(inv);
      final matchesQuery = _query.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(_query.toLowerCase()) ||
          customerName(inv.customerId)
              .toLowerCase()
              .contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AnimatedEntry(
                offsetY: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.invoicesTitle,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(l10n.manageAllInvoices,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CollapsibleSearchBar(
                controller: _searchController,
                expanded: _searching,
                hintText: l10n.searchInvoiceHint,
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
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final selected = f == _filter;
                  return PressableScale(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      curve: AppCurves.smooth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        _filterLabel(f, l10n),
                        style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const InvoiceCardSkeleton(),
                    )
                  : filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: l10n.noInvoicesFoundTitle,
                          message: l10n.noInvoicesFoundMessage,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final invoice = filtered[i];
                            return AnimatedEntry(
                              key: ValueKey(invoice.id),
                              delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
                              child: Dismissible(
                                key: ValueKey('dismiss-${invoice.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: AppColors.danger),
                                ),
                                onDismissed: (_) {
                                  final removed = invoice;
                                  ref
                                      .read(invoiceRepositoryProvider.notifier)
                                      .delete(invoice.id);
                                  AppSnackbar.show(
                                    context,
                                    message: l10n.invoiceDeleted,
                                    icon: Icons.delete_rounded,
                                    actionLabel: l10n.undo,
                                    onAction: () => ref
                                        .read(
                                            invoiceRepositoryProvider.notifier)
                                        .restore(removed),
                                  );
                                },
                                child: InvoiceListCard(
                                  invoice: invoice,
                                  customerName:
                                      customerName(invoice.customerId),
                                  onTap: () => Navigator.of(context).push(
                                      SlideFadeRoute(
                                          page: InvoiceDetailScreen(
                                              invoiceId: invoice.id))),
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
