import 'package:hive_flutter/hive_flutter.dart';
import '../../models/models.dart';

/// Central place that owns Hive initialization and box handles.
/// All data is persisted locally, so the app is fully usable offline.
class AppDatabase {
  AppDatabase._();

  static const String customersBoxName = 'customers_box';
  static const String invoicesBoxName = 'invoices_box';
  static const String businessBoxName = 'business_box';
  static const String settingsBoxName = 'settings_box';
  static const String productsBoxName = 'products_box';

  static late Box<Customer> customersBox;
  static late Box<Invoice> invoicesBox;
  static late Box<BusinessProfile> businessBox;
  static late Box<InvoiceSettingsModel> settingsBox;
  static late Box<Product> productsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(BusinessProfileAdapter());
    Hive.registerAdapter(InvoiceSettingsAdapter());
    Hive.registerAdapter(ProductAdapter());

    customersBox = await Hive.openBox<Customer>(customersBoxName);
    invoicesBox = await Hive.openBox<Invoice>(invoicesBoxName);
    businessBox = await Hive.openBox<BusinessProfile>(businessBoxName);
    settingsBox = await Hive.openBox<InvoiceSettingsModel>(settingsBoxName);
    productsBox = await Hive.openBox<Product>(productsBoxName);
  }

  static BusinessProfile get business {
    if (businessBox.isEmpty) {
      businessBox.put('profile', BusinessProfile());
    }
    return businessBox.get('profile')!;
  }

  static InvoiceSettingsModel get settings {
    if (settingsBox.isEmpty) {
      settingsBox.put('settings', InvoiceSettingsModel());
    }
    return settingsBox.get('settings')!;
  }
}
