class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final String category;
  final bool isDigital;
  final int inStock;
  final int soldCount;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.images,
    required this.rating,
    required this.category,
    required this.isDigital,
    required this.inStock,
    required this.soldCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [json['imageUrl'] as String],
      rating: (json['rating'] as num).toDouble(),
      category: json['category'] as String,
      isDigital: json['isDigital'] as bool? ?? false,
      inStock: json['inStock'] as int? ?? 0,
      soldCount: json['soldCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'category': category,
      'isDigital': isDigital,
      'inStock': inStock,
      'soldCount': soldCount,
    };
  }
}
