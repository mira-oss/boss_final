import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
class TicketPreviewScreen extends StatefulWidget {
  final Ticket ticket;
  final String eventId;

  const TicketPreviewScreen({super.key, 
    required this.ticket,
    required this.eventId,
  });

  @override
  _TicketPreviewScreenState createState() => _TicketPreviewScreenState();
}

class _TicketPreviewScreenState extends State<TicketPreviewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _databaseService.getEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aperçu du ticket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(
          child: Text('Impossible de charger les détails de l\'événement'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu du ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implémenter le partage du ticket (PDF, email, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de partage à implémenter'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTicket(context),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier le code'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.ticket.ticketCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copié dans le presse-papier'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicket(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.7),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _event!.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.ticket.ticketTypeName ?? 'Standard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _event!.location,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Ligne de séparation avec effet déchiré
            SizedBox(
              height: 30,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        30,
                        (index) => Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Informations sur la date et l'heure
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${dateFormat.format(_event!.date)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Informations sur le billet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Nom', widget.ticket.buyerName),
                        _buildInfoRow('Email', widget.ticket.buyerEmail),
                        
                        _buildInfoRow('Prix', '${widget.ticket.price} €FCFA'),
                        _buildInfoRow('Acheté le', dateFormat.format(widget.ticket.purchaseDate)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Code QR
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.ticket.ticketCode,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.ticket.ticketCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Pied de page
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _event!.description ?? 'Présentez ce billet à l\'entrée de l\'événement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}