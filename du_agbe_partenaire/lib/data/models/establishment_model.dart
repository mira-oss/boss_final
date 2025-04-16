// lib/data/models/establishment_model.dart
class Establishment {
  final String id;
  final String name;
  final String address;
  final String description;
  final Map<String, dynamic> openingHours;
  final String category;
  final String phone;
  final String email;
  final bool isOpen;
  final List<String> photoUrls;
  final double? rating;
  final int? reviewCount;
  final String? website;
  final String? city;
  final String? postalCode;
  final String? additionalInfo;

  Establishment({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.openingHours,
    required this.category,
    required this.phone,
    required this.email,
    required this.isOpen,
    required this.photoUrls,
    this.rating,
    this.reviewCount,
    this.website,
    this.city,
    this.postalCode,
    this.additionalInfo,
  });

  // Méthode de validation des données dans le constructeur
  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'] ?? 'Unknown',
      name: json['name'] ?? 'No name',
      address: json['address'] ?? 'No address',
      description: json['description'] ?? 'No description',
      openingHours:
          json['openingHours'] != null
              ? Map<String, dynamic>.from(json['openingHours'])
              : {},
      category: json['category'] ?? 'No category',
      phone: json['phone'] ?? 'No phone',
      email: json['email'] ?? 'No email',
      isOpen: json['isOpen'] ?? false,
      photoUrls:
          json['photoUrls'] != null ? List<String>.from(json['photoUrls']) : [],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      website: json['website'],
      city: json['city'],
      postalCode: json['postalCode'],
      additionalInfo: json['additionalInfo'],
    );
  }

  // Méthode pour convertir l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'openingHours': openingHours,
      'category': category,
      'phone': phone,
      'email': email,
      'isOpen': isOpen,
      'photoUrls': photoUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'website': website,
      'city': city,
      'postalCode': postalCode,
      'additionalInfo': additionalInfo,
    };
  }

  // Méthode pour créer une copie modifiée de l'objet
  Establishment copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    Map<String, dynamic>? openingHours,
    String? category,
    String? phone,
    String? email,
    bool? isOpen,
    List<String>? photoUrls,
    double? rating,
    int? reviewCount,
    String? website,
    String? city,
    String? postalCode,
    String? additionalInfo,
  }) {
    return Establishment(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      openingHours: openingHours ?? this.openingHours,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isOpen: isOpen ?? this.isOpen,
      photoUrls: photoUrls ?? this.photoUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      website: website ?? this.website,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  // Méthode utilitaire pour vérifier si l'établissement est ouvert à une heure donnée
  bool isOpenAt(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday; // 1 = Lundi, 7 = Dimanche
    final currentHour = dateTime.hour;

    // Vérification des heures d'ouverture pour le jour actuel
    if (openingHours.containsKey(dayOfWeek.toString())) {
      final dayHours = openingHours[dayOfWeek.toString()];
      final openHour = dayHours['open'] ?? 0;
      final closeHour = dayHours['close'] ?? 23;

      return currentHour >= openHour && currentHour < closeHour;
    }

    return false; // Si les heures d'ouverture ne sont pas définies pour ce jour
  }
}
