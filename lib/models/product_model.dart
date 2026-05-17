class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double wholesalePrice;
  final int stock;
  final String imageUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.wholesalePrice,
    required this.stock,
    this.imageUrl = '',
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) => ProductModel(
        id: id,
        name: map['name'] ?? '',
        brand: map['brand'] ?? '',
        category: map['category'] ?? '',
        wholesalePrice: (map['wholesalePrice'] ?? 0).toDouble(),
        stock: map['stock'] ?? 0,
        imageUrl: map['imageUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'wholesalePrice': wholesalePrice,
        'stock': stock,
        'imageUrl': imageUrl,
      };
}
