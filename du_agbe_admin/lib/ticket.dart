import 'package:uuid/uuid.dart';

class Ticket {
  final String id;
  final String eventId;
  final String ticketTypeId;
  final String ticketTypeName;
  final double price;
  final DateTime purchaseDate;
  final String buyerEmail;
  final String buyerName;
  final String ticketCode;
  bool isUsed;

  Ticket({
    String? id,
    required this.eventId,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.price,
    required this.buyerEmail,
    required this.buyerName,
    DateTime? purchaseDate,
    String? ticketCode,
    this.isUsed = false,
  }) :
    id = id ?? const Uuid().v4(),
    purchaseDate = purchaseDate ?? DateTime.now(),
    ticketCode = ticketCode ?? const Uuid().v4().substring(0, 8).toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'ticketTypeId': ticketTypeId,
      'ticketTypeName': ticketTypeName,
      'price': price,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'buyerEmail': buyerEmail,
      'buyerName': buyerName,
      'ticketCode': ticketCode,
      'isUsed': isUsed,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      eventId: map['eventId'],
      ticketTypeId: map['ticketTypeId'],
      ticketTypeName: map['ticketTypeName'],
      price: map['price'],
      buyerEmail: map['buyerEmail'],
      buyerName: map['buyerName'],
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(map['purchaseDate']),
      ticketCode: map['ticketCode'],
      isUsed: map['isUsed'] ?? false,
    );
  }
}