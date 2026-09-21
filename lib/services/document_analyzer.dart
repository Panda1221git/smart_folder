import '../models/document_info.dart';
import 'analyzer_context.dart';
import 'document_type_analyzer.dart';
import 'sender_analyzer.dart';
import 'date_analyzer.dart';
import 'billing_period_analyzer.dart';
import 'invoice_number_analyzer.dart';
import 'gross_amount_analyzer.dart';
import 'net_amount_analyzer.dart';
import 'tax_analyzer.dart';
import 'recipient_analyzer.dart';

/// SmartFolder orchestrator.
///
/// Each field is intentionally delegated to a specialist analyzer.
/// The public API remains compatible with the existing app:
/// DocumentAnalyzer.analyze(text)
class DocumentAnalyzer {
  static DocumentInfo analyze(String text) {
    final context = AnalyzerContext.fromText(text);

    final documentType = DocumentTypeAnalyzer.analyze(context);
    final sender = SenderAnalyzer.analyze(context);
    final date = DateAnalyzer.analyze(context);
    final billingPeriod = BillingPeriodAnalyzer.analyze(context);
    final invoiceNumber = InvoiceNumberAnalyzer.analyze(context);
    final grossAmount = GrossAmountAnalyzer.analyze(context);
    final netAmount = NetAmountAnalyzer.analyze(context);
    final taxAmount = TaxAnalyzer.analyzeAmount(context);
    final taxRate = TaxAnalyzer.analyzeRate(context);
    final recipient = RecipientAnalyzer.analyze(context, sender.value);

    return DocumentInfo(
      documentType: documentType.value,
      sender: sender.value,
      date: date.value,
      billingPeriod: billingPeriod.value,
      invoiceNumber: invoiceNumber.value,
      amount: grossAmount.value,
      netAmount: netAmount.value,
      taxAmount: taxAmount.value,
      taxRate: taxRate.value,
      recipient: recipient.value,
      suggestedFileName: _createFileName(
        date: date.value,
        sender: sender.value,
        documentType: documentType.value,
        invoiceNumber: invoiceNumber.value,
      ),
      rawText: text,
    );
  }

  static String _createFileName({
    required String date,
    required String sender,
    required String documentType,
    required String invoiceNumber,
  }) {
    final parts = <String>[];

    if (date.isNotEmpty) {
      parts.add(_normalizeDate(date));
    }
    if (sender.isNotEmpty) {
      parts.add(sender);
    }
    if (documentType.isNotEmpty) {
      parts.add(documentType);
    }
    if (invoiceNumber.isNotEmpty) {
      parts.add(invoiceNumber);
    }

    if (parts.isEmpty) return 'Dokument.pdf';

    return '${_cleanFileName(parts.join('_'))}.pdf';
  }

  static String _normalizeDate(String date) {
    final match = RegExp(
      r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4})$',
    ).firstMatch(date.trim());

    if (match == null) return date.trim();

    final day = match.group(1)!.padLeft(2, '0');
    final month = match.group(2)!.padLeft(2, '0');

    var year = match.group(3)!;
    if (year.length == 2) year = '20$year';

    return '$year-$month-$day';
  }

  static String _cleanFileName(String value) {
    return value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
