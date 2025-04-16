// lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Ajoute cette ligne

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role; // 'partner', 'admin', etc.
  final List<String>? establishmentIds;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.establishmentIds,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      establishmentIds:
          json['establishmentIds'] != null
              ? List<String>.from(json['establishmentIds'])
              : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'establishmentIds': establishmentIds,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }
}
