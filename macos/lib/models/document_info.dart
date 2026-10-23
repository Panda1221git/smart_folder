class DocumentInfo {
  final String documentType;
  final String sender;
  final String date;
  final String billingPeriod;
  final String invoiceNumber;

  final String amount;
  final String netAmount;
  final String taxAmount;
  final String taxRate;

  final String recipient;

  final String suggestedFileName;
  final String rawText;

  const DocumentInfo({
    required this.documentType,
    required this.sender,
    required this.date,
    required this.billingPeriod,
    required this.invoiceNumber,
    required this.amount,
    required this.netAmount,
    required this.taxAmount,
    required this.taxRate,
    required this.recipient,
    required this.suggestedFileName,
    required this.rawText,
  });
}