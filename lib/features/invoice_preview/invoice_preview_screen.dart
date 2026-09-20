import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';

enum _SendState { idle, loading, success }

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final GlobalKey _previewKey = GlobalKey();
  _SendState _sendState = _SendState.idle;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: AppDurations.slow)
      ..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Invoice? get _invoice =>
      ref.read(invoiceRepositoryProvider.notifier).byId(widget.invoiceId);

  Future<void> _handleSend() async {
    setState(() => _sendState = _SendState.loading);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sendState = _SendState.success);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppSnackbar.show(context,
        message: AppStrings(ref.read(localeProvider)).invoiceSentSuccessfully,
        icon: Icons.check_circle_rounded,
        color: AppColors.success);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sendState = _SendState.idle);
  }

  /// Renders the on-screen invoice card (exactly as shown in the preview)
  /// to a .jpg file, so it can be shared as an image to WhatsApp and
  /// other apps instead of a bare text message.
  Future<File?> _captureInvoiceJpg() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final uiImage = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      final image = img.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: byteData.buffer,
        numChannels: 4,
      );
      final jpgBytes = img.encodeJpg(image, quality: 92);
      final dir = await getTemporaryDirectory();
      final invoice = _invoice;
      final file =
          File('${dir.path}/${invoice?.invoiceNumber ?? 'invoice'}.jpg');
      await file.writeAsBytes(jpgBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openShareSheet() async {
    final invoice = _invoice;
    if (invoice == null) return;
    final imageFile = await _captureInvoiceJpg();
    if (!mounted) return;
    await showAppBottomSheet(context,
        child: _ShareSheet(invoice: invoice, imageFile: imageFile));
  }

  Future<void> _generateAndOpenPdf() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _generatingPdf = true);
    final customer =
        ref.read(customerRepositoryProvider.notifier).byId(invoice.customerId);
    final business = AppDatabase.business;

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PreparingPdfDialog(),
    ));

    final bytes = await PdfGenerator.generateInvoicePdf(
        invoice: invoice,
        customer: customer,
        business: business,
        template: AppDatabase.settings.invoiceTemplate,
        locale: ref.read(localeProvider));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close preparing dialog
    setState(() => _generatingPdf = false);

    await showScaleFadeDialog(context,
        child:
            _PdfReadyDialog(file: file, invoiceNumber: invoice.invoiceNumber));
  }

  void unawaited(Future future) {}

  @override
  Widget build(BuildContext context) {
    ref.watch(invoiceRepositoryProvider);
    final invoice = _invoice;
    final l10n = AppStrings(ref.watch(localeProvider));
    if (invoice == null) {
      return Scaffold(body: Center(child: Text(l10n.invoiceNotFound)));
    }
    final customer =
        ref.watch(customerRepositoryProvider.notifier).byId(invoice.customerId);
    final business = AppDatabase.business;

    final logoAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: AppCurves.bounce),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(l10n.preview,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: _generatingPdf
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: _generatingPdf ? null : _generateAndOpenPdf,
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                invoice.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(invoice.isFavorite),
                color: invoice.isFavorite ? AppColors.secondary : Colors.white,
              ),
            ),
            onPressed: () => ref
                .read(invoiceRepositoryProvider.notifier)
                .toggleFavorite(invoice.id),
          ),
        ],
      ),
      body: FadeTransition(
        opacity:
            CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.3)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 120),
            children: [
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, child) {
                  final t = CurvedAnimation(
                          parent: _entrance,
                          curve: const Interval(0.1, 0.7,
                              curve: AppCurves.standard))
                      .value;
                  return Opacity(
                    opacity: t.clamp(0, 1),
                    child: Transform.translate(
                        offset: Offset(0, (1 - t.clamp(0, 1)) * 40),
                        child: child),
                  );
                },
                child: ScaleTransition(
                  scale: logoAnim.drive(Tween(begin: 0.98, end: 1)),
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: Container(
                      color: const Color(0xFFF1F3F6),
                      padding: const EdgeInsets.all(4),
                      child: InvoicePaper(
                          invoice: invoice,
                          customer: customer,
                          business: business,
                          template: AppDatabase.settings.invoiceTemplate),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = CurvedAnimation(
                  parent: _entrance,
                  curve: const Interval(0.55, 1, curve: AppCurves.bounce))
              .value
              .clamp(0.0, 1.0);
          return Transform.scale(
              scale: 0.7 + 0.3 * t, child: Opacity(opacity: t, child: child));
        },
        child: _SendFab(
            state: _sendState,
            onSend: () async {
              await _handleSend();
            },
            onShare: _openShareSheet),
      ),
    );
  }
}

