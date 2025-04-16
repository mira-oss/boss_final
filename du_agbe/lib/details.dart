import 'dart:convert';

import 'package:du_agbe/reserverTicket.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['title']),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image principale
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event['imageUrl'].toString().startsWith('data:image')
                  ? Image.memory(
                      base64Decode(event['imageUrl'].split(',')[1]),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      event['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(height: 20),

            // Titre et bouton favori
            Row(
              children: [
                Expanded(
                  child: Text(
                    event['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    event['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    // Logique pour ajouter aux favoris
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // Date et lieu
            Row(
              children: [
                /*Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(event['date'].toDate()),
                  style: TextStyle(color: Colors.grey),
                ),*/
                SizedBox(width: 15),
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                  event['location'],
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Description complète
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              event['description'],
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Capacité
            Text(
              'Capacité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${event['maxCapacity']} places disponibles',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),

            // Bouton "Prendre un ticket"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navigation vers la page de réservation
                  _navigateToTicketBooking(context);
                },
                child: Text(
                  'Prendre un ticket',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTicketBooking(BuildContext context) {
    // Implémentez votre logique de navigation ici
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketBookingPage(event: event),
      ),
    );
  }
}