
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/formTypeTicket.dart';
import 'package:du_agbe_admin/ticketType.dart';
import 'package:flutter/material.dart';


class TicketTypesScreen extends StatefulWidget {
  final String eventId;

  const TicketTypesScreen({super.key, required this.eventId});

  @override
  _TicketTypesScreenState createState() => _TicketTypesScreenState();
}

class _TicketTypesScreenState extends State<TicketTypesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Types de billets'),
      ),
      body: StreamBuilder<List<TicketType>>(
        stream: _databaseService.getTicketTypesForEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ticketTypes = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gérez les différents types de billets pour votre événement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ticketTypes.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun type de billet défini.\nAppuyez sur + pour en ajouter.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: ticketTypes.length,
                        itemBuilder: (context, index) {
                          final ticketType = ticketTypes[index];
                          return TicketTypeCard(
                            ticketType: ticketType,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketTypeFormScreen(
                                    eventId: widget.eventId,
                                    ticketType: ticketType,
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: const Text(
                                    'Êtes-vous sûr de vouloir supprimer ce type de billet? '
                                    'Cette action est irréversible.',
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

                              if (confirm == true) {
                                await _databaseService.deleteTicketType(ticketType.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketTypeFormScreen(
                eventId: widget.eventId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Terminer'),
        ),
      ),
    );
  }
}

class TicketTypeCard extends StatelessWidget {
  final TicketType ticketType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TicketTypeCard({super.key, 
    required this.ticketType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticketType.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${ticketType.price.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(ticketType.description),
            const SizedBox(height: 8),
            Text(
              'Disponibilité: ${ticketType.availableQuantity}/${ticketType.quantity}',
              style: TextStyle(
                color: ticketType.availableQuantity > 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            if (ticketType.salesStartDate != null && ticketType.salesEndDate != null)
              Text(
                'En vente du ${_formatDate(ticketType.salesStartDate!)} '
                'au ${_formatDate(ticketType.salesEndDate!)}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}