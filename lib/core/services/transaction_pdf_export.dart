import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/budget/domain/models/budget_profile.dart';
import '../../features/budget/domain/models/month_liquidity_snapshot.dart';
import '../../features/budget/domain/models/spending_kind.dart';
import '../../features/budget/domain/models/transaction_entry.dart';
import '../utils/month_utils.dart';

/// PDF amounts: use "Rs." instead of the rupee sign so built-in PDF fonts render reliably.
class TransactionPdfExport {
  TransactionPdfExport._();

  static final NumberFormat _pdfInr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String _money(num v) => _pdfInr.format(v);

  // Brand-ish colors (RGB 0-1)
  static final PdfColor _ink = PdfColor(0.06, 0.07, 0.09);
  static final PdfColor _muted = PdfColor(0.38, 0.42, 0.48);
  static final PdfColor _surface = PdfColor(0.96, 0.97, 0.98);
  static final PdfColor _border = PdfColor(0.85, 0.87, 0.91);
  static final PdfColor _accent = PdfColor(0.39, 0.40, 0.95);
  static final PdfColor _headerBg = PdfColor(0.09, 0.10, 0.13);
  static final PdfColor _positive = PdfColor(0.13, 0.55, 0.35);
  static final PdfColor _negative = PdfColor(0.85, 0.22, 0.18);

  static Future<void> shareMonthStatement({
    required DateTime month,
    required List<TransactionEntry> items,
    BudgetProfile? profile,
  }) async {
    final m = MonthUtils.startOfMonth(month);
    final monthLabel = MonthUtils.formatMonthYear(m);
    final sorted = [...items]
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    double credits = 0;
    double debits = 0;
    for (final t in sorted) {
      if (t.isCredit) {
        credits += t.amount;
      } else {
        debits += t.amount;
      }
    }
    final net = credits - debits;
    final liq = liquiditySnapshotForTransactions(sorted);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (context) => [
          _docHeader(
            title: 'Kharcha',
            subtitle: 'Account statement',
            metaLine: 'Statement period: $monthLabel',
          ),
          if (profile != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Reference income (profile): ${_money(profile.monthlyIncome)} / month',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
          pw.SizedBox(height: 18),
          _summaryRow(
            left: ('Total credits', credits, _positive),
            mid: ('Total debits', debits, _negative),
            right: ('Net', net, net >= 0 ? _positive : _negative),
          ),
          pw.SizedBox(height: 16),
          _liquidityCard(liq),
          pw.SizedBox(height: 20),
          _sectionTitle('Transactions (${sorted.length})'),
          pw.SizedBox(height: 8),
          _txTable(sorted),
          pw.SizedBox(height: 28),
          _footer(),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'kharcha_statement_${m.year}_${m.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  static Future<void> shareReport({
    required String periodLabel,
    required List<TransactionEntry> items,
    BudgetProfile? profile,
  }) async {
    final sorted = [...items]
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    double credits = 0;
    double debits = 0;
    double needs = 0;
    double wants = 0;
    double savings = 0;
    double otherDebit = 0;

    for (final t in sorted) {
      if (t.isCredit) {
        credits += t.amount;
      } else {
        debits += t.amount;
        final k = t.spendingKind;
        if (k == null) {
          otherDebit += t.amount;
        } else {
          switch (k) {
            case SpendingKind.need:
              needs += t.amount;
            case SpendingKind.want:
            case SpendingKind.other:
              wants += t.amount;
            case SpendingKind.saving:
              savings += t.amount;
          }
        }
      }
    }
    final net = credits - debits;
    final liq = liquiditySnapshotForTransactions(sorted);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (context) => [
          _docHeader(
            title: 'Kharcha',
            subtitle: 'Financial report',
            metaLine: 'Period: $periodLabel',
          ),
          if (profile != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Monthly income (reference): ${_money(profile.monthlyIncome)}',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
          pw.SizedBox(height: 18),
          _summaryRow(
            left: ('Total income', credits, _positive),
            mid: ('Total expenses', debits, _negative),
            right: ('Net', net, net >= 0 ? _positive : _negative),
          ),
          pw.SizedBox(height: 16),
          _liquidityCard(liq),
          pw.SizedBox(height: 16),
          _sectionTitle('Category breakdown (expenses)'),
          pw.SizedBox(height: 6),
          pw.Text(
            'Needs: ${_money(needs)}   |   Wants: ${_money(wants)}   |   '
            'Savings: ${_money(savings)}'
            '${otherDebit > 0.01 ? '   |   Other: ${_money(otherDebit)}' : ''}',
            style: pw.TextStyle(fontSize: 9.5, color: _ink, height: 1.35),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Transactions (${sorted.length})'),
          pw.SizedBox(height: 8),
          _txTable(sorted),
          pw.SizedBox(height: 28),
          _footer(),
        ],
      ),
    );

    final bytes = await doc.save();
    var safe = periodLabel.replaceAll(RegExp(r'[^\w\-]'), '_');
    if (safe.isEmpty) safe = 'export';
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'kharcha_report_$safe.pdf',
    );
  }

  static pw.Widget _docHeader({
    required String title,
    required String subtitle,
    required String metaLine,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.Container(
              width: 4,
              color: _accent,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(0.18, 0.19, 0.22),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    metaLine,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11.5,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
        letterSpacing: 0.2,
      ),
    );
  }

  static pw.Widget _summaryRow({
    required (String label, double value, PdfColor color) left,
    required (String label, double value, PdfColor color) mid,
    required (String label, double value, PdfColor color) right,
  }) {
    pw.Widget cell((String label, double value, PdfColor color) x) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                x.$1.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: _muted,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                _money(x.$2),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: x.$3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        cell(left),
        pw.SizedBox(width: 10),
        cell(mid),
        pw.SizedBox(width: 10),
        cell(right),
      ],
    );
  }

  static pw.Widget _liquidityCard(MonthLiquiditySnapshot s) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CASH VS ONLINE (THIS PERIOD)',
            style: pw.TextStyle(
              fontSize: 7.5,
              color: _muted,
              letterSpacing: 0.9,
            ),
          ),
          pw.SizedBox(height: 8),
          _liqLine('Cash', s.creditCash, s.debitCash, s.netCash),
          pw.SizedBox(height: 6),
          _liqLine('Online', s.creditOnline, s.debitOnline, s.netOnline),
          if (s.hasUnspecified) ...[
            pw.SizedBox(height: 6),
            _liqLine(
              'Unspecified',
              s.creditUnspecified,
              s.debitUnspecified,
              s.netUnspecified,
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _liqLine(
    String label,
    double in_,
    double out,
    double left,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            'In ${_money(in_)}   Out ${_money(out)}   Left ${_money(left)}',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
      ],
    );
  }

  static pw.Widget _txTable(List<TransactionEntry> sorted) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _border, width: 0.5),
        bottom: pw.BorderSide(color: _border, width: 0.5),
        top: pw.BorderSide(color: _border, width: 0.5),
        left: pw.BorderSide(color: _border, width: 0.5),
        right: pw.BorderSide(color: _border, width: 0.5),
        verticalInside: pw.BorderSide(color: _border, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(68),
        1: const pw.FixedColumnWidth(32),
        2: const pw.FlexColumnWidth(2.3),
        3: const pw.FlexColumnWidth(1.9),
        4: const pw.FixedColumnWidth(76),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor(0.93, 0.94, 0.96),
          ),
          children: [
            _th('Date'),
            _th('Type'),
            _th('Description'),
            _th('Category'),
            _th('Amount'),
          ],
        ),
        ...sorted.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          final d = t.effectiveDate.toLocal();
          final dateStr =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          final type = t.isCredit ? 'CR' : 'DR';
          final zebra = i.isOdd ? PdfColor(0.995, 0.996, 0.998) : PdfColors.white;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: zebra),
            children: [
              _td(dateStr),
              _td(type),
              _td(t.title),
              _td(t.displayCategoryLine),
              _td(
                '${t.isCredit ? '+' : '-'}${_money(t.amount)}',
                align: pw.TextAlign.right,
                strong: true,
                positive: t.isCredit,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.8,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool strong = false,
    bool positive = false,
  }) {
    final c = strong
        ? (positive ? _positive : _negative)
        : _ink;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: strong ? 8.5 : 8,
          fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: strong ? c : _ink,
        ),
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 1,
          color: _border,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by Kharcha. Amounts in Indian Rupees (Rs.). '
          'Use the Kharcha app for live balances and budgets.',
          style: pw.TextStyle(fontSize: 7.5, color: _muted, height: 1.35),
        ),
      ],
    );
  }
}
