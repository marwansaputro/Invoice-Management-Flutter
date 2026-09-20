import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/models.dart';
import '../database/app_database.dart';

/// Thrown when a picked file isn't a recognizable Invoicely backup.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);
}

/// Parsed contents of a backup file, ready to be written into Hive.
class BackupData {
  final BusinessProfile business;
  final InvoiceSettingsModel settings;
  final List<Customer> customers;
  final List<Invoice> invoices;
  final List<Product> products;
  final DateTime? exportedAt;

  const BackupData({
    required this.business,
    required this.settings,
    required this.customers,
    required this.invoices,
    required this.products,
    this.exportedAt,
  });
}

/// Exports all locally-stored data (business profile, settings, customers,
/// invoices) to a single JSON file and restores from one. This is the only
/// way data ever leaves the device — there's no cloud sync, so this file
/// is the user's one recovery path if the app is reinstalled or the device
/// is lost.
class BackupService {
  BackupService._();

  static const int formatVersion = 1;

  static Map<String, dynamic> _buildPayload() => {
        'app': 'invoicely',
        'version': formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'business': AppDatabase.business.toJson(),
        'settings': AppDatabase.settings.toJson(),
        'customers': AppDatabase.customersBox.values.map((c) => c.toJson()).toList(),
        'invoices': AppDatabase.invoicesBox.values.map((i) => i.toJson()).toList(),
        'products': AppDatabase.productsBox.values.map((p) => p.toJson()).toList(),
      };

  static Future<File> _writeBackupFile() async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(_buildPayload());
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/invoicely_backup_$stamp.json');
    return file.writeAsString(jsonString);
  }

  /// Writes the backup file and hands it to the OS share sheet so the user
  /// can save it wherever they like (Drive, Files, email, chat, ...).
  static Future<void> shareBackup() async {
    final file = await _writeBackupFile();
    await Share.shareXFiles([XFile(file.path)], text: 'Invoicely backup');
  }

  /// Opens a file picker for a `.json` backup and returns its raw text, or
  /// null if the user cancelled.
  static Future<String?> pickBackupFileContents() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    if (picked.bytes != null) return utf8.decode(picked.bytes!);
    if (picked.path != null) return File(picked.path!).readAsString();
    return null;
  }

  /// Parses and validates backup JSON text. Throws [BackupFormatException]
  /// with a user-facing reason if the file isn't a usable backup.
  static BackupData parse(String jsonString) {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw const BackupFormatException('invalid_json');
    }
    if (decoded is! Map || decoded['business'] == null || decoded['settings'] == null) {
      throw const BackupFormatException('unrecognized');
    }
    final version = decoded['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException('unsupported_version');
    }
    try {
      return BackupData(
        business: BusinessProfile.fromJson(Map<String, dynamic>.from(decoded['business'] as Map)),
        settings: InvoiceSettingsModel.fromJson(Map<String, dynamic>.from(decoded['settings'] as Map)),
        customers: (decoded['customers'] as List? ?? [])
            .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        invoices: (decoded['invoices'] as List? ?? [])
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        products: (decoded['products'] as List? ?? [])
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        exportedAt: decoded['exportedAt'] != null
            ? DateTime.tryParse(decoded['exportedAt'] as String)
            : null,
      );
    } catch (_) {
      throw const BackupFormatException('unrecognized');
    }
  }

  /// Overwrites all local data with the contents of [data]. Destructive and
  /// irreversible — callers must confirm with the user first.
  static Future<void> restore(BackupData data) async {
    final business = AppDatabase.business
      ..businessName = data.business.businessName
      ..address = data.business.address
      ..phone = data.business.phone
      ..email = data.business.email
      ..bankName = data.business.bankName
      ..bankAccountName = data.business.bankAccountName
      ..bankAccountNumber = data.business.bankAccountNumber
      ..acceptedPaymentMethods = data.business.acceptedPaymentMethods
      ..logoBytes = data.business.logoBytes
      ..qrisId = data.business.qrisId
      ..eWalletProvider = data.business.eWalletProvider
      ..eWalletNumber = data.business.eWalletNumber;
    await business.save();

    final settings = AppDatabase.settings
      ..currencySymbol = data.settings.currencySymbol
      ..invoiceNumberPrefix = data.settings.invoiceNumberPrefix
      ..nextInvoiceSequence = data.settings.nextInvoiceSequence
      ..defaultDueDays = data.settings.defaultDueDays
      ..defaultTaxPercent = data.settings.defaultTaxPercent
      ..themeMode = data.settings.themeMode
      ..notificationsEnabled = data.settings.notificationsEnabled
      ..invoiceTemplate = data.settings.invoiceTemplate
      ..savedSignatureBytes = data.settings.savedSignatureBytes
      ..savedIsApproved = data.settings.savedIsApproved
      ..savedApproverName = data.settings.savedApproverName
      ..locale = data.settings.locale;
    await settings.save();

    await AppDatabase.customersBox.clear();
    for (final customer in data.customers) {
      await AppDatabase.customersBox.put(customer.id, customer);
    }

    await AppDatabase.invoicesBox.clear();
    for (final invoice in data.invoices) {
      await AppDatabase.invoicesBox.put(invoice.id, invoice);
    }

    await AppDatabase.productsBox.clear();
    for (final product in data.products) {
      await AppDatabase.productsBox.put(product.id, product);
    }
  }
}
