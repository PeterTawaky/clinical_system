class ExpenseCategory {
  final int categoryId;
  final String categoryName;

  const ExpenseCategory({required this.categoryId, required this.categoryName});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String,
      );
}
