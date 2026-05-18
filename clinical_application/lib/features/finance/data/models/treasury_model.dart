class TreasuryModel {
  final int treasuryId;
  final String creationDate;
  final double amount;
  final String transactionType;
  final String username;
  final int categoryId;
  final String categoryName;
  final int branchId;
  final String branchName;
  final String? description;

  const TreasuryModel({
    required this.treasuryId,
    required this.creationDate,
    required this.amount,
    required this.transactionType,
    required this.username,
    required this.categoryId,
    required this.categoryName,
    required this.branchId,
    required this.branchName,
    this.description,
  });

  factory TreasuryModel.fromJson(Map<String, dynamic> json) => TreasuryModel(
        treasuryId: json['treasury_id'] as int,
        creationDate: json['creation_date']?.toString().split('T').first ?? '',
        amount: (json['amount'] as num).toDouble(),
        transactionType: json['transaction_type'] as String,
        username: json['username'] as String,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
        branchId: json['branch_id'] as int,
        branchName: json['branch_name'] as String,
        description: json['description'] as String?,
      );
}
