import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../database/app_database.dart';

const _uuid = Uuid();

/// ------------------------- CUSTOMERS -------------------------

class CustomerRepository extends StateNotifier<List<Customer>> {
  CustomerRepository() : super(AppDatabase.customersBox.values.toList());

  void _refresh() => state = AppDatabase.customersBox.values.toList();

  /// Re-reads everything from Hive — used after a bulk restore replaces
  /// the box contents out from under this notifier's cached state.
  void reload() => _refresh();

  Customer add({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
  }) {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      address: address,
    );
    AppDatabase.customersBox.put(customer.id, customer);
    _refresh();
    return customer;
  }

  void update(Customer customer) {
    AppDatabase.customersBox.put(customer.id, customer);
    _refresh();
  }

  void delete(String id) {
    AppDatabase.customersBox.delete(id);
    _refresh();
  }

  Customer? byId(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final customerRepositoryProvider =
    StateNotifierProvider<CustomerRepository, List<Customer>>((ref) => CustomerRepository());

/// ------------------------- PRODUCTS -------------------------

class ProductRepository extends StateNotifier<List<Product>> {
  ProductRepository() : super(_sorted());

  static List<Product> _sorted() {
    final list = AppDatabase.productsBox.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _refresh() => state = _sorted();

  /// Re-reads everything from Hive — used after a bulk restore replaces
  /// the box contents out from under this notifier's cached state.
  void reload() => _refresh();

  Product add({required String name, required double price}) {
    final product = Product(id: _uuid.v4(), name: name, price: price);
    AppDatabase.productsBox.put(product.id, product);
    _refresh();
    return product;
  }

  void update(Product product) {
    AppDatabase.productsBox.put(product.id, product);
    _refresh();
  }

  void delete(String id) {
    AppDatabase.productsBox.delete(id);
    _refresh();
  }

  Product? byId(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final productRepositoryProvider =
    StateNotifierProvider<ProductRepository, List<Product>>((ref) => ProductRepository());

/// ------------------------- INVOICES -------------------------

class InvoiceRepository extends StateNotifier<List<Invoice>> {
  InvoiceRepository() : super(_sorted());

  static List<Invoice> _sorted() {
    final list = AppDatabase.invoicesBox.values.toList();
    list.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
    return list;
  }

  void _refresh() => state = _sorted();

  /// Re-reads everything from Hive — used after a bulk restore replaces
  /// the box contents out from under this notifier's cached state.
  void reload() => _refresh();

  String generateInvoiceNumber() {
    final settings = AppDatabase.settings;
    final number = '${settings.invoiceNumberPrefix}${settings.nextInvoiceSequence.toString().padLeft(4, '0')}';
    return number;
  }

  Invoice createDraft({required String customerId}) {
    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: generateInvoiceNumber(),
      customerId: customerId,
      invoiceDate: DateTime.now(),
      status: InvoiceStatus.draft,
    );
    AppDatabase.invoicesBox.put(invoice.id, invoice);
    _refresh();
    return invoice;
  }

  void save(Invoice invoice) {
    invoice.updatedAt = DateTime.now();
    AppDatabase.invoicesBox.put(invoice.id, invoice);
    _refresh();
  }

  void commitInvoiceNumberIfNeeded(Invoice invoice) {
    final settings = AppDatabase.settings;
    // Bump the running sequence once an invoice moves out of draft.
    final currentNum = int.tryParse(
      invoice.invoiceNumber.replaceAll(RegExp('[^0-9]'), ''),
    );
    if (currentNum != null && currentNum >= settings.nextInvoiceSequence) {
      settings.nextInvoiceSequence = currentNum + 1;
      settings.save();
    }
  }

  Invoice duplicate(Invoice source) {
    final copy = Invoice(
      id: _uuid.v4(),
      invoiceNumber: generateInvoiceNumber(),
      customerId: source.customerId,
      invoiceDate: DateTime.now(),
      dueDate: source.dueDate,
      items: source.items
          .map((i) => InvoiceItem(
                id: _uuid.v4(),
                name: i.name,
                price: i.price,
                quantity: i.quantity,
                discount: i.discount,
                tax: i.tax,
              ))
          .toList(),
      discount: source.discount,
      tax: source.tax,
      shipping: source.shipping,
      status: InvoiceStatus.draft,
      notes: source.notes,
      poNumber: source.poNumber,
      paymentMethod: source.paymentMethod,
    );
    AppDatabase.invoicesBox.put(copy.id, copy);
    _refresh();
    return copy;
  }

  void delete(String id) {
    AppDatabase.invoicesBox.delete(id);
    _refresh();
  }

  /// Re-adds a previously deleted invoice — used for the "Undo" snackbar.
  void restore(Invoice invoice) {
    AppDatabase.invoicesBox.put(invoice.id, invoice);
    _refresh();
  }

  void setStatus(String id, InvoiceStatus status) {
    final invoice = AppDatabase.invoicesBox.get(id);
    if (invoice == null) return;
    invoice.status = status;
    if (status == InvoiceStatus.paid) {
      invoice.amountPaid = invoice.total;
    }
    invoice.updatedAt = DateTime.now();
    AppDatabase.invoicesBox.put(id, invoice);
    _refresh();
  }

  void toggleFavorite(String id) {
    final invoice = AppDatabase.invoicesBox.get(id);
    if (invoice == null) return;
    invoice.isFavorite = !invoice.isFavorite;
    AppDatabase.invoicesBox.put(id, invoice);
    _refresh();
  }

  Invoice? byId(String id) {
    try {
      return state.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}

final invoiceRepositoryProvider =
    StateNotifierProvider<InvoiceRepository, List<Invoice>>((ref) => InvoiceRepository());

/// ------------------------- SETTINGS / THEME -------------------------

class ThemeModeController extends StateNotifier<int> {
  ThemeModeController() : super(AppDatabase.settings.themeMode);

  void set(int mode) {
    final settings = AppDatabase.settings;
    settings.themeMode = mode;
    settings.save();
    state = mode;
  }

  /// Re-reads from Hive — used after a bulk restore.
  void reload() => state = AppDatabase.settings.themeMode;
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, int>((ref) => ThemeModeController());

class LocaleController extends StateNotifier<String> {
  LocaleController() : super(AppDatabase.settings.locale);

  void set(String locale) {
    final settings = AppDatabase.settings;
    settings.locale = locale;
    settings.save();
    state = locale;
  }

  /// Re-reads from Hive — used after a bulk restore.
  void reload() => state = AppDatabase.settings.locale;
}

final localeProvider = StateNotifierProvider<LocaleController, String>((ref) => LocaleController());

final businessProfileProvider = StateProvider<BusinessProfile>((ref) => AppDatabase.business);

/// ------------------------- DERIVED / COMPUTED -------------------------

final dashboardStatsProvider = Provider((ref) {
  final invoices = ref.watch(invoiceRepositoryProvider);
  double paid = 0, pending = 0, overdue = 0;
  for (final inv in invoices) {
    switch (inv.status) {
      case InvoiceStatus.paid:
        paid += inv.total;
        break;
      case InvoiceStatus.overdue:
        overdue += inv.balanceDue;
        break;
      case InvoiceStatus.unpaid:
      case InvoiceStatus.partial:
        pending += inv.balanceDue;
        break;
      case InvoiceStatus.draft:
        break;
    }
  }
  return DashboardStats(paid: paid, pending: pending, overdue: overdue);
});

class DashboardStats {
  final double paid;
  final double pending;
  final double overdue;
  const DashboardStats({required this.paid, required this.pending, required this.overdue});
  double get total => paid + pending + overdue;
}
