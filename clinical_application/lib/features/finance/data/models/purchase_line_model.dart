class PurchaseLineModel {
  final int lineId;
  final String name;
  final double price;
  final double quantity;
  final double total;

  const PurchaseLineModel({
    required this.lineId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory PurchaseLineModel.fromJson(Map<String, dynamic> json) => PurchaseLineModel(
        lineId: json['line_id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}
