
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/ticket.dart';
import 'package:du_agbe_admin/ticketForm.dart';
import 'package:du_agbe_admin/ticketType.dart';
import 'package:flutter/material.dart';

class GenerateTicketsScreen extends StatefulWidget {
  final String eventId;
  final List<TicketType> ticketTypes;

  const GenerateTicketsScreen({super.key, 
    required this.eventId,
    required this.ticketTypes,
  });

  @override
  @override
_GenerateTicketsScreenState createState() => _GenerateTicketsScreenState();
}

class _GenerateTicketsScreenState extends State<GenerateTicketsScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  late TicketType _selectedTicketType;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedTicketType = widget.ticketTypes.first;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generateTickets() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTicketType.availableQuantity < _quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantité demandée non disponible'),
          ),
        );
        return;
      }

      final tickets = <Ticket>[];

      // Générer le nombre de tickets demandés
      for (int i = 0; i < _quantity; i++) {
        final ticket = Ticket(
          eventId: widget.eventId,
          ticketTypeId: _selectedTicketType.id,
          ticketTypeName: _selectedTicketType.name,
          price: _selectedTicketType.price,
          buyerEmail: _emailController.text,
          buyerName: _nameController.text,
        );

        tickets.add(ticket);

        // Enregistrer le ticket dans la base de données
        await _databaseService.saveTicket(ticket);
      }

      if (!mounted) return;

      // Afficher l'aperçu du premier ticket généré
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketPreviewScreen(
            ticket: tickets.first,
            eventId: widget.eventId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer des tickets'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de billet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TicketType>(
                      value: _selectedTicketType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: widget.ticketTypes
                          .where((type) => type.isAvailable)
                          .map((type) {
                        return DropdownMenuItem<TicketType>(
                          value: type,
                          child: Text(
                            '${type.name} - ${type.price.toStringAsFixed(2)} FCFA '
                            '(${type.availableQuantity} disponibles)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            _selectedTicketType = value;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un type de billet';
                        }
                        if (!value.isAvailable) {
                          return 'Ce type de billet n\'est plus disponible';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du participant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < _selectedTicketType.availableQuantity
                            ? () {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Total: ${(_selectedTicketType.price * _quantity).toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateTickets,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Générer les tickets'),
            ),
          ],
        ),
      ),
    );
  }
}