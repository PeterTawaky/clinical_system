class PurchaseModel {
  final int purchaseId;
  final String createdDate;
  final String username;
  final String? description;
  final int categoryId;
  final String categoryName;
  final String status;
  final int branchId;
  final String branchName;
  final double totalAmount;

  const PurchaseModel({
    required this.purchaseId,
    required this.createdDate,
    required this.username,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.branchId,
    required this.branchName,
    required this.totalAmount,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) => PurchaseModel(
        purchaseId: json['purchase_id'] as int,
        createdDate: json['created_date']?.toString().split('T').first ?? '',
        username: json['username'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
        status: json['status'] as String,
        branchId: json['branch_id'] as int,
        branchName: json['branch_name'] as String,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      );
}
