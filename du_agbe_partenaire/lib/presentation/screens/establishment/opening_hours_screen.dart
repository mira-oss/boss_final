// lib/presentation/screens/establishment/opening_hours_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';

class OpeningHoursScreen extends StatefulWidget {
  const OpeningHoursScreen({Key? key}) : super(key: key);

  @override
  _OpeningHoursScreenState createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends State<OpeningHoursScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Liste des jours de la semaine
  final List<String> _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  // Structure pour stocker les horaires
  Map<String, Map<String, dynamic>> _openingHours = {};

  @override
  void initState() {
    super.initState();
    _loadOpeningHours();
  }

  // Charger les horaires actuels
  Future<void> _loadOpeningHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      final establishment = establishmentProvider.currentEstablishment;

      if (establishment != null) {
        // Initialiser les horaires depuis l'établissement
        final existingHours = establishment.openingHours;

        // Structure par défaut pour chaque jour
        for (final day in _weekdays) {
          if (existingHours.containsKey(day.toLowerCase())) {
            _openingHours[day] = Map<String, dynamic>.from(
              existingHours[day.toLowerCase()],
            );
          } else {
            _openingHours[day] = {
              'isOpen': false,
              'periods': [
                {'open': '09:00', 'close': '18:00'},
              ],
            };
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des horaires: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sauvegarder les horaires
  Future<void> _saveOpeningHours() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      final establishmentId = establishmentProvider.currentEstablishment!.id;

      // Convertir le format des horaires pour la sauvegarde
      Map<String, dynamic> formattedHours = {};
      _openingHours.forEach((day, value) {
        formattedHours[day.toLowerCase()] = value;
      });

      // Mettre à jour dans Firestore en utilisant la méthode updateEstablishmentDetails existante
      await establishmentProvider.updateEstablishmentDetails(
        openingHours: formattedHours,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horaires mis à jour avec succès')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la sauvegarde des horaires: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Ajouter une période pour un jour
  void _addPeriod(String day) {
    setState(() {
      (_openingHours[day]!['periods'] as List).add({
        'open': '09:00',
        'close': '18:00',
      });
    });
  }

  // Supprimer une période
  void _removePeriod(String day, int index) {
    setState(() {
      (_openingHours[day]!['periods'] as List).removeAt(index);
    });
  }

  // Gérer le changement d'horaire
  void _updateTime(String day, int periodIndex, String field, String value) {
    setState(() {
      (_openingHours[day]!['periods'] as List)[periodIndex][field] = value;
    });
  }

  // Gérer le changement d'état ouvert/fermé
  void _toggleDayOpen(String day, bool value) {
    setState(() {
      _openingHours[day]!['isOpen'] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horaires d\'ouverture'),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Définissez les horaires d\'ouverture de votre établissement',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Liste des jours
                    ..._weekdays.map((day) => _buildDayCard(day)),
                    const SizedBox(height: 24),
                    // Bouton de sauvegarde
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                          text: 'Enregistrer',
                          onPressed: _saveOpeningHours,
                          backgroundColor: ColorConstants.primaryColor,
                          // Suppression du paramètre isFullWidth s'il n'est pas défini dans CustomButton
                          // Si vous voulez garder cette fonctionnalité, vous devrez modifier CustomButton
                        ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDayCard(String day) {
    final dayData = _openingHours[day]!;
    final isOpen = dayData['isOpen'] as bool;
    final periods = dayData['periods'] as List;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (value) => _toggleDayOpen(day, value),
                  activeColor: ColorConstants.primaryColor,
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 8),
              ...List.generate(periods.length, (index) {
                return _buildTimePeriod(day, index, periods[index]);
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _addPeriod(day),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter une plage horaire'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Fermé',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriod(String day, int index, Map<dynamic, dynamic> period) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeField(
              'Ouverture',
              period['open'] as String,
              (value) => _updateTime(day, index, 'open', value),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTimeField(
              'Fermeture',
              period['close'] as String,
              (value) => _updateTime(day, index, 'close', value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed:
                (_openingHours[day]!['periods'] as List).length > 1
                    ? () => _removePeriod(day, index)
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTimeString(currentValue),
        );

        if (picked != null) {
          final formattedTime = _formatTimeOfDay(picked);
          onChanged(formattedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Text(currentValue),
      ),
    );
  }

  // Convertir une chaîne d'heure en TimeOfDay
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Formater TimeOfDay en chaîne
  String _formatTimeOfDay(TimeOfDay time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
