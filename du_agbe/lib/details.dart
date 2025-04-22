import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe/reserverTicket.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> event;
  
  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _hasTickets = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTicketAvailability();
  }

  Future<void> _checkTicketAvailability() async {
    try {
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: widget.event['id'])
          .limit(1)
          .get();

      setState(() {
        _hasTickets = ticketsSnapshot.docs.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur de vérification des tickets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseEventDate() {
    try {
      if (widget.event['date'] == null) return null;
      
      if (widget.event['date'] is DateTime) {
        return widget.event['date'] as DateTime;
      } else if (widget.event['date'] is num) {
        return DateTime.fromMillisecondsSinceEpoch(widget.event['date'].toInt());
      } else if (widget.event['date'] is String) {
        return DateTime.tryParse(widget.event['date']) ?? 
               DateTime.fromMillisecondsSinceEpoch(int.tryParse(widget.event['date']) ?? 0);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur de parsing de date: $e');
      return null;
    }
  }

  void _navigateToTicketBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketBookingPage(event: widget.event),
      ),
    );
  }

  Widget _buildAccessInfo() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasTickets) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _navigateToTicketBooking(context),
          child: const Text(
            'Prendre un ticket',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.celebration, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              'Entrée libre et gratuite !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Aucun ticket nécessaire pour cet événement',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = _parseEventDate();
    final dateString = eventDate != null 
        ? DateFormat('dd/MM/yyyy à HH:mm').format(eventDate)
        : 'Date non disponible';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['title'] ?? 'Détails Événement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image de l'événement
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.event['imageUrl'].toString().startsWith('data:image')
                        ? Image.memory(
                            base64Decode(widget.event['imageUrl'].split(',')[1]),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.event['imageUrl'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Titre et favori
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.event['title'] ?? 'Titre non disponible',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          (widget.event['isFavorite'] ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          // TODO: Gérer les favoris
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date et lieu
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(dateString, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 15),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        widget.event['location'] ?? 'Lieu non spécifié',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event['description'] ?? 'Aucune description disponible',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Capacité
                  const Text(
                    'Capacité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event['maxCapacity'] != null
                        ? '${widget.event['maxCapacity']} places disponibles'
                        : 'Information non disponible',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Section Accès (Ticket ou Entrée libre)
                  _buildAccessInfo(),
                ],
              ),
            ),
    );
  }
}