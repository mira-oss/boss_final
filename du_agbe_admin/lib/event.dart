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
  List<String> imageUrls; // Changé de String imageUrl à List<String> imageUrls
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
    this.imageUrls = const [], // Initialisé comme liste vide par défaut
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
      'imageUrls': imageUrls, // Changé de imageUrl à imageUrls
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
      imageUrls: List<String>.from(map['imageUrls'] ?? []), // Conversion en liste
      organizerId: map['organizerId'],
      ticketTypes: null, // Vous devrez peut-être charger ces séparément
    );
  }

  int get remainingCapacity {
    int sold = ticketTypes.fold(0, (sum, type) => sum + type.soldCount);
    return maxCapacity - sold;
  }
}