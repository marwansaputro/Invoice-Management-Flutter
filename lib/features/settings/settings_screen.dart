import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/backup/backup_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../products/products_screen.dart';
import '../reports/transaction_recap_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

const kInvoiceTemplateNames = ['Classic', 'Modern', 'Minimal'];
const kInvoiceTemplateDescriptions = [
  'Clean white paper with a signature top accent stripe.',
  'Bold colored header card for a contemporary look.',
  'Monochrome, borderless, distraction-free layout.',
];
const kInvoiceTemplateIcons = [
  Icons.receipt_long_rounded,
  Icons.dashboard_customize_rounded,
  Icons.crop_square_rounded,
];

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _editBusinessProfile() async {
    final business = AppDatabase.business;
    await showAppBottomSheet(context,
        child: BusinessProfileSheet(business: business));
    setState(() {});
  }

  Future<void> _editInvoiceSettings() async {
    final settings = AppDatabase.settings;
    await showAppBottomSheet(context,
        child: _InvoiceSettingsSheet(settings: settings));
    setState(() {});
  }

  Future<void> _editTaxSettings() async {
    final settings = AppDatabase.settings;
    await showAppBottomSheet(context,
        child: _TaxSettingsSheet(settings: settings));
    setState(() {});
  }

  Future<void> _pickInvoiceTemplate() async {
    final settings = AppDatabase.settings;
    final picked = await showAppBottomSheet<int>(context,
        child: _InvoiceTemplateSheet(current: settings.invoiceTemplate));
    if (picked != null) {
      settings.invoiceTemplate = picked;
      await settings.save();
      if (mounted) {
        AppSnackbar.show(context,
            message:
                'Invoice template set to ${kInvoiceTemplateNames[picked]}');
        setState(() {});
      }
    }
  }

  Future<void> _pickCurrency() async {
    final settings = AppDatabase.settings;
    final picked = await showAppBottomSheet<String>(context,
        child: _CurrencySheet(current: settings.currencySymbol));
    if (picked != null) {
      settings.currencySymbol = picked;
      await settings.save();
      if (mounted) {
        AppSnackbar.show(context, message: 'Currency set to $picked');
        setState(() {});
      }
    }
  }

  Future<void> _pickLanguage() async {
    final settings = AppDatabase.settings;
    final picked = await showAppBottomSheet<String>(context,
        child: _LanguageSheet(current: settings.locale));
    if (picked != null) {
      ref.read(localeProvider.notifier).set(picked);
      if (mounted) {
        final l10n = AppStrings(picked);
        AppSnackbar.show(context,
            message:
                '${l10n.language}: ${picked == 'id' ? l10n.languageIndonesian : l10n.languageEnglish}');
        setState(() {});
      }
    }
  }

  Future<void> _openBackupRestore() async {
    final action = await showAppBottomSheet<String>(context,
        child: const _BackupRestoreSheet());
    if (!mounted || action == null) return;
    if (action == 'export') {
      await _exportBackup();
    } else if (action == 'restore') {
      await _restoreBackup();
    }
  }

  Future<void> _exportBackup() async {
    try {
      await BackupService.shareBackup();
    } catch (_) {
      if (mounted) {
        final l10n = AppStrings(ref.read(localeProvider));
        AppSnackbar.show(context,
            message: l10n.backupExportFailed,
            icon: Icons.error_outline_rounded,
            color: AppColors.danger);
      }
    }
  }

  String _backupErrorMessage(AppStrings l10n, String code) {
    switch (code) {
      case 'invalid_json':
        return l10n.backupInvalidJson;
      case 'unsupported_version':
        return l10n.backupUnsupportedVersion;
      default:
        return l10n.backupUnrecognized;
    }
  }

  Future<void> _restoreBackup() async {
    final l10n = AppStrings(ref.read(localeProvider));
    String? contents;
    try {
      contents = await BackupService.pickBackupFileContents();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context,
            message: l10n.backupUnrecognized,
            icon: Icons.error_outline_rounded,
            color: AppColors.danger);
      }
      return;
    }
    if (contents == null || !mounted) return; // user cancelled the picker

    final BackupData data;
    try {
      data = BackupService.parse(contents);
    } on BackupFormatException catch (e) {
      AppSnackbar.show(context,
          message: _backupErrorMessage(l10n, e.message),
          icon: Icons.error_outline_rounded,
          color: AppColors.danger);
      return;
    }

    if (!mounted) return;
    final confirmed = await showScaleFadeDialog<bool>(context,
        child: _ConfirmRestoreDialog(
            locale: ref.read(localeProvider),
            customerCount: data.customers.length,
            invoiceCount: data.invoices.length));
    if (confirmed != true || !mounted) return;

    await BackupService.restore(data);
    ref.read(customerRepositoryProvider.notifier).reload();
    ref.read(invoiceRepositoryProvider.notifier).reload();
    ref.read(productRepositoryProvider.notifier).reload();
    ref.read(themeModeProvider.notifier).reload();
    ref.read(localeProvider.notifier).reload();

    if (mounted) {
      setState(() {});
      AppSnackbar.show(context,
          message: AppStrings(ref.read(localeProvider)).restoreSuccess,
          icon: Icons.check_circle_rounded,
          color: AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = AppDatabase.business;
    final settings = AppDatabase.settings;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppStrings(locale);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        children: [
          AnimatedEntry(
            offsetY: 10,
            child: Text(l10n.settingsTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(l10n.manageBusinessPreferences,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13.5)),
          const SizedBox(height: 20),
          AnimatedEntry(
            delay: const Duration(milliseconds: 60),
            child: AppCard(
              onTap: _editBusinessProfile,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: business.logoBytes != null
                        ? Image.memory(
                            Uint8List.fromList(business.logoBytes!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 24),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(business.businessName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(l10n.tapToEditBusinessProfile,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedEntry(
            delay: const Duration(milliseconds: 100),
            child: _GroupedSettingsCard(
              title: l10n.sectionBusiness,
              items: [
                _SettingsItem(
                    icon: Icons.receipt_long_rounded,
                    label: l10n.invoiceSettings,
                    onTap: _editInvoiceSettings),
                _SettingsItem(
                  icon: Icons.account_balance_rounded,
                  label: l10n.paymentMethods,
                  trailing: business.acceptedPaymentMethods.isEmpty
                      ? business.bankName
                      : business.acceptedPaymentMethods.length == 1
                          ? business.acceptedPaymentMethods.first
                          : '${business.acceptedPaymentMethods.length} methods',
                  onTap: _editBusinessProfile,
                ),
                _SettingsItem(
                  icon: Icons.percent_rounded,
                  label: l10n.taxSettings,
                  trailing: '${settings.defaultTaxPercent.toStringAsFixed(0)}%',
                  onTap: _editTaxSettings,
                ),
                _SettingsItem(
                  icon: Icons.inventory_2_rounded,
                  label: l10n.productsAndServices,
                  trailing: '${ref.watch(productRepositoryProvider).length}',
                  onTap: () => Navigator.of(context)
                      .push(SlideFadeRoute(page: const ProductsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 140),
            child: _GroupedSettingsCard(
              title: l10n.sectionPreferences,
              items: [
                _SettingsItem(
                    icon: Icons.attach_money_rounded,
                    label: l10n.currency,
                    trailing: settings.currencySymbol,
                    onTap: _pickCurrency),
                _SettingsItem(
                  icon: Icons.description_rounded,
                  label: l10n.invoiceTemplate,
                  trailing: kInvoiceTemplateNames[settings.invoiceTemplate],
                  onTap: _pickInvoiceTemplate,
                ),
                _SettingsItem(
                  icon: Icons.language_rounded,
                  label: l10n.language,
                  trailing: locale == 'id'
                      ? l10n.languageIndonesian
                      : l10n.languageEnglish,
                  onTap: _pickLanguage,
                ),
                _SettingsItem(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.transactionRecap,
                  onTap: () => Navigator.of(context).push(
                      SlideFadeRoute(page: const TransactionRecapScreen())),
                ),
                // _SettingsItem(
                //   icon: Icons.notifications_none_rounded,
                //   label: l10n.notifications,
                //   trailingWidget: Switch.adaptive(
                //     value: settings.notificationsEnabled,
                //     activeColor: AppColors.themedPrimary(context),
                //     onChanged: (v) {
                //       settings.notificationsEnabled = v;
                //       settings.save();
                //       setState(() {});
                //     },
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 180),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Row(
                      children: [
                        Text(l10n.sectionAppearance,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _ThemeOption(
                              label: l10n.light,
                              icon: Icons.light_mode_rounded,
                              selected: themeMode == 1,
                              onTap: () =>
                                  ref.read(themeModeProvider.notifier).set(1))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _ThemeOption(
                              label: l10n.dark,
                              icon: Icons.dark_mode_rounded,
                              selected: themeMode == 2,
                              onTap: () =>
                                  ref.read(themeModeProvider.notifier).set(2))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _ThemeOption(
                              label: l10n.system,
                              icon: Icons.smartphone_rounded,
                              selected: themeMode == 0,
                              onTap: () =>
                                  ref.read(themeModeProvider.notifier).set(0))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 220),
            child: _GroupedSettingsCard(
              title: l10n.sectionData,
              items: [
                _SettingsItem(
                  icon: Icons.cloud_sync_rounded,
                  label: l10n.backupRestore,
                  onTap: _openBackupRestore,
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: l10n.about,
                  onTap: () =>
                      showScaleFadeDialog(context, child: const _AboutDialog()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('INVOICE MANAGEMENT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.6),
                        letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('Created. Marwan S',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withOpacity(0.5))),
                const SizedBox(height: 4),
                Text('Version 1.0.0',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.4))),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  _SettingsItem(
      {required this.icon,
      required this.label,
      this.trailing,
      this.trailingWidget,
      this.onTap});
}

class _GroupedSettingsCard extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _GroupedSettingsCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4)),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _SettingsRow(item: items[i]),
                if (i != items.length - 1)
                  const Divider(height: 1, indent: 70, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsItem item;
  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.trailingWidget != null ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: AppColors.themedPrimary(context)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(item.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5))),
            if (item.trailingWidget != null)
              item.trailingWidget!
            else ...[
              if (item.trailing != null)
                Text(item.trailing!,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themedPrimary(context);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? accent : Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20, color: selected ? accent : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// ------------------------- EDIT SHEETS -------------------------

class BusinessProfileSheet extends StatefulWidget {
  final BusinessProfile business;
  const BusinessProfileSheet({super.key, required this.business});

  @override
  State<BusinessProfileSheet> createState() => _BusinessProfileSheetState();
}

class _BusinessProfileSheetState extends State<BusinessProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountName;
  late final TextEditingController _bankAccountNumber;
  late final TextEditingController _qrisId;
  late final TextEditingController _eWalletProvider;
  late final TextEditingController _eWalletNumber;
  late final Set<String> _selectedMethods;
  Uint8List? _logoBytes;

  static const _availableMethods = [
    'Bank Transfer',
    'Cash',
    'QRIS',
    'E-Wallet'
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _name = TextEditingController(text: b.businessName);
    _address = TextEditingController(text: b.address);
    _phone = TextEditingController(text: b.phone);
    _email = TextEditingController(text: b.email);
    _bankName = TextEditingController(text: b.bankName);
    _bankAccountName = TextEditingController(text: b.bankAccountName);
    _bankAccountNumber = TextEditingController(text: b.bankAccountNumber);
    _qrisId = TextEditingController(text: b.qrisId);
    _eWalletProvider = TextEditingController(text: b.eWalletProvider);
    _eWalletNumber = TextEditingController(text: b.eWalletNumber);
    _selectedMethods = b.acceptedPaymentMethods.toSet();
    _logoBytes = b.logoBytes != null ? Uint8List.fromList(b.logoBytes!) : null;
  }

  void _toggleMethod(String method) {
    setState(() {
      if (_selectedMethods.contains(method)) {
        if (_selectedMethods.length > 1) _selectedMethods.remove(method);
      } else {
        _selectedMethods.add(method);
      }
    });
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _logoBytes = bytes);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _bankName.dispose();
    _bankAccountName.dispose();
    _bankAccountNumber.dispose();
    _qrisId.dispose();
    _eWalletProvider.dispose();
    _eWalletNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.business
      ..businessName = _name.text.trim()
      ..address = _address.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..bankName = _bankName.text.trim()
      ..bankAccountName = _bankAccountName.text.trim()
      ..bankAccountNumber = _bankAccountNumber.text.trim()
      ..acceptedPaymentMethods = _selectedMethods.toList()
      ..logoBytes = _logoBytes
      ..qrisId = _qrisId.text.trim()
      ..eWalletProvider = _eWalletProvider.text.trim()
      ..eWalletNumber = _eWalletNumber.text.trim();
    await widget.business.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Business profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Center(
            child: PressableScale(
              onTap: _pickLogo,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _logoBytes != null
                        ? Image.memory(_logoBytes!,
                            width: 84, height: 84, fit: BoxFit.cover)
                        : Container(
                            width: 84,
                            height: 84,
                            color: AppColors.themedPrimary(context),
                            alignment: Alignment.center,
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 32),
                          ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.themedPrimary(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).cardTheme.color ??
                                Colors.white,
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo_camera_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  if (_logoBytes != null)
                    Positioned(
                      left: -4,
                      bottom: -4,
                      child: PressableScale(
                        onTap: () => setState(() => _logoBytes = null),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).cardTheme.color ??
                                    Colors.white,
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Tap to change photo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 18),
          AppTextField(label: 'Business Name', controller: _name),
          const SizedBox(height: 14),
          AppTextField(label: 'Address', controller: _address, maxLines: 2),
          const SizedBox(height: 14),
          AppTextField(
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          AppTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          const Text('PAYMENT METHOD',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMethods
                .map((m) => _MethodChip(
                      label: m,
                      selected: _selectedMethods.contains(m),
                      onTap: () => _toggleMethod(m),
                    ))
                .toList(),
          ),
          if (_selectedMethods.contains('Bank Transfer')) ...[
            const SizedBox(height: 16),
            AppTextField(label: 'Bank Name', controller: _bankName),
            const SizedBox(height: 14),
            AppTextField(label: 'Account Name', controller: _bankAccountName),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Account Number',
                controller: _bankAccountNumber,
                keyboardType: TextInputType.number),
          ],
          if (_selectedMethods.contains('QRIS')) ...[
            const SizedBox(height: 16),
            AppTextField(
                label: 'QRIS Merchant ID',
                controller: _qrisId,
                hint: 'e.g. ID10200123456789'),
          ],
          if (_selectedMethods.contains('E-Wallet')) ...[
            const SizedBox(height: 16),
            AppTextField(
                label: 'E-Wallet Provider',
                controller: _eWalletProvider,
                hint: 'e.g. OVO, GoPay, Dana'),
            const SizedBox(height: 14),
            AppTextField(
                label: 'E-Wallet Number',
                controller: _eWalletNumber,
                keyboardType: TextInputType.phone),
          ],
          const SizedBox(height: 22),
          AppButton(
              label: 'Save Changes',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _save),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSettingsSheet extends StatefulWidget {
  final InvoiceSettingsModel settings;
  const _InvoiceSettingsSheet({required this.settings});

  @override
  State<_InvoiceSettingsSheet> createState() => _InvoiceSettingsSheetState();
}

class _InvoiceSettingsSheetState extends State<_InvoiceSettingsSheet> {
  late final TextEditingController _prefix;
  late final TextEditingController _nextNumber;
  late final TextEditingController _dueDays;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _prefix = TextEditingController(text: s.invoiceNumberPrefix);
    _nextNumber = TextEditingController(text: s.nextInvoiceSequence.toString());
    _dueDays = TextEditingController(text: s.defaultDueDays.toString());
  }

  @override
  void dispose() {
    _prefix.dispose();
    _nextNumber.dispose();
    _dueDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings
      ..invoiceNumberPrefix = _prefix.text.trim().isEmpty
          ? 'INV'
          : _prefix.text.trim().toUpperCase()
      ..nextInvoiceSequence =
          int.tryParse(_nextNumber.text) ?? widget.settings.nextInvoiceSequence
      ..defaultDueDays = int.tryParse(_dueDays.text) ?? 0;
    await widget.settings.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Invoice settings updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invoice Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        AppTextField(
            label: 'Invoice Number Prefix', controller: _prefix, hint: 'INV'),
        const SizedBox(height: 14),
        AppTextField(
            label: 'Next Invoice Number',
            controller: _nextNumber,
            keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        AppTextField(
            label: 'Default Due Days',
            controller: _dueDays,
            hint: '0 = Due on receipt',
            keyboardType: TextInputType.number),
        const SizedBox(height: 22),
        AppButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save),
      ],
    );
  }
}

class _TaxSettingsSheet extends StatefulWidget {
  final InvoiceSettingsModel settings;
  const _TaxSettingsSheet({required this.settings});

  @override
  State<_TaxSettingsSheet> createState() => _TaxSettingsSheetState();
}

class _TaxSettingsSheetState extends State<_TaxSettingsSheet> {
  late final TextEditingController _percent;

  @override
  void initState() {
    super.initState();
    _percent = TextEditingController(
        text: widget.settings.defaultTaxPercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings.defaultTaxPercent = double.tryParse(_percent.text) ?? 0;
    await widget.settings.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Tax settings updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tax Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Used as a default suggestion when adding new items.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 18),
        AppTextField(
            label: 'Default Tax (%)',
            controller: _percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 22),
        AppButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save),
      ],
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  final String current;
  const _CurrencySheet({required this.current});

  @override
  Widget build(BuildContext context) {
    const currencies = ['Rp', '\$', '€', 'RM'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...currencies.map((c) {
          final accent = AppColors.themedPrimary(context);
          return PressableScale(
            scaleDown: 0.99,
            onTap: () => Navigator.pop(context, c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: c == current
                    ? accent.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        c == current ? accent : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Text(c,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(width: 12),
                  if (c == current)
                    Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InvoiceTemplateSheet extends StatelessWidget {
  final int current;
  const _InvoiceTemplateSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themedPrimary(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invoice Template',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Choose how your invoices look when previewed or shared.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 16),
        for (int i = 0; i < kInvoiceTemplateNames.length; i++) ...[
          PressableScale(
            scaleDown: 0.99,
            onTap: () => Navigator.pop(context, i),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: i == current
                    ? accent.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        i == current ? accent : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child:
                        Icon(kInvoiceTemplateIcons[i], color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kInvoiceTemplateNames[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(kInvoiceTemplateDescriptions[i],
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (i == current) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded, color: accent, size: 20),
                  ],
                ],
              ),
            ),
          ),
          if (i != kInvoiceTemplateNames.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themedPrimary(context);
    final l10n = AppStrings(current);
    const options = [
      (code: 'en', flag: '🇬🇧'),
      (code: 'id', flag: '🇮🇩'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectLanguage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l10n.selectLanguageDescription,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 16),
        for (final option in options) ...[
          PressableScale(
            scaleDown: 0.99,
            onTap: () => Navigator.pop(context, option.code),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: option.code == current
                    ? accent.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: option.code == current
                        ? accent
                        : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Text(option.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                      option.code == 'id'
                          ? l10n.languageIndonesian
                          : l10n.languageEnglish,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  if (option.code == current)
                    Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BackupRestoreSheet extends ConsumerWidget {
  const _BackupRestoreSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.backupRestore,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(l10n.backupRestoreDescription,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 16),
        _BackupRestoreRow(
          icon: Icons.upload_file_rounded,
          iconColor: AppColors.success,
          title: l10n.exportBackup,
          subtitle: l10n.exportBackupDescription,
          onTap: () => Navigator.pop(context, 'export'),
        ),
        const SizedBox(height: 10),
        _BackupRestoreRow(
          icon: Icons.download_rounded,
          iconColor: AppColors.warning,
          title: l10n.restoreBackup,
          subtitle: l10n.restoreBackupDescription,
          onTap: () => Navigator.pop(context, 'restore'),
        ),
      ],
    );
  }
}

class _BackupRestoreRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BackupRestoreRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.99,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRestoreDialog extends StatelessWidget {
  final String locale;
  final int customerCount;
  final int invoiceCount;
  const _ConfirmRestoreDialog({
    required this.locale,
    required this.customerCount,
    required this.invoiceCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(locale);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.solidSurface(context),
              borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 36),
              const SizedBox(height: 14),
              Text(l10n.confirmRestoreTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Text(l10n.confirmRestoreMessage(customerCount, invoiceCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
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
                      label: l10n.restoreAction,
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

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
              color: AppColors.solidSurface(context),
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              const Text('Invoice Management',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 4),
              const Text('Created. Marwan S',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 14),
              const Text('Version 1.0.0',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('All data is stored locally on this device.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 18),
              AppButton(
                  label: 'Close',
                  expand: true,
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
