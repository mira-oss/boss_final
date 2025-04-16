// lib/data/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String establishmentId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? response;
  final DateTime? respondedAt;

  // Ajouter le constructeur avec le champ response en option
  Review({
    required this.id,
    required this.establishmentId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.response,
    this.respondedAt,
  });

  // Ajout de la méthode hasResponse pour vérifier si une réponse est présente
  bool get hasResponse => response != null && response!.isNotEmpty;

  // Factory pour convertir le JSON en un objet Review
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      establishmentId: json['establishmentId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      response: json['response'],
      respondedAt:
          json['respondedAt'] != null
              ? (json['respondedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Nouvelle méthode fromMap pour la cohérence avec le repository
  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      establishmentId: map['establishmentId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      response: map['response'],
      respondedAt:
          map['respondedAt'] != null
              ? (map['respondedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Méthode pour convertir un objet Review en un Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'response': response,
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // Alias pour toJson pour la cohérence
  Map<String, dynamic> toMap() => toJson();

  // Méthode copyWith pour créer une copie de Review avec des modifications
  Review copyWith({
    String? id,
    String? establishmentId,
    String? customerId,
    String? customerName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? response,
    DateTime? respondedAt,
  }) {
    return Review(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
