import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import 'add_customer_sheet.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final result = await showAppBottomSheet<Map<String, String>>(context, child: const AddCustomerSheet());
    if (result != null) {
      ref.read(customerRepositoryProvider.notifier).add(
            name: result['name']!,
            phone: result['phone'] ?? '',
            email: result['email'] ?? '',
            address: result['address'] ?? '',
          );
      if (mounted) {
        AppSnackbar.show(context, message: AppStrings(ref.read(localeProvider)).customerAdded);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerRepositoryProvider);
    final invoices = ref.watch(invoiceRepositoryProvider);
    final l10n = AppStrings(ref.watch(localeProvider));

    List<Invoice> invoicesFor(String id) => invoices.where((i) => i.customerId == id).toList();

    final filtered = customers.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
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
                        Text(l10n.navCustomers, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(l10n.customersSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  PressableScale(
                    onTap: _addCustomer,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
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
              hintText: l10n.searchCustomerHint,
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
                    icon: Icons.people_outline_rounded,
                    title: customers.isEmpty ? l10n.noCustomersYetTitle : l10n.noCustomersFoundTitle,
                    message: customers.isEmpty
                        ? l10n.addFirstCustomerMessage
                        : l10n.tryDifferentSearchTerm,
                    actionLabel: customers.isEmpty ? l10n.addCustomer : null,
                    onAction: customers.isEmpty ? _addCustomer : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final customer = filtered[i];
                      final custInvoices = invoicesFor(customer.id);
                      final totalSpend = custInvoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
                      return AnimatedEntry(
                        delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                        child: AppCard(
                          onTap: () => Navigator.of(context).push(SlideFadeRoute(page: CustomerDetailScreen(customerId: customer.id))),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.themedPrimary(context).withOpacity(0.14),
                                child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: AppColors.themedPrimary(context), fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(customer.phone.isEmpty ? '—' : customer.phone,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(l10n.invoicesCount(custInvoices.length),
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  MoneyText(value: totalSpend, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