class _SendFab extends ConsumerWidget {
  final _SendState state;
  final VoidCallback onSend;
  final VoidCallback onShare;
  const _SendFab(
      {required this.state, required this.onSend, required this.onShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return PressableScale(
      scaleDown: 0.94,
      onTap: state == _SendState.idle
          ? () async {
              onSend();
              await Future.delayed(const Duration(milliseconds: 1600));
              if (context.mounted) onShare();
            }
          : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.normal,
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: RotationTransition(
                      turns: Tween<double>(begin: 0.85, end: 1).animate(anim),
                      child: child)),
              child: switch (state) {
                _SendState.idle => const Icon(Icons.send_rounded,
                    key: ValueKey('idle'), color: Colors.white, size: 20),
                _SendState.loading => const SizedBox(
                    key: ValueKey('loading'),
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  ),
                _SendState.success => const Icon(Icons.check_rounded,
                    key: ValueKey('success'), color: Colors.white, size: 22),
              },
            ),
            const SizedBox(width: 10),
            Text(
              switch (state) {
                _SendState.idle => l10n.send,
                _SendState.loading => l10n.sending,
                _SendState.success => l10n.sent,
              },
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparingPdfDialog extends ConsumerStatefulWidget {
  const _PreparingPdfDialog();

  @override
  ConsumerState<_PreparingPdfDialog> createState() => _PreparingPdfDialogState();
}

class _PreparingPdfDialogState extends ConsumerState<_PreparingPdfDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: AppColors.solidSurface(context),
            borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                  offset: Offset(0, -8 * _controller.value), child: child),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: AppColors.themedPrimary(context).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Icon(Icons.description_rounded,
                    color: AppColors.themedPrimary(context), size: 28),
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.preparingInvoice,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Text(l10n.generatingPdf,
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _PdfReadyDialog extends ConsumerWidget {
  final File file;
  final String invoiceNumber;
  const _PdfReadyDialog({required this.file, required this.invoiceNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
              color: AppColors.solidSurface(context),
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 30),
              ),
              const SizedBox(height: 16),
              Text(l10n.pdfReady,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('$invoiceNumber.pdf',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.openPdf,
                icon: Icons.open_in_new_rounded,
                expand: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(
                      onLayout: (format) async => file.readAsBytesSync());
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: l10n.share,
                type: AppButtonStyleType.outline,
                icon: Icons.ios_share_rounded,
                expand: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(file.path)],
                      text: l10n.shareInvoiceText(invoiceNumber));
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: l10n.close,
                type: AppButtonStyleType.text,
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSheet extends ConsumerWidget {
  final Invoice invoice;
  final File? imageFile;
  const _ShareSheet({required this.invoice, this.imageFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final options = [
      ('WhatsApp', Icons.chat_rounded, AppColors.success),
      (l10n.emailLabel, Icons.email_rounded, AppColors.themedPrimary(context)),
      ('Telegram', Icons.send_rounded, const Color(0xFF29A9EA)),
      (l10n.otherApps, Icons.more_horiz_rounded, AppColors.textSecondary),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sendInvoiceTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(l10n.shareVia,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: options
              .map((o) => PressableScale(
                    onTap: () async {
                      Navigator.pop(context);
                      final text = l10n.shareTextMessage(
                          invoice.invoiceNumber, invoice.total.toStringAsFixed(0));
                      if (imageFile != null) {
                        await Share.shareXFiles([XFile(imageFile!.path)],
                            text: text);
                      } else {
                        await Share.share(text);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                              color: o.$3.withOpacity(0.12),
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(o.$2, color: o.$3, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(o.$1,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(Icons.link_rounded, color: AppColors.themedPrimary(context)),
          title: Text(l10n.copyInvoiceLink,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          onTap: () {
            Navigator.pop(context);
            AppSnackbar.show(context, message: l10n.invoiceLinkCopied);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(Icons.tag_rounded, color: AppColors.themedPrimary(context)),
          title: Text(l10n.copyInvoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          onTap: () {
            Navigator.pop(context);
            AppSnackbar.show(context, message: l10n.invoiceNumberCopied);
          },
        ),
      ],
    );
  }
}
