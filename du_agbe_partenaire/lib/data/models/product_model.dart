// lib/data/models/product_model.dart
class Product {
  final String id;
  final String establishmentId;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String category;
  final List<String> photoUrls;
  final Map<String, dynamic>? promotion;
  final List<Map<String, dynamic>> options;

  Product({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.category,
    required this.photoUrls,
    this.promotion,
    required this.options,
  });

  // Create a Product from a Firestore document
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      establishmentId: map['establishmentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      available: map['available'] ?? true,
      category: map['category'] ?? 'Plat',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      promotion: map['promotion'],
      options: List<Map<String, dynamic>>.from(map['options'] ?? []),
    );
  }

  // Convert a Product to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'name': name,
      'description': description,
      'price': price,
      'available': available,
      'category': category,
      'photoUrls': photoUrls,
      'promotion': promotion,
      'options': options,
    };
  }

  // Create a copy of this Product with some fields replaced
  Product copyWith({
    String? id,
    String? establishmentId,
    String? name,
    String? description,
    double? price,
    bool? available,
    String? category,
    List<String>? photoUrls,
    Map<String, dynamic>? promotion,
    List<Map<String, dynamic>>? options,
  }) {
    return Product(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      available: available ?? this.available,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      promotion: promotion ?? this.promotion,
      options: options ?? this.options,
    );
  }
}
