import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../animations/app_motion.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'widgets.dart';

/// Invoice paper is always printed on white, regardless of the app's
/// light/dark theme — so its "muted" label/caption color is a fixed,
/// deliberately darker gray (not [AppColors.textSecondary]) for stronger
/// contrast and easier reading than the app-wide secondary tone.
const Color _paperMuted = Color(0xFF52525C);
const Color _paperInk = Color(0xFF202124);

/// Invoice list/dashboard row card. Wrapped in a [Hero] so tapping it
/// morphs smoothly into the Invoice Detail screen.
class InvoiceListCard extends ConsumerWidget {
  final Invoice invoice;
  final String customerName;
  final VoidCallback onTap;

  const InvoiceListCard({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final firstItem = invoice.items.isNotEmpty ? invoice.items.first : null;
    final extraItems = invoice.items.length - 1;
    final accent = AppColors.themedPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'invoice-${invoice.id}',
      child: Material(
        type: MaterialType.transparency,
        child: AppCard(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child:
                    Icon(Icons.receipt_long_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(invoice.invoiceNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        if (invoice.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite_rounded,
                                size: 15, color: AppColors.secondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(customerName,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.date(invoice.invoiceDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (firstItem != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        extraItems > 0
                            ? '${firstItem.name} ${l10n.moreItemsSuffix(extraItems)}'
                            : firstItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    value: invoice.total,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: invoice.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row inside the itemized product table, used in both the
/// Create Invoice items list and the printable invoice preview table.
class InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvoiceItemRow(
      {super.key, required this.item, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 6),
                Text(
                  '${AppFormatters.money(item.price)}  ×  ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          MoneyText(
              value: item.lineTotal,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// The bill summary block (subtotal / discount / tax / shipping / total)
/// shown in Create Invoice and the invoice preview.
class TotalSummary extends ConsumerWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;
  final bool animateTotal;
  final bool compact;

  const TotalSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shipping,
    required this.total,
    this.animateTotal = true,
    this.compact = false,
  });

  Widget _row(String label, double value,
      {bool negative = false, bool bold = false}) {
    final text = negative && value > 0
        ? '-${AppFormatters.money(value)}'
        : AppFormatters.money(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? null : AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 15 : 13.5)),
          Text(text,
              style: TextStyle(
                  color: negative && value > 0 ? AppColors.danger : null,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: bold ? 15 : 13.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final accent = AppColors.themedPrimary(context);
    final content = Column(
      children: [
        _row(l10n.subtotal, subtotal),
        if (discount > 0) _row(l10n.discount, discount, negative: true),
        if (tax > 0) _row(l10n.tax, tax),
        if (shipping > 0) _row(l10n.shipping, shipping),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              animateTotal
                  ? AnimatedNumber(
                      value: total,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: accent))
                  : MoneyText(
                      value: total,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: accent)),
            ],
          ),
        ),
      ],
    );
    return compact ? content : AppCard(child: content);
  }
}

/// The full "printable paper" look for the invoice — used both on-screen
/// in Invoice Preview and mirrored by the PDF generator.
class InvoicePaper extends ConsumerWidget {
  final Invoice invoice;
  final Customer? customer;
  final BusinessProfile business;

  /// 0 = Classic, 1 = Modern, 2 = Minimal. See [InvoiceTemplates].
  final int template;

  const InvoicePaper(
      {super.key,
      required this.invoice,
      required this.customer,
      required this.business,
      this.template = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final isModern = template == 1;
    final isMinimal = template == 2;
    final Color brandColor =
        isMinimal ? const Color(0xFF3A3A3A) : AppColors.primary;
    final Color headerInk = isModern ? Colors.white : _paperInk;
    final Color headerMuted = isModern ? Colors.white70 : _paperMuted;

    // Logo + invoice title | business address & contact — the address
    // column moves below on narrow (phone-width) screens so the title
    // never gets squeezed into a letter-by-letter wrap. Extracted so the
    // Modern template can render it full-bleed (no side/top inset)
    // outside the card's normal content padding.
    final headerSection = LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;
                  final hasAddressBlock = business.address.isNotEmpty ||
                      business.phone.isNotEmpty ||
                      business.email.isNotEmpty;

                  final addressBlock = !hasAddressBlock
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: isNarrow
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            if (business.address.isNotEmpty)
                              Text(business.address,
                                  textAlign: isNarrow
                                      ? TextAlign.left
                                      : TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: headerMuted,
                                      height: 1.5)),
                            if (business.phone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(business.phone,
                                    textAlign: isNarrow
                                        ? TextAlign.left
                                        : TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: headerMuted)),
                              ),
                            if (business.email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(business.email,
                                    textAlign: isNarrow
                                        ? TextAlign.left
                                        : TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: headerMuted)),
                              ),
                          ],
                        );

                  final titleRow = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedEntry(
                        duration: AppDurations.medium,
                        offsetY: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: business.logoBytes != null
                              ? Image.memory(
                                  Uint8List.fromList(business.logoBytes!),
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.contain,
                                )
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: isModern ? Colors.white : brandColor,
                                  alignment: Alignment.center,
                                  child: Text(
                                    business.businessName.isNotEmpty
                                        ? business.businessName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: isModern
                                            ? brandColor
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(l10n.invoicePaperTitle(invoice.invoiceNumber),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 18,
                                        color: headerInk)),
                                StatusBadge(status: invoice.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(business.businessName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: headerInk)),
                            if (invoice.poNumber.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(l10n.refLine(invoice.poNumber),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: headerMuted)),
                              ),
                            if (isNarrow && hasAddressBlock) ...[
                              const SizedBox(height: 8),
                              addressBlock,
                            ],
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 10),
                        SizedBox(width: 130, child: addressBlock),
                      ],
                    ],
                  );

                  if (!isModern) return titleRow;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    color: brandColor,
                    child: titleRow,
                  );
    });

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            isMinimal ? Border.all(color: Colors.black.withOpacity(0.12)) : null,
        boxShadow: isMinimal
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 12)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand accent strip — Classic only; Modern's header itself
          // already carries the brand color full-bleed, edge to edge,
          // and Minimal stays monochrome.
          if (!isModern && !isMinimal)
            Container(height: 5, width: double.infinity, color: brandColor),
          if (isModern) headerSection,
          Padding(
            padding: EdgeInsets.fromLTRB(22, isModern ? 18 : 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isModern) headerSection,
                if (!isModern) const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Bill to | invoice meta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.billTo,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _paperMuted,
                                  letterSpacing: 0.6)),
                          const SizedBox(height: 6),
                          Text(customer?.name ?? l10n.walkInCustomer,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _paperInk)),
                          if ((customer?.address ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(customer!.address,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _paperMuted)),
                            ),
                          if ((customer?.phone ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(customer!.phone,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _paperMuted)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MetaRow(l10n.invoiceDate.toUpperCase(),
                              AppFormatters.dateInput(invoice.invoiceDate)),
                          const SizedBox(height: 10),
                          _MetaRow(
                              l10n.dueDate.toUpperCase(),
                              invoice.dueDate != null
                                  ? AppFormatters.dateInput(invoice.dueDate!)
                                  : l10n.onReceiptShort),
                          const SizedBox(height: 10),
                          _MetaRow(l10n.balanceDue.toUpperCase(),
                              AppFormatters.money(invoice.balanceDue),
                              valueColor: AppColors.danger),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Items — a clean, spacious receipt-style list instead of
                // a cramped multi-column grid (which truncated on narrow
                // screens). Each item gets its own two-line block.
                Text(l10n.itemsTitle.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _paperMuted,
                        letterSpacing: 0.6)),
                const SizedBox(height: 12),
                ...invoice.items.map((item) {
                  final pct = item.lineSubtotal > 0
                      ? (item.discount / item.lineSubtotal * 100)
                      : 0;
                  final qtyStr = item.quantity
                      .toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                      color: _paperInk)),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                      '${AppFormatters.money(item.price)} × $qtyStr',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: _paperMuted)),
                                  if (item.discount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.danger.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          '-${AppFormatters.money(item.discount)} (${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%)',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.danger)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppFormatters.money(item.lineTotal),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _paperInk)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Payment instructions | totals — stacks vertically on
                // narrow (phone-width) screens instead of overflowing.
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;

                  final totalsBox = Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TotalRow(l10n.subtotal.toUpperCase(), invoice.subtotal),
                      if (invoice.discount > 0)
                        _TotalRow(l10n.discount.toUpperCase(), invoice.discount, negative: true),
                      if (invoice.tax > 0) _TotalRow(l10n.tax.toUpperCase(), invoice.tax),
                      if (invoice.shipping > 0)
                        _TotalRow(l10n.shipping.toUpperCase(), invoice.shipping),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1)),
                      _TotalRow(l10n.total.toUpperCase(), invoice.total, bold: true),
                      if (invoice.amountPaid > 0)
                        _TotalRow(
                            l10n.paidOn(AppFormatters.dateInput(invoice.updatedAt)),
                            invoice.amountPaid),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: AppColors.danger, width: 1.4)),
                        ),
                        width: double.infinity,
                        child: _TotalRow(l10n.balanceDue.toUpperCase(), invoice.balanceDue,
                            bold: true, color: AppColors.danger),
                      ),
                    ],
                  );

                  final paymentBox = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.paymentInstruction.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _paperMuted,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final method = invoice.paymentMethod.isNotEmpty
                              ? invoice.paymentMethod
                              : 'Bank Transfer';
                          const emphasized = TextStyle(
                              fontSize: 14,
                              color: _paperInk,
                              fontWeight: FontWeight.w800);

                          if (method == 'QRIS') {
                            final qrisId = business.qrisId;
                            return SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (qrisId.isNotEmpty)
                                    Text('MID: $qrisId',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _paperInk)),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: 150,
                                    height: 150,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: Colors.black12),
                                    ),
                                    child: qrisId.isNotEmpty
                                        ? QrImageView(
                                            data: qrisId,
                                            backgroundColor: Colors.white,
                                            eyeStyle: const QrEyeStyle(
                                                color: _paperInk),
                                            dataModuleStyle:
                                                const QrDataModuleStyle(
                                                    color: _paperInk),
                                          )
                                        : const Icon(Icons.qr_code_2_rounded,
                                            color: _paperMuted, size: 48),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(l10n.scanQrisToPay,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _paperMuted)),
                                ],
                              ),
                            );
                          }

                          final List<InlineSpan> detailSpans;
                          switch (method) {
                            case 'E-Wallet':
                              detailSpans = [
                                TextSpan(
                                    text:
                                        '${business.eWalletProvider.isNotEmpty ? business.eWalletProvider : l10n.paymentMethodLabel('E-Wallet')}: '),
                                TextSpan(
                                    text: business.eWalletNumber,
                                    style: emphasized),
                              ];
                              break;
                            case 'Cash':
                              detailSpans = [
                                TextSpan(text: l10n.paymentDueCash),
                              ];
                              break;
                            default:
                              detailSpans = [
                                TextSpan(
                                    text:
                                        '${business.bankName} : ${business.bankAccountName}'),
                                if (business.bankAccountNumber.isNotEmpty)
                                  TextSpan(
                                      text: '\n${business.bankAccountNumber}',
                                      style: emphasized),
                              ];
                          }
                          return Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _paperMuted,
                                  height: 1.5),
                              children: [
                                TextSpan(
                                    text: '${l10n.paymentMethodLabel(method)}: ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _paperInk)),
                                ...detailSpans,
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        totalsBox,
                        const SizedBox(height: 16),
                        paymentBox,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: paymentBox),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: totalsBox),
                    ],
                  );
                }),

                if (invoice.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(l10n.notesLabel,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _paperMuted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Text(invoice.notes,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: _paperMuted,
                          height: 1.4,
                          fontStyle: FontStyle.italic)),
                ],
                if (invoice.attachmentBytes != null) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(l10n.attachmentLabel,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _paperMuted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      Uint8List.fromList(invoice.attachmentBytes!),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (invoice.signatureBytes != null || invoice.isApproved) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(l10n.approvalLabel,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _paperMuted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  if (invoice.signatureBytes != null)
                    Image.memory(Uint8List.fromList(invoice.signatureBytes!),
                        height: 70,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft),
                  const SizedBox(height: 4),
                  Text(
                    invoice.isApproved
                        ? l10n.approvedBy(invoice.approverName.isNotEmpty
                            ? invoice.approverName
                            : l10n.customerFallback)
                        : l10n.pendingApproval,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          invoice.isApproved ? AppColors.success : _paperMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A right-aligned label/value pair used in the invoice header meta block
/// (invoice date, due date, balance due). Label sits above the value so
/// neither ever has to fight the other for horizontal room.
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _paperMuted,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? _paperInk)),
      ],
    );
  }
}

/// A totals-block row (subtotal / tax / total / balance due) used in the
/// invoice paper's payment summary column.
class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool negative;
  final Color? color;
  const _TotalRow(this.label, this.value,
      {this.bold = false, this.negative = false, this.color});

  @override
  Widget build(BuildContext context) {
    final text = negative && value > 0
        ? '-${AppFormatters.money(value)}'
        : AppFormatters.money(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: bold ? 13.5 : 12,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color ?? (bold ? _paperInk : _paperMuted))),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: bold ? 13.5 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: color ?? _paperInk)),
        ],
      ),
    );
  }
}
