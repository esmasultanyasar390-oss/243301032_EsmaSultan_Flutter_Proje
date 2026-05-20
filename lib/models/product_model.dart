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

  static String normalizeName(String name) {
    var n = name.trim();
    const prefixes = ['Örnek ', 'örnek ', 'ORNEK ', 'Ornek '];
    for (final p in prefixes) {
      if (n.startsWith(p)) {
        n = n.substring(p.length).trim();
        break;
      }
    }
    return n;
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) => ProductModel(
        id: id,
        name: normalizeName(map['name']?.toString() ?? ''),
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

  ProductModel copyWith({
    String? name,
    String? brand,
    String? category,
    double? wholesalePrice,
    int? stock,
    String? imageUrl,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        stock: stock ?? this.stock,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
