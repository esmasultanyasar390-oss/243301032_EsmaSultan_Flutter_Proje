class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        quantity: map['quantity'] ?? 0,
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final items = (map['items'] as List? ?? [])
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: items,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'beklemede',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt,
      };
}
