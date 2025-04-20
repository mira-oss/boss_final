import 'package:du_agbe_admin/event.dart';
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/typebillets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class CreateEventScreen extends StatefulWidget {
  final Event? event;

  const CreateEventScreen({super.key, this.event});

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
  late TimeOfDay _selectedTime;
  String _status = 'draft';
  List<String> _base64Images = [];
  bool _isUploading = false;
  bool _hasCapacityLimit = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _capacityController = TextEditingController(
      text: widget.event?.maxCapacity?.toString() ?? '100',
    );
    _selectedDate = widget.event?.date ?? DateTime.now().add(Duration(days: 7));
    _selectedTime = TimeOfDay.fromDateTime(widget.event?.date ?? DateTime.now().add(Duration(hours: 1)));
    _status = widget.event?.status ?? 'draft';
    _base64Images = widget.event?.imageUrls ?? [];
    _hasCapacityLimit = widget.event?.maxCapacity != null;
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
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
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
      // Gestion de la capacité
      int? capacity;
      if (_hasCapacityLimit) {
        capacity = int.tryParse(_capacityController.text);
        if (capacity == null || capacity <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veuillez entrer une capacité valide')),
          );
          return;
        }
      }

      final event = Event(
        id: widget.event?.id,
        title: _titleController.text,
        date: _selectedDate,
        location: _locationController.text,
        description: _descriptionController.text,
        maxCapacity: capacity, // Peut être null si illimité
        status: _status,
        imageUrls: _base64Images,
        organizerId: 'current_user_id',
        ticketTypes: widget.event?.ticketTypes ?? [],
      );

      try {
        await _databaseService.saveEvent(event);

        if (!mounted) return;
        if (widget.event == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TicketTypesScreen(eventId: event.id),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
              SizedBox(height: 8),
              Text('Ajouter une photo', style: TextStyle(color: Colors.grey[600])),
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
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.add, size: 40, color: Colors.grey[600]),
                    ),
                  ),
                );
              }
              
              return Stack(
                children: [
                  Container(
                    width: 150,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_base64Images[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 15,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _base64Images.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
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
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  controller: TextEditingController(
                                    text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectTime,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Heure',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  controller: TextEditingController(
                                    text: _selectedTime.format(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Lieu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
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
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Capacité limitée'),
                          Switch(
                            value: _hasCapacityLimit,
                            onChanged: (value) {
                              setState(() {
                                _hasCapacityLimit = value;
                              });
                            },
                          ),
                          Text('Illimitée'),
                        ],
                      ),
                      if (_hasCapacityLimit) ...[
                        SizedBox(height: 16),
                        TextFormField(
  controller: _capacityController,
  decoration: InputDecoration(
    labelText: 'Capacité maximale',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.people),
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (_hasCapacityLimit) {
      if (value == null || value.isEmpty) {
        return 'Veuillez entrer une capacité';
      }
      final capacity = int.tryParse(value);
      if (capacity == null || capacity <= 0) {
        return 'Veuillez entrer un nombre valide > 0';
      }
    }
    return null;
  },
  enabled: _hasCapacityLimit, // Désactive le champ si capacité illimitée
),
                      ],
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.stairs),
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
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    backgroundColor: Colors.blue, // Couleur plus profonde
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    shadowColor: Colors.blue.shade200,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(widget.event == null ? Icons.create : Icons.save, size: 20),
      SizedBox(width: 8),
      Text(
        widget.event == null ? 'Créer et continuer' : 'Enregistrer les modifications',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (widget.event == null) ...[
        SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 20),
      ],
    ],
  ),
)
            ],
          ),
        ),
      ),
    );
  }
}