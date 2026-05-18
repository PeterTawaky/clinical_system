class DebtModel {
  final int debtId;
  final String creationDate;
  final String? paymentDate;
  final double amount;
  final String status;
  final String username;
  final int categoryId;
  final String categoryName;
  final int branchId;
  final String branchName;
  final int? purchaseId;
  final int? examId;
  final int? invoiceId;
  final String? description;

  const DebtModel({
    required this.debtId,
    required this.creationDate,
    this.paymentDate,
    required this.amount,
    required this.status,
    required this.username,
    required this.categoryId,
    required this.categoryName,
    required this.branchId,
    required this.branchName,
    this.purchaseId,
    this.examId,
    this.invoiceId,
    this.description,
  });

  String get source {
    if (examId != null) return 'كشف #$examId';
    if (purchaseId != null) return 'مشتريات #$purchaseId';
    if (invoiceId != null) return 'فاتورة #$invoiceId';
    return 'غير محدد';
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
        debtId: json['debt_id'] as int,
        creationDate: json['creation_date']?.toString().split('T').first ?? '',
        paymentDate: json['payment_date']?.toString().split('T').first,
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
        username: json['username'] as String,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
        branchId: json['branch_id'] as int,
        branchName: json['branch_name'] as String,
        purchaseId: json['purchase_id'] as int?,
        examId: json['exam_id'] as int?,
        invoiceId: json['invoice_id'] as int?,
        description: json['description'] as String?,
      );
}
