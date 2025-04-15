
import 'package:du_agbe_admin/creatEvent.dart';
import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/generateTicket.dart';
import 'package:du_agbe_admin/ticketType.dart';
import 'package:du_agbe_admin/typebillets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Event? _event;
  List<TicketType> _ticketTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
     // _isLoading = true;
    });

    try {
      final event = await _databaseService.getEvent(widget.eventId);
      final ticketTypes = await _databaseService
          .getTicketTypesForEvent(widget.eventId)
          .first;

      if (mounted) {
        setState(() {
          _event = event;
          _ticketTypes = ticketTypes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet événement? '
          'Cette action est irréversible et supprimera tous les types de billets associés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails de l\'événement')),
        body: 
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Événement non trouvé')),
        body: const Center(
          child: Text('Cet événement n\'existe pas ou a été supprimé.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_event!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventScreen(event: _event),
                ),
              );
              _loadEvent();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvent,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // En-tête de l'événement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _event!.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(_event!.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                       Text(
                    DateFormat('dd/MM/yyyy').format(_event!.date), // Format simple
                    style: const TextStyle(fontSize: 16),
                  ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _event!.location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_event!.description),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Capacité',
                    '${_event!.maxCapacity}',
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Places restantes',
                    '${_event!.remainingCapacity}',
                    Icons.event_seat,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Types de billets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Types de billets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Gérer'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketTypesScreen(
                                  eventId: widget.eventId,
                                ),
                              ),
                            );
                            _loadEvent();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_ticketTypes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Aucun type de billet défini.\nAppuyez sur "Gérer" pour en ajouter.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _ticketTypes.length,
                        itemBuilder: (context, index) {
                          final ticket = _ticketTypes[index];
                          return ListTile(
                            title: Text(ticket.name),
                            subtitle: Text(
                              '${ticket.price.toStringAsFixed(2)} € - '
                              'Disponibles: ${ticket.availableQuantity}/${ticket.quantity}',
                            ),
                            trailing: ticket.isOnSale
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton pour générer des tickets
            if (_ticketTypes.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('Générer des tickets'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerateTicketsScreen(
                        eventId: widget.eventId,
                        ticketTypes: _ticketTypes,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}