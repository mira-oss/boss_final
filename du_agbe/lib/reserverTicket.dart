import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isProcessing = false;

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

      final tickets = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
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
                    backgroundColor: _selectedTicketIndex != null
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  onPressed: _selectedTicketIndex != null && !_isProcessing
                      ? () => _confirmPurchase(context)
                      : null,
                  child: _isProcessing
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
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
        title: Text('Informations personnelles'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Veuillez entrer vos informations pour la réservation'),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('Détails de la réservation:'),
                Text(
                  selectedTicket['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Prix: ${selectedTicket['price']} FCFA'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _processPurchase(selectedTicket);
              }
            },
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(Map<String, dynamic> ticket) async {
    setState(() => _isProcessing = true);
    
    try {
      final ticketId = const Uuid().v4();
      final qrCode = const Uuid().v4();
      
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).set({
        'eventId': widget.event['id'],
        'eventTitle': widget.event['title'],
        'ticketTypeId': ticket['id'],
        'ticketType': ticket['name'],
        'price': ticket['price'],
        'buyerName': _nameController.text,
        'buyerEmail': _emailController.text,
        'qrCode': qrCode,
        'status': 'valid',
        'isUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await FirebaseFirestore.instance.collection('ticketTypes').doc(ticket['id']).update({
        'soldCount': FieldValue.increment(1),
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketConfirmationPage(
            ticketId: ticketId,
            eventTitle: widget.event['title'],
            ticketType: ticket['name'],
            price: ticket['price'],
            buyerName: _nameController.text,
            qrCode: qrCode,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

class TicketConfirmationPage extends StatefulWidget {
  final String ticketId;
  final String eventTitle;
  final String ticketType;
  final double price;
  final String buyerName;
  final String qrCode;

  const TicketConfirmationPage({
    Key? key,
    required this.ticketId,
    required this.eventTitle,
    required this.ticketType,
    required this.price,
    required this.buyerName,
    required this.qrCode,
  }) : super(key: key);

  @override
  _TicketConfirmationPageState createState() => _TicketConfirmationPageState();
}

class _TicketConfirmationPageState extends State<TicketConfirmationPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isGeneratingPdf = false;

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 2.0,
      );
      
      if (imageBytes == null) throw Exception('Échec de la capture du ticket');

      final pdf = pw.Document();
      final image = pw.MemoryImage(imageBytes);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Billet pour ${widget.eventTitle}',
                      style: pw.TextStyle(fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Image(image, width: 300, height: 300)),
                pw.SizedBox(height: 30),
                pw.Text('Détails du billet:',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Text('Événement: ${widget.eventTitle}'),
                pw.Text('Type: ${widget.ticketType}'),
                pw.Text('Prix: ${widget.price} FCFA'),
                pw.Text('Nom: ${widget.buyerName}'),
                pw.SizedBox(height: 15),
                pw.Text('Code QR: ${widget.qrCode}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text('Présentez ce billet à l\'entrée',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/ticket_${widget.ticketId}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Voici mon billet pour ${widget.eventTitle}',
        );
      } else {
        throw Exception('Le fichier PDF n\'a pas été créé');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation de réservation'),
      ),
      body: SingleChildScrollView(
        child: Screenshot(
          controller: _screenshotController,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Réservation confirmée!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Votre billet a été généré avec succès.',
                          textAlign: TextAlign.center,
                        ),
                        Divider(height: 32),
                        Text(
                          'Détails du billet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow('Événement', widget.eventTitle),
                        _buildDetailRow('Type de billet', widget.ticketType),
                        _buildDetailRow('Prix', '${widget.price} FCFA'),
                        _buildDetailRow('Nom', widget.buyerName),
                        SizedBox(height: 24),
                        Text(
                          'Votre code QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(
                            data: widget.qrCode,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Code: ${widget.qrCode}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _isGeneratingPdf
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _generateAndSharePdf,
                        child: Text('Télécharger le PDF'),
                      ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TicketScannerPage extends StatefulWidget {
  @override
  _TicketScannerPageState createState() => _TicketScannerPageState();
}

class _TicketScannerPageState extends State<TicketScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String _scanResult = '';
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner de billets'),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.camera_front),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_isProcessing) {
                      final String code = barcodes.first.rawValue ?? '';
                      _checkTicket(code);
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _isProcessing
                ? Center(child: CircularProgressIndicator())
                : _scanResult.isNotEmpty
                    ? _buildScanResult()
                    : Center(
                        child: Text(
                          'Scannez un code QR de billet',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResult() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.error,
            color: _isSuccess ? Colors.green : Colors.red,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            _scanResult,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _scanResult = '';
                _isSuccess = false;
              });
            },
            child: Text('Scanner un autre billet'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkTicket(String qrCode) async {
    setState(() {
      _isProcessing = true;
      _scanResult = '';
      _isSuccess = false;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _scanResult = 'Ticket non trouvé';
          _isSuccess = false;
        });
        return;
      }

      final ticketDoc = querySnapshot.docs.first;
      final ticketData = ticketDoc.data();
      final eventTitle = ticketData['eventTitle'] ?? 'Événement inconnu';
      final buyerName = ticketData['buyerName'] ?? 'Utilisateur inconnu';
      final isUsed = ticketData['isUsed'] ?? false;
      final isValid = ticketData['status'] == 'valid';

      if (!isValid) {
        setState(() {
          _scanResult = 'Ticket invalide ou déjà utilisé';
          _isSuccess = false;
        });
        return;
      }

      if (isUsed) {
        setState(() {
          _scanResult = 'Ticket déjà utilisé pour $eventTitle';
          _isSuccess = false;
        });
        return;
      }

      await ticketDoc.reference.update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _scanResult = 'Ticket valide pour $eventTitle\n($buyerName)';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Erreur de vérification: ${e.toString()}';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}