import 'package:uuid/uuid.dart';

class TicketType {
  final String id;
  final String eventId;
  String name;
  double price;
  int quantity;
  String description;
  DateTime? salesStartDate;
  DateTime? salesEndDate;
  String? discountCode;
  int soldCount;

  TicketType({
    String? id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    this.salesStartDate,
    this.salesEndDate,
    this.discountCode,
    this.soldCount = 0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'salesStartDate': salesStartDate?.millisecondsSinceEpoch,
      'salesEndDate': salesEndDate?.millisecondsSinceEpoch,
      'discountCode': discountCode,
      'soldCount': soldCount,
    };
  }

  factory TicketType.fromMap(Map<String, dynamic> map) {
    return TicketType(
      id: map['id'],
      eventId: map['eventId'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      description: map['description'],
      salesStartDate: map['salesStartDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['salesStartDate'])
          : null,
      salesEndDate: map['salesEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['salesEndDate'])
          : null,
      discountCode: map['discountCode'],
      soldCount: map['soldCount'] ?? 0,
    );
  }

  int get availableQuantity => quantity - soldCount;
  bool get isAvailable => availableQuantity > 0;
  bool get isOnSale {
    final now = DateTime.now();
    return (salesStartDate == null || now.isAfter(salesStartDate!)) &&
        (salesEndDate == null || now.isBefore(salesEndDate!));
  }
}