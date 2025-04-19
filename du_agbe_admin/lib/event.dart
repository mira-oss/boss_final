import 'package:du_agbe_admin/ticketType.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  String title;
  DateTime date;
  String location;
  String description;
  int? maxCapacity; // Nullable
  String status;
  List<String> imageUrls;
  String organizerId;
  List<TicketType> ticketTypes;

  Event({
    String? id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    this.maxCapacity, // Nullable
    required this.status,
    this.imageUrls = const [],
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
      'imageUrls': imageUrls,
      'organizerId': organizerId,
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
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      organizerId: map['organizerId'],
    );
  }

  int? get remainingCapacity {
    if (maxCapacity == null) return null; // Retourne null si capacité illimitée
    
    final int sold = ticketTypes.fold(0, (sum, type) => sum + type.soldCount);
    return maxCapacity! - sold; // Utilisation de ! car nous avons vérifié null
  }
}