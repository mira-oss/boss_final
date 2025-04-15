import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/ticket.dart';
import 'package:du_agbe_admin/ticketType.dart';
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Events
  Future<void> saveEvent(Event event) async {
    await _db.collection('events').doc(event.id).set(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    // Supprimer l'événement
    await _db.collection('events').doc(eventId).delete();
    
    // Supprimer tous les types de billets associés
    final ticketTypesSnapshot = await _db
        .collection('ticketTypes')
        .where('eventId', isEqualTo: eventId)
        .get();
    
    for (var doc in ticketTypesSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Eventuellement supprimer les billets déjà générés
    final ticketsSnapshot = await _db
        .collection('tickets')
        .where('eventId', isEqualTo: eventId)
        .get();
    
    for (var doc in ticketsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Event>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
    });
  }

  Future<Event> getEvent(String eventId) async {
    final doc = await _db.collection('events').doc(eventId).get();
    final event = Event.fromMap(doc.data()!);
    
    // Charger les types de billets associés
    final ticketTypesSnapshot = await _db
        .collection('ticketTypes')
        .where('eventId', isEqualTo: eventId)
        .get();
    
    event.ticketTypes = ticketTypesSnapshot.docs
        .map((doc) => TicketType.fromMap(doc.data()))
        .toList();
    
    return event;
  }

  // Ticket Types
  Future<void> saveTicketType(TicketType ticketType) async {
    await _db.collection('ticketTypes').doc(ticketType.id).set(ticketType.toMap());
  }

  Future<void> deleteTicketType(String ticketTypeId) async {
    await _db.collection('ticketTypes').doc(ticketTypeId).delete();
  }

  Stream<List<TicketType>> getTicketTypesForEvent(String eventId) {
    return _db
        .collection('ticketTypes')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TicketType.fromMap(doc.data()))
          .toList();
    });
  }

  // Tickets
  Future<void> saveTicket(Ticket ticket) async {
    await _db.collection('tickets').doc(ticket.id).set(ticket.toMap());
    
    // Mettre à jour le compteur de billets vendus
    final ticketTypeRef = _db.collection('ticketTypes').doc(ticket.ticketTypeId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketTypeRef);
      final ticketType = TicketType.fromMap(snapshot.data()!);
      transaction.update(ticketTypeRef, {'soldCount': ticketType.soldCount + 1});
    });
  }

  Future<List<Ticket>> getTicketsForEvent(String eventId) async {
    final snapshot = await _db
        .collection('tickets')
        .where('eventId', isEqualTo: eventId)
        .get();
    
    return snapshot.docs.map((doc) => Ticket.fromMap(doc.data())).toList();
  }

  Future<List<Ticket>> getTicketsByBuyer(String email) async {
    final snapshot = await _db
        .collection('tickets')
        .where('buyerEmail', isEqualTo: email)
        .get();
    
    return snapshot.docs.map((doc) => Ticket.fromMap(doc.data())).toList();
  }
}