import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/typebillets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class CreateEventScreen extends StatefulWidget {
  final Event? event;

  const CreateEventScreen({Key? key, this.event}) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  late DateTime _selectedDate;
  String _status = 'draft';
  List<String> _base64Images = [];
  bool _isUploading = false;

  // Couleur bleue claire intelligente
  final Color lightBlue = Color(0xFFE1F5FE);
  final Color primaryBlue = Color(0xFF4FC3F7);
  final Color accentBlue = Color(0xFFB3E5FC);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _capacityController = TextEditingController(
      text: widget.event?.maxCapacity.toString() ?? '100',
    );
    _selectedDate = widget.event?.date ?? DateTime.now().add(Duration(days: 7));
    _status = widget.event?.status ?? 'draft';
    _base64Images = widget.event?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isUploading = true);
        
        final bytes = await File(image.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        
        setState(() {
          _base64Images.add(base64Image);
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du téléchargement de l'image")),
      );
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      
       final event = Event(
      id: widget.event?.id,
      title: _titleController.text,
      date: _selectedDate,
      location: _locationController.text,
      description: _descriptionController.text,
      maxCapacity: int.parse(_capacityController.text),
      status: _status,
      imageUrls: _base64Images, // Maintenant compatible avec la classe Event
      organizerId: 'current_user_id',
      ticketTypes: widget.event?.ticketTypes ?? [],
    );

      await _databaseService.saveEvent(event);

      if (widget.event == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketTypesScreen(eventId: event.id),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  Widget _buildImagePreview() {
    if (_isUploading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_base64Images.isEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: accentBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: primaryBlue),
              SizedBox(height: 8),
              Text('Ajouter une photo', style: TextStyle(color: primaryBlue)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _base64Images.length + 1,
            itemBuilder: (context, index) {
              if (index == _base64Images.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: accentBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.add, size: 40, color: primaryBlue),
                    ),
                  ),
                );
              }
              
              return Container(
                width: 150,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(_base64Images[index])),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Text('${_base64Images.length} photo(s) ajoutée(s)'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Créer un événement' : 'Modifier l\'événement'),
        backgroundColor: primaryBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: lightBlue,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Photos de l\'événement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildImagePreview(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titre de l\'événement',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          prefixIcon: Icon(Icons.title, color: primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date de l\'événement',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryBlue),
                              ),
                              prefixIcon: Icon(Icons.calendar_today, color: primaryBlue),
                            ),
                            controller: TextEditingController(
                              text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Lieu',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          prefixIcon: Icon(Icons.location_on, color: primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un lieu';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          prefixIcon: Icon(Icons.description, color: primaryBlue),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        decoration: InputDecoration(
                          labelText: 'Capacité maximale',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          prefixIcon: Icon(Icons.people, color: primaryBlue),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une capacité';
                          }
                          if (int.tryParse(value) == null || int.parse(value) <= 0) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          prefixIcon: Icon(Icons.stairs, color: primaryBlue),
                        ),
                        items: [
                          DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                          DropdownMenuItem(value: 'published', child: Text('Publié')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                          DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.event == null ? 'Créer et continuer' : 'Enregistrer les modifications',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}