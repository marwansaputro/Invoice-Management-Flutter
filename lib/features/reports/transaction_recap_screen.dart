import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_motion.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../invoices/invoice_detail_screen.dart';

enum _Period { today, week, month, year, all }

/// Aggregates invoices into a revenue/paid/pending/overdue summary for a
/// selectable period (today / this week / this month / this year / all
/// time), plus a scrollable list of the invoices that fall in it.
class TransactionRecapScreen extends ConsumerStatefulWidget {
  const TransactionRecapScreen({super.key});

  @override
  ConsumerState<TransactionRecapScreen> createState() =>
      _TransactionRecapScreenState();
}

class _TransactionRecapScreenState
    extends ConsumerState<TransactionRecapScreen> {
  _Period _period = _Period.month;

  bool _inPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case _Period.week:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
      case _Period.month:
        return date.year == now.year && date.month == now.month;
      case _Period.year:
        return date.year == now.year;
      case _Period.all:
        return true;
    }
  }

  /// Buckets the period's revenue into bars matching the selected period's
  /// granularity — hourly for Today, daily for Week/Month, monthly for
  /// Year, yearly for All Time — so the chart always reflects what the
  /// period chips say it's showing.
  List<({String label, double value})> _chartPoints(List<Invoice> periodInvoices) {
    final countable = periodInvoices.where((i) => i.status != InvoiceStatus.draft);
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        const bucketHours = 4;
        const bucketCount = 24 ~/ bucketHours;
        final buckets = List<double>.filled(bucketCount, 0);
        for (final inv in countable) {
          final idx = (inv.invoiceDate.hour ~/ bucketHours).clamp(0, bucketCount - 1);
          buckets[idx] += inv.total;
        }
        return List.generate(bucketCount,
            (i) => (label: (i * bucketHours).toString().padLeft(2, '0'), value: buckets[i]));

      case _Period.week:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final buckets = List<double>.filled(7, 0);
        for (final inv in countable) {
          final d = DateTime(inv.invoiceDate.year, inv.invoiceDate.month, inv.invoiceDate.day);
          final idx = d.difference(startOfWeek).inDays;
          if (idx >= 0 && idx < 7) buckets[idx] += inv.total;
        }
        return List.generate(7, (i) => (label: weekdayLabels[i], value: buckets[i]));

      case _Period.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final buckets = List<double>.filled(daysInMonth, 0);
        for (final inv in countable) {
          if (inv.invoiceDate.year == now.year && inv.invoiceDate.month == now.month) {
            buckets[inv.invoiceDate.day - 1] += inv.total;
          }
        }
        return List.generate(daysInMonth, (i) => (label: '${i + 1}', value: buckets[i]));

      case _Period.year:
        const monthLabels = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final buckets = List<double>.filled(12, 0);
        for (final inv in countable) {
          if (inv.invoiceDate.year == now.year) {
            buckets[inv.invoiceDate.month - 1] += inv.total;
          }
        }
        return List.generate(12, (i) => (label: monthLabels[i], value: buckets[i]));

      case _Period.all:
        if (countable.isEmpty) return const [];
        final years = countable.map((i) => i.invoiceDate.year).toSet().toList()..sort();
        final buckets = {for (final y in years) y: 0.0};
        for (final inv in countable) {
          buckets[inv.invoiceDate.year] = (buckets[inv.invoiceDate.year] ?? 0) + inv.total;
        }
        return years.map((y) => (label: '$y', value: buckets[y]!)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final invoices = ref.watch(invoiceRepositoryProvider);
    final customers = ref.watch(customerRepositoryProvider);
    final filtered = invoices.where((inv) => _inPeriod(inv.invoiceDate)).toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    String customerName(String id) {
      try {
        return customers.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return 'Walk-in Customer';
      }
    }

    double revenue = 0, paid = 0, pending = 0, overdue = 0, collected = 0;
    var countableInvoices = 0;
    for (final inv in filtered) {
      if (inv.status == InvoiceStatus.draft) continue;
      countableInvoices++;
      revenue += inv.total;
      collected += inv.amountPaid;
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

    final periods = [
      (period: _Period.today, label: l10n.periodToday),
      (period: _Period.week, label: l10n.periodWeek),
      (period: _Period.month, label: l10n.periodMonth),
      (period: _Period.year, label: l10n.periodYear),
      (period: _Period.all, label: l10n.periodAll),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionRecap)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.recapSubtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13.5)),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = periods[i];
                  final selected = p.period == _period;
                  final accent = AppColors.themedPrimary(context);
                  return PressableScale(
                    onTap: () => setState(() => _period = p.period),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? accent
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? accent
                                : Theme.of(context).dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(p.label,
                          style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: _RecapCard(
                          label: l10n.totalRevenue,
                          value: AppFormatters.money(revenue),
                          color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _RecapCard(
                          label: l10n.totalCollected,
                          value: AppFormatters.money(collected),
                          color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                      child: _RecapMiniStat(
                          label: l10n.paid,
                          value: AppFormatters.money(paid),
                          color: AppColors.success)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _RecapMiniStat(
                          label: l10n.pending,
                          value: AppFormatters.money(pending),
                          color: AppColors.warning)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _RecapMiniStat(
                          label: l10n.overdue,
                          value: AppFormatters.money(overdue),
                          color: AppColors.danger)),
                ],
              ),
            ),
            if (filtered.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.revenueOverview,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: _PeriodBarChart(
                    key: ValueKey(_period),
                    points: _chartPoints(filtered),
                    color: AppColors.themedPrimary(context),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${l10n.totalInvoices}: $countableInvoices',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      title: l10n.noTransactionsTitle,
                      message: l10n.noTransactionsMessage,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final invoice = filtered[i];
                        return InvoiceListCard(
                          invoice: invoice,
                          customerName: customerName(invoice.customerId),
                          onTap: () => Navigator.of(context).push(
                              SlideFadeRoute(
                                  page: InvoiceDetailScreen(
                                      invoiceId: invoice.id))),
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

class _RecapCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RecapCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child:
                Icon(Icons.trending_up_rounded, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

class _RecapMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RecapMiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Horizontally-scrollable revenue bar chart. Bars are keyed to whatever
/// buckets [_TransactionRecapScreenState._chartPoints] produced for the
/// selected period, so it works unchanged whether that's 6 hourly bars or
/// 31 daily ones.
class _PeriodBarChart extends StatelessWidget {
  final List<({String label, double value})> points;
  final Color color;
  const _PeriodBarChart({super.key, required this.points, required this.color});

  static const double _maxBarHeight = 110;
  // Value label (16) + spacing (4) + bar (_maxBarHeight) + spacing (6) + day label (16).
  static const double _chartHeight = _maxBarHeight + 42;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((p) => p.value <= 0)) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: Icon(Icons.bar_chart_rounded,
              size: 32, color: AppColors.textSecondary.withOpacity(0.4)),
        ),
      );
    }
    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: _chartHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: points.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = points[i];
          final isPeak = maxValue > 0 && p.value == maxValue;
          return _Bar(
            label: p.label,
            value: p.value,
            heightFraction: maxValue > 0 ? p.value / maxValue : 0,
            maxHeight: _maxBarHeight,
            color: color,
            highlight: isPeak,
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final double heightFraction;
  final double maxHeight;
  final Color color;
  final bool highlight;
  const _Bar({
    required this.label,
    required this.value,
    required this.heightFraction,
    required this.maxHeight,
    required this.color,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 16,
            child: highlight && value > 0
                ? Text(AppFormatters.moneyCompact(value),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                        fontSize: 9.5, fontWeight: FontWeight.w800, color: color))
                : null,
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: heightFraction.clamp(0, 1)),
            duration: AppDurations.slow,
            curve: AppCurves.standard,
            builder: (context, v, _) => Container(
              height: value > 0 ? (maxHeight * v).clamp(4, maxHeight) : 4,
              width: 18,
              decoration: BoxDecoration(
                color: highlight ? color : color.withOpacity(0.32),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
