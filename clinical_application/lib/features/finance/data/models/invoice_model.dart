class InvoiceModel {
  final int invoiceId;
  final String createdDate;
  final String username;
  final String name;
  final double price;
  final int branchId;
  final String branchName;
  final String? description;
  final String status;
  final int categoryId;
  final String categoryName;

  const InvoiceModel({
    required this.invoiceId,
    required this.createdDate,
    required this.username,
    required this.name,
    required this.price,
    required this.branchId,
    required this.branchName,
    this.description,
    required this.status,
    required this.categoryId,
    required this.categoryName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        invoiceId: json['invoice_id'] as int,
        createdDate: json['created_date']?.toString().split('T').first ?? '',
        username: json['username'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        branchId: json['branch_id'] as int,
        branchName: json['branch_name'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
      );
}
