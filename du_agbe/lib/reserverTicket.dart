import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TicketBookingPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const TicketBookingPage({Key? key, required this.event}) : super(key: key);

  @override
  _TicketBookingPageState createState() => _TicketBookingPageState();
}

class _TicketBookingPageState extends State<TicketBookingPage> {
  List<Map<String, dynamic>> _ticketTypes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedTicketIndex;

  @override
  void initState() {
    super.initState();
    _fetchTicketTypes();
  }

  Future<void> _fetchTicketTypes() async {
  try {
    if (widget.event['id'] == null) {
      throw Exception('ID d\'événement manquant');
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('ticketTypes')
        .where('eventId', isEqualTo: widget.event['id'])
        .get();

    print('Requête Firestore exécutée'); // Debug

    final tickets = querySnapshot.docs.map((doc) {
      final data = doc.data();
      
      // Conversion sécurisée des dates
      DateTime? safeConvertDate(dynamic date) {
        if (date == null) return null;
        if (date is Timestamp) return date.toDate();
        if (date is DateTime) return date;
        return null;
      }

      return {
        'id': doc.id,
        'name': data['name'] ?? 'Nom inconnu',
        'price': (data['price'] ?? 0).toDouble(),
        'quantity': data['quantity'] ?? 0,
        'soldCount': data['soldCount'] ?? 0,
        'description': data['description'] ?? '',
        'salesStartDate': safeConvertDate(data['salesStartDate']),
        'salesEndDate': safeConvertDate(data['salesEndDate']),
        'eventId': data['eventId'],
      };
    }).where((ticket) {
      // Filtre côté client pour les tickets disponibles
      final available = (ticket['quantity'] - ticket['soldCount']) > 0;
      final now = DateTime.now();
      final startOk = ticket['salesStartDate'] == null || 
                     now.isAfter(ticket['salesStartDate']);
      final endOk = ticket['salesEndDate'] == null || 
                    now.isBefore(ticket['salesEndDate']);
      return available && startOk && endOk;
    }).toList();

    setState(() {
      _ticketTypes = tickets;
      _isLoading = false;
    });
  } catch (e, stack) {
    print('Erreur: $e');
    print('Stack trace: $stack');
    setState(() {
      _errorMessage = 'Impossible de charger les billets. Réessayez.';
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billetterie - ${widget.event['title']}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_ticketTypes.isEmpty) {
      return Center(child: Text('Aucun billet disponible pour cet événement'));
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _ticketTypes.length,
              itemBuilder: (context, index) {
                final ticket = _ticketTypes[index];
                final isSelected = _selectedTicketIndex == index;
                final isAvailable = _isTicketAvailable(ticket);

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  color: isSelected ? Colors.blue[50] : null,
                  child: InkWell(
                    onTap: isAvailable
                        ? () => setState(() => _selectedTicketIndex = index)
                        : null,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ticket['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable ? Colors.black : Colors.grey,
                                ),
                              ),
                              Text(
                                '${ticket['price']} FCFA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            ticket['description'],
                            style: TextStyle(
                              color: isAvailable ? Colors.black54 : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (ticket['salesStartDate'] != null || ticket['salesEndDate'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                if (ticket['salesStartDate'] != null)
                                  Text(
                                    'Vente à partir du: ${DateFormat('dd/MM/yyyy').format(ticket['salesStartDate'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (ticket['salesEndDate'] != null)
                                  Text(
                                    'Vente jusqu\'au: ${DateFormat('dd/MM/yyyy').format(ticket['salesEndDate'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          SizedBox(height: 8),
                          Text(
                            '${ticket['quantity'] - (ticket['soldCount'] ?? 0)} billets disponibles',
                            style: TextStyle(
                              color: isAvailable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isAvailable)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Non disponible',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_ticketTypes.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedTicketIndex != null ? Colors.orange : Colors.grey,
                  ),
                  onPressed: _selectedTicketIndex != null
                      ? () => _confirmPurchase(context)
                      : null,
                  child: Text(
                    'Réserver maintenant',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isTicketAvailable(Map<String, dynamic> ticket) {
    final now = DateTime.now();
    final startDate = ticket['salesStartDate'];
    final endDate = ticket['salesEndDate'];
    final available = ticket['quantity'] - (ticket['soldCount'] ?? 0) > 0;

    if (startDate != null && now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate)) return false;
    return available;
  }

  void _confirmPurchase(BuildContext context) {
    if (_selectedTicketIndex == null) return;

    final selectedTicket = _ticketTypes[_selectedTicketIndex!];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous allez réserver:'),
            SizedBox(height: 8),
            Text(
              selectedTicket['name'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Prix: ${selectedTicket['price']} €'),
            SizedBox(height: 16),
            Text('Pour l\'événement:'),
            SizedBox(height: 8),
            Text(
              widget.event['title'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPurchase(selectedTicket);
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(Map<String, dynamic> ticket) async {
    try {
      // Mettre à jour le nombre de billets vendus
      await FirebaseFirestore.instance
          .collection('ticketTypes')
          .doc(ticket['id'])
          .update({
        'soldCount': FieldValue.increment(1),
      });

      // Créer la réservation (à adapter selon votre structure de données)
      await FirebaseFirestore.instance.collection('reservations').add({
        'eventId': widget.event['id'],
        'ticketTypeId': ticket['id'],
        'userId': 'current_user_id', // À remplacer par l'ID de l'utilisateur connecté
        'purchaseDate': DateTime.now(),
        'status': 'confirmed',
        'price': ticket['price'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation confirmée avec succès!')),
      );

      Navigator.pop(context); // Retour à la page précédente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la réservation: $e')),
      );
    }
  }
}