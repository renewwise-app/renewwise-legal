import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:renew_wise/models/life_insights_models.dart';
import 'package:renew_wise/utils/life_insights_engine.dart';
import 'package:share_plus/share_plus.dart';

class LifeInsightsExport {
  LifeInsightsExport({
    required this.engine,
    required this.snapshot,
  });

  final LifeInsightsEngine engine;
  final LifeInsightsSnapshot snapshot;

  String buildPreviewText() {
    final c = snapshot.currency;
    final buf = StringBuffer()
      ..writeln('RenewWise Life Insights')
      ..writeln('Filter: ${snapshot.filter.label}')
      ..writeln('')
      ..writeln('Overview')
      ..writeln('  Active events: ${snapshot.activeEvents}')
      ..writeln('  Upcoming this month: ${snapshot.upcomingThisMonth}')
      ..writeln('  Completed this year: ${snapshot.completedThisYear}')
      ..writeln('  Total due: ${c.formatAmount(snapshot.totalAmountDue)}')
      ..writeln('')
      ..writeln('Financial')
      ..writeln('  Due this month: ${c.formatAmount(snapshot.amountDueThisMonth)}')
      ..writeln('  Due this year: ${c.formatAmount(snapshot.amountDueThisYear)}')
      ..writeln('  Paid this year: ${c.formatAmount(snapshot.paidThisYear)}')
      ..writeln('  Avg monthly: ${c.formatAmount(snapshot.avgMonthlyPayments)}')
      ..writeln('')
      ..writeln('Completion')
      ..writeln(
        '  Rate: ${snapshot.completion.completionRate.toStringAsFixed(0)}%',
      )
      ..writeln('  On time: ${snapshot.completion.completedOnTime}')
      ..writeln('  Late: ${snapshot.completion.completedLate}')
      ..writeln(
        '  Current streak: ${snapshot.completion.currentStreak} days',
      );

    if (snapshot.categoryGroups.isNotEmpty) {
      buf.writeln('');
      buf.writeln('Categories');
      for (final g in snapshot.categoryGroups) {
        buf.writeln(
          '  ${g.group.label}: ${g.count} (${c.formatAmount(g.amount)})',
        );
      }
    }
    return buf.toString();
  }

  String buildCsv() {
    final c = snapshot.currency;
    final rows = <List<String>>[
      ['Section', 'Metric', 'Value'],
      ['Overview', 'Active Events', '${snapshot.activeEvents}'],
      ['Overview', 'Upcoming This Month', '${snapshot.upcomingThisMonth}'],
      ['Overview', 'Completed This Year', '${snapshot.completedThisYear}'],
      [
        'Overview',
        'Total Amount Due',
        c.formatAmount(snapshot.totalAmountDue),
      ],
      [
        'Financial',
        'Due This Month',
        c.formatAmount(snapshot.amountDueThisMonth),
      ],
      [
        'Financial',
        'Due This Year',
        c.formatAmount(snapshot.amountDueThisYear),
      ],
      ['Financial', 'Paid This Year', c.formatAmount(snapshot.paidThisYear)],
      [
        'Financial',
        'Avg Monthly',
        c.formatAmount(snapshot.avgMonthlyPayments),
      ],
      [
        'Completion',
        'Rate',
        '${snapshot.completion.completionRate.toStringAsFixed(1)}%',
      ],
      ['Completion', 'On Time', '${snapshot.completion.completedOnTime}'],
      ['Completion', 'Late', '${snapshot.completion.completedLate}'],
      [
        'Completion',
        'Current Streak',
        '${snapshot.completion.currentStreak}',
      ],
    ];

    for (final g in snapshot.categoryGroups) {
      rows.add([
        'Category',
        g.group.label,
        '${g.count} / ${c.formatAmount(g.amount)}',
      ]);
    }

    return rows
        .map((r) => r.map(_escapeCsv).join(','))
        .join('\n');
  }

  Future<File> writeCsvFile() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/renewwise_insights_$stamp.csv');
    await file.writeAsString(buildCsv());
    return file;
  }

  Future<File> writePdfFile() async {
    final c = snapshot.currency;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'RenewWise Life Insights',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text('Generated ${DateFormat.yMMMd().add_jm().format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.Text('Filter: ${snapshot.filter.label}'),
          pw.SizedBox(height: 16),
          _pdfSection('Overview', [
            'Active events: ${snapshot.activeEvents}',
            'Upcoming this month: ${snapshot.upcomingThisMonth}',
            'Completed this year: ${snapshot.completedThisYear}',
            'Total due: ${c.formatAmount(snapshot.totalAmountDue)}',
          ]),
          _pdfSection('Financial', [
            'Due this month: ${c.formatAmount(snapshot.amountDueThisMonth)}',
            'Due this year: ${c.formatAmount(snapshot.amountDueThisYear)}',
            'Paid this year: ${c.formatAmount(snapshot.paidThisYear)}',
            'Average monthly: ${c.formatAmount(snapshot.avgMonthlyPayments)}',
          ]),
          _pdfSection('Completion', [
            'Rate: ${snapshot.completion.completionRate.toStringAsFixed(0)}%',
            'On time: ${snapshot.completion.completedOnTime}',
            'Late: ${snapshot.completion.completedLate}',
            'Current streak: ${snapshot.completion.currentStreak} days',
          ]),
          if (snapshot.categoryGroups.isNotEmpty)
            _pdfSection(
              'Categories',
              snapshot.categoryGroups
                  .map(
                    (g) =>
                        '${g.group.label}: ${g.count} events, ${c.formatAmount(g.amount)}',
                  )
                  .toList(),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/renewwise_insights_$stamp.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _pdfSection(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        ...lines.map((l) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(l, style: const pw.TextStyle(fontSize: 11)),
            )),
      ],
    );
  }

  Future<void> shareCsv() async {
    final file = await writeCsvFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'RenewWise Insights',
    );
  }

  Future<void> sharePdf() async {
    final file = await writePdfFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'RenewWise Insights',
    );
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
