// lib/data/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final DateTime pickupTime;
  final String customerName;
  final String customerPhone;
  final String customerNotes;
  final List<OrderItem> items;
  final double subtotal;
  final double serviceFee;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String establishmentId;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.pickupTime,
    required this.customerName,
    required this.customerPhone,
    required this.customerNotes,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.discount,
    required this.total,
    this.paymentMethod,
    required this.establishmentId,
    this.updatedAt,
  });

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    // Parse items
    List<OrderItem> orderItems = [];
    if (map['items'] != null) {
      orderItems = List<OrderItem>.from(
        map['items'].map((item) => OrderItem.fromMap(item)),
      );
    }

    // Parse dates
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    DateTime pickupTime;
    if (map['pickupTime'] is Timestamp) {
      pickupTime = (map['pickupTime'] as Timestamp).toDate();
    } else {
      pickupTime = DateTime.now().add(Duration(minutes: 30)); // Fallback
    }

    DateTime? updatedAt;
    if (map['updatedAt'] is Timestamp) {
      updatedAt = (map['updatedAt'] as Timestamp).toDate();
    }

    return Order(
      id: id,
      orderNumber: map['orderNumber'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: createdAt,
      pickupTime: pickupTime,
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerNotes: map['customerNotes'] ?? '',
      items: orderItems,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      serviceFee: (map['serviceFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'],
      establishmentId: map['establishmentId'] ?? '',
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'status': status,
      'createdAt': createdAt,
      'pickupTime': pickupTime,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerNotes': customerNotes,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'establishmentId': establishmentId,
      'updatedAt': updatedAt,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final List<String> options;
  final String notes;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.options,
    required this.notes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      options: List<String>.from(map['options'] ?? []),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'options': options,
      'notes': notes,
    };
  }
}

enum OrderStatus { pending, accepted, preparing, ready, completed, cancelled }

extension OrderStatusExtension on Order {
  Order copyWith({
    String? id,
    String? orderNumber,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? pickupTime,
    String? customerName,
    String? customerPhone,
    String? customerNotes,
    List<OrderItem>? items,
    double? subtotal,
    double? serviceFee,
    double? discount,
    double? total,
    String? paymentMethod,
    String? establishmentId,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status != null ? status.name : this.status,
      createdAt: createdAt ?? this.createdAt,
      pickupTime: pickupTime ?? this.pickupTime,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerNotes: customerNotes ?? this.customerNotes,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      establishmentId: establishmentId ?? this.establishmentId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
