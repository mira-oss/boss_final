
import 'package:du_agbe_admin/ticketType.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  String title;
  DateTime date;
  String location;
  String description;
  int maxCapacity;
  String status; // 'draft', 'published', 'completed', 'cancelled'
  String imageUrl;
  String organizerId;
  List<TicketType> ticketTypes;

  Event({
    String? id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.maxCapacity,
    required this.status,
    this.imageUrl = '',
    required this.organizerId,
    List<TicketType>? ticketTypes,
  }) : 
    id = id ?? const Uuid().v4(),
    ticketTypes = ticketTypes ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'location': location,
      'description': description,
      'maxCapacity': maxCapacity,
      'status': status,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      // Tickets sont sauvegardés séparément
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      location: map['location'],
      description: map['description'],
      maxCapacity: map['maxCapacity'],
      status: map['status'],
      imageUrl: map['imageUrl'],
      organizerId: map['organizerId'],
    );
  }

  int get remainingCapacity {
    int sold = ticketTypes.fold(0, (sum, type) => sum + type.soldCount);
    return maxCapacity - sold;
  }
}