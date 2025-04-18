
import 'package:du_agbe_admin/firestorService.dart';
import 'package:du_agbe_admin/ticketType.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class TicketTypeFormScreen extends StatefulWidget {
  final String eventId;
  final TicketType? ticketType;

  const TicketTypeFormScreen({super.key, 
    required this.eventId,
    this.ticketType,
  });

 @override
_TicketTypeFormScreenState createState() => _TicketTypeFormScreenState();
}

class _TicketTypeFormScreenState extends State<TicketTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountCodeController;

  DateTime? _salesStartDate;
  DateTime? _salesEndDate;
  bool _hasDateRange = false;

  @override
void initState() {
  super.initState();
  _nameController = TextEditingController(text: widget.ticketType?.name ?? '');
  _priceController = TextEditingController(
    text: widget.ticketType?.price.toString() ?? '0.00',
  );
  _quantityController = TextEditingController(
    text: widget.ticketType?.quantity.toString() ?? '100',
  );
  _descriptionController = TextEditingController(
    text: widget.ticketType?.description ?? '',
  );
  _discountCodeController = TextEditingController(
    text: widget.ticketType?.discountCode ?? '',
  );
  _salesStartDate = widget.ticketType?.salesStartDate;
  _salesEndDate = widget.ticketType?.salesEndDate;
  _hasDateRange = _salesStartDate != null && _salesEndDate != null;
}

  @override
void dispose() {
  _nameController.dispose();
  _priceController.dispose();
  _quantityController.dispose();
  _descriptionController.dispose();
  _discountCodeController.dispose();
  super.dispose();
}
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.ticketType == null
              ? 'Ajouter un type de billet'
              : 'Modifier le type de billet'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du type de billet',
                  hintText: 'Ex: VIP, Standard, Étudiant...',
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
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix (CFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité disponible',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Ex: Accès à toutes les zones, place assise...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Période de vente spécifique'),
                subtitle:
                    const Text('Définir des dates de début et de fin de vente'),
                value: _hasDateRange,
                onChanged: (value) {
                  setState(() {
                    _hasDateRange = value;
                    if (!value) {
                      _salesStartDate = null;
                      _salesEndDate = null;
                    } else {
                      _salesStartDate = DateTime.now();
                      _salesEndDate =
                          DateTime.now().add(const Duration(days: 30));
                    }
                  });
                },
              ),
              if (_hasDateRange) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _salesStartDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _salesStartDate = date;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Début des ventes',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: _salesStartDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_salesStartDate!)
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _salesEndDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: _salesStartDate ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _salesEndDate = date;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Fin des ventes',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: _salesEndDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_salesEndDate!)
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code de réduction (optionnel)',
                  hintText: 'Ex: PROMO10',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTicketType,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.ticketType == null ? 'Créer' : 'Enregistrer',
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> _saveTicketType() async {
      if (_formKey.currentState!.validate()) {
        final ticketType = TicketType(
          id: widget.ticketType?.id,
          eventId: widget.eventId,
          name: _nameController.text,
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text,
          salesStartDate: _hasDateRange ? _salesStartDate : null,
          salesEndDate: _hasDateRange ? _salesEndDate : null,
          discountCode: _discountCodeController.text.isEmpty
              ? null
              : _discountCodeController.text,
          soldCount: widget.ticketType?.soldCount ?? 0,
        );

        await _databaseService.saveTicketType(ticketType);
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }
