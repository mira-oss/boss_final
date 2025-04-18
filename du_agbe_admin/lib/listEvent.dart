
import 'package:du_agbe_admin/creatEvent.dart';
import 'package:du_agbe_admin/detailsEvent.dart';
import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/firestorService.dart';
import 'package:flutter/material.dart';

class EventListScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: _databaseService.getEvents(),
        builder: (context, snapshot) {
         /* if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }*/

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun événement trouvé. Créez votre premier événement!'),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(eventId: event.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(event.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${event.date.day}/${event.date.month}/${event.date.year}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Capacité: ${event.maxCapacity} personnes',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'Brouillon';
        break;
      case 'published':
        color = Colors.green;
        label = 'Publié';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Terminé';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Annulé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
    );
  }
}