// lib/presentation/screens/establishment/establishment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/data/models/establishment_model.dart';
import 'package:patenaire/presentation/common_widgets/custom_button.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';
import 'package:patenaire/routes/app_router.dart';

class EstablishmentDetailsScreen extends StatefulWidget {
  const EstablishmentDetailsScreen({Key? key}) : super(key: key);

  @override
  _EstablishmentDetailsScreenState createState() =>
      _EstablishmentDetailsScreenState();
}

class _EstablishmentDetailsScreenState
    extends State<EstablishmentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      establishmentProvider.fetchEstablishmentDetails();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updateControllers(Establishment establishment) {
    _nameController.text = establishment.name;
    _addressController.text = establishment.address;
    _descriptionController.text = establishment.description;
    _categoryController.text = establishment.category;
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveEstablishment() async {
    if (_formKey.currentState!.validate()) {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      final currentEstablishment = establishmentProvider.establishment;

      if (currentEstablishment != null) {
        final updatedEstablishment = currentEstablishment.copyWith(
          name: _nameController.text,
          address: _addressController.text,
          description: _descriptionController.text,
          category: _categoryController.text,
        );

        await establishmentProvider.updateEstablishment(updatedEstablishment);
        _toggleEditing();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Informations mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détails de l'établissement"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditing,
          ),
        ],
      ),
      body: Consumer<EstablishmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: LoadingIndicator());
          }

          final establishment = provider.establishment;
          if (establishment == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Aucune information d'établissement trouvée"),
                  SizedBox(height: 16),
                  CustomButton(
                    text: "Ajouter un établissement",
                    onPressed: () {
                      // Navigation vers une page de création d'établissement
                      // ou commencer l'édition directement
                      _toggleEditing();
                    },
                  ),
                ],
              ),
            );
          }

          // Si ce n'est pas la première fois, mettre à jour les contrôleurs
          if (!_isEditing) {
            _updateControllers(establishment);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section info principale
                  _buildMainInfoSection(establishment),
                  SizedBox(height: 24),

                  // Section adresse
                  _buildAddressSection(establishment),
                  SizedBox(height: 24),

                  // Section horaires d'ouverture
                  _buildOpeningHoursSection(establishment),
                  SizedBox(height: 24),

                  // Section coordonnées
                  _buildContactSection(establishment),
                  SizedBox(height: 24),

                  // Bouton de sauvegarde (visible uniquement en mode édition)
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Enregistrer les modifications",
                          onPressed: _saveEstablishment,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInfoSection(Establishment establishment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations principales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Nom de l'établissement",
              controller: _nameController,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer le nom de l'établissement";
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Catégorie",
              controller: _categoryController,
              enabled: _isEditing,
              suffixIcon:
                  _isEditing
                      ? IconButton(
                        icon: Icon(Icons.category),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.categorySelection,
                          ).then((selectedCategory) {
                            if (selectedCategory != null) {
                              _categoryController.text =
                                  selectedCategory as String;
                            }
                          });
                        },
                      )
                      : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez sélectionner une catégorie";
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Description",
              controller: _descriptionController,
              maxLines: 3,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer une description";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Establishment establishment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Adresse",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Adresse complète",
              controller: _addressController,
              enabled: _isEditing,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer l'adresse de l'établissement";
                }
                return null;
              },
            ),
            if (!_isEditing) ...[
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.map),
                  label: Text("Voir sur la carte"),
                  onPressed: () {
                    // TODO: Ouvrir la carte avec l'adresse
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection(Establishment establishment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Horaires d'ouverture",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.openingHours);
                  },
                  child: Text("Modifier"),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildOpeningHoursList(establishment.openingHours),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHoursList(Map<String, dynamic> openingHours) {
    final List<String> days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayKey = day.toLowerCase();
        final hours = openingHours[dayKey] ?? {"open": false};

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(day, style: TextStyle(fontWeight: FontWeight.w500)),
              hours["open"]
                  ? Text(
                    "${hours['openTime']} - ${hours['closeTime']}",
                    style: TextStyle(color: Colors.green),
                  )
                  : Text("Fermé", style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactSection(Establishment establishment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Coordonnées de contact",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.contactInfo);
                  },
                  child: Text("Modifier"),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.phone, color: ColorConstants.accentColor),
              title: Text("Téléphone"),
              subtitle: Text(
                establishment.phone.isNotEmpty
                    ? establishment.phone
                    : "Non renseigné",
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.email, color: ColorConstants.accentColor),
              title: Text("Email"),
              subtitle: Text(
                establishment.email.isNotEmpty
                    ? establishment.email
                    : "Non renseigné",
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
