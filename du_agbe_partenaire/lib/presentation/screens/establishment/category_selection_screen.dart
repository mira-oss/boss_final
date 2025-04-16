import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_constants.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/form_validators.dart';
import '../../../data/models/establishment_model.dart';
import '../../../presentation/state/establishment_provider.dart';
import '../../../presentation/common_widgets/custom_button.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';

class ContactInfoScreen extends StatefulWidget {
  const ContactInfoScreen({Key? key}) : super(key: key);

  @override
  _ContactInfoScreenState createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _additionalInfoController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      final establishment =
          await establishmentProvider.getEstablishmentDetails();

      setState(() {
        _phoneController.text = establishment.phone ?? '';
        _emailController.text = establishment.email ?? '';
        _websiteController.text = establishment.website ?? '';
        _addressController.text = establishment.address ?? '';
        _cityController.text = establishment.city ?? '';
        _postalCodeController.text = establishment.postalCode ?? '';
        _additionalInfoController.text = establishment.additionalInfo ?? '';

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(
        "Erreur lors du chargement des informations de contact: ${e.toString()}",
      );
    }
  }

  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );

      await establishmentProvider.updateContactInfo(
        phone: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        address: _addressController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        additionalInfo: _additionalInfoController.text,
      );

      setState(() {
        _isSaving = false;
      });

      _showSuccessSnackBar("Informations de contact mises à jour avec succès");
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar(
        "Erreur lors de la sauvegarde des informations: ${e.toString()}",
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TextConstants.contactInfo),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: LoadingIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordonnées de contact',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Numéro de téléphone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone *',
                          hintText: '01 23 45 67 89',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: FormValidators.validatePhone,
                        onChanged: (value) {
                          // Formater automatiquement le numéro de téléphone
                          final formattedPhone = value.formatPhone();
                          if (formattedPhone != value) {
                            _phoneController.value = TextEditingValue(
                              text: formattedPhone,
                              selection: TextSelection.collapsed(
                                offset: formattedPhone.length,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'contact@votreetablissement.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmail,
                      ),
                      const SizedBox(height: 16.0),

                      // Site web
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Site web',
                          hintText: 'www.votreetablissement.com',
                          prefixIcon: Icon(Icons.language),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                        validator: FormValidators.validateWebsite,
                      ),
                      const SizedBox(height: 32.0),

                      const Text(
                        'Adresse',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Adresse
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse *',
                          hintText: '123 rue Example',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: FormValidators.validateRequired,
                      ),
                      const SizedBox(height: 16.0),

                      // Code postal et ville (sur la même ligne)
                      Row(
                        children: [
                          // Code postal
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Code postal *',
                                hintText: '75000',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: FormValidators.validatePostalCode,
                            ),
                          ),
                          const SizedBox(width: 16.0),

                          // Ville
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'Ville *',
                                hintText: 'Paris',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormValidators.validateRequired,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Informations complémentaires
                      TextFormField(
                        controller: _additionalInfoController,
                        decoration: const InputDecoration(
                          labelText: 'Informations complémentaires',
                          hintText: 'Bâtiment, étage, code d\'entrée, etc.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32.0),

                      CustomButton(
                        text: TextConstants.save,
                        isLoading: _isSaving,
                        onPressed: _saveContactInfo,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
    );
  }
}
