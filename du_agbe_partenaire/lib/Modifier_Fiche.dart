import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ModifierFichePage extends StatefulWidget {
  final String partenaireId;

  const ModifierFichePage({Key? key, required this.partenaireId})
    : super(key: key);

  @override
  _ModifierFichePageState createState() => _ModifierFichePageState();
}

class _ModifierFichePageState extends State<ModifierFichePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Contrôleurs de texte pour les informations de base
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Variables pour les horaires d'ouverture
  Map<String, Map<String, TimeOfDay?>> _horaires = {
    'Lundi': {'debut': null, 'fin': null},
    'Mardi': {'debut': null, 'fin': null},
    'Mercredi': {'debut': null, 'fin': null},
    'Jeudi': {'debut': null, 'fin': null},
    'Vendredi': {'debut': null, 'fin': null},
    'Samedi': {'debut': null, 'fin': null},
    'Dimanche': {'debut': null, 'fin': null},
  };

  // Variables pour le menu
  List<Plat> _plats = [];
  List<Categorie> _categories = [];

  // Variables pour les photos
  List<String> _photosUrls = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _coverImageUrl;
  File? _coverImageFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les données du partenaire
      DocumentSnapshot etablissementDoc =
          await _firestore
              .collection('etablissements')
              .doc(widget.partenaireId)
              .get();

      if (etablissementDoc.exists) {
        Map<String, dynamic> data =
            etablissementDoc.data() as Map<String, dynamic>;

        // Informations de base
        _nomController.text = data['nom'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _adresseController.text = data['adresse'] ?? '';
        _telephoneController.text = data['telephone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _coverImageUrl = data['coverImage'];

        // Horaires
        if (data.containsKey('horaires')) {
          Map<String, dynamic> horaires = data['horaires'];
          horaires.forEach((jour, heures) {
            if (_horaires.containsKey(jour)) {
              _horaires[jour]!['debut'] =
                  heures['debut'] != null
                      ? TimeOfDay(
                        hour: int.parse(heures['debut'].split(':')[0]),
                        minute: int.parse(heures['debut'].split(':')[1]),
                      )
                      : null;

              _horaires[jour]!['fin'] =
                  heures['fin'] != null
                      ? TimeOfDay(
                        hour: int.parse(heures['fin'].split(':')[0]),
                        minute: int.parse(heures['fin'].split(':')[1]),
                      )
                      : null;
            }
          });
        }

        // Photos
        if (data.containsKey('photos')) {
          _photosUrls = List<String>.from(data['photos']);
        }

        // Charger les catégories et plats
        await _chargerCategoriesEtPlats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerCategoriesEtPlats() async {
    try {
      // Charger les catégories
      QuerySnapshot categoriesSnapshot =
          await _firestore
              .collection('etablissements')
              .doc(widget.partenaireId)
              .collection('categories')
              .orderBy('ordre')
              .get();

      _categories =
          categoriesSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Categorie(
              id: doc.id,
              nom: data['nom'] ?? '',
              ordre: data['ordre'] ?? 0,
            );
          }).toList();

      // Charger les plats
      QuerySnapshot platsSnapshot =
          await _firestore
              .collection('etablissements')
              .doc(widget.partenaireId)
              .collection('plats')
              .orderBy('nom')
              .get();

      _plats =
          platsSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Plat(
              id: doc.id,
              nom: data['nom'] ?? '',
              description: data['description'] ?? '',
              prix: data['prix'] ?? 0,
              categorieId: data['categorieId'] ?? '',
              imageUrl: data['imageUrl'],
              disponible: data['disponible'] ?? true,
            );
          }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du menu: $e')),
      );
    }
  }

  Future<void> _sauvegarderDonnees() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? coverImageUrl = _coverImageUrl;

      // Si une nouvelle image de couverture a été sélectionnée, la télécharger
      if (_coverImageFile != null) {
        String fileName =
            'etablissements/${widget.partenaireId}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        await ref.putFile(_coverImageFile!);
        coverImageUrl = await ref.getDownloadURL();
      }

      // Formatter les horaires pour Firestore
      Map<String, Map<String, String?>> horairesFormatted = {};
      _horaires.forEach((jour, heures) {
        horairesFormatted[jour] = {
          'debut':
              heures['debut'] != null
                  ? '${heures['debut']!.hour.toString().padLeft(2, '0')}:${heures['debut']!.minute.toString().padLeft(2, '0')}'
                  : null,
          'fin':
              heures['fin'] != null
                  ? '${heures['fin']!.hour.toString().padLeft(2, '0')}:${heures['fin']!.minute.toString().padLeft(2, '0')}'
                  : null,
        };
      });

      // Sauvegarder les données de base
      await _firestore
          .collection('etablissements')
          .doc(widget.partenaireId)
          .update({
            'nom': _nomController.text,
            'description': _descriptionController.text,
            'adresse': _adresseController.text,
            'telephone': _telephoneController.text,
            'email': _emailController.text,
            'coverImage': coverImageUrl,
            'horaires': horairesFormatted,
            'photos': _photosUrls,
            'derniereMiseAJour': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informations sauvegardées avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectionnerHeure(String jour, String type) async {
    final TimeOfDay? heure = await showTimePicker(
      context: context,
      initialTime: _horaires[jour]![type] ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (heure != null) {
      setState(() {
        _horaires[jour]![type] = heure;
      });
    }
  }

  Future<void> _ajouterCategorie() async {
    TextEditingController categorieController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter une catégorie'),
          content: TextField(
            controller: categorieController,
            decoration: InputDecoration(
              labelText: 'Nom de la catégorie',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (categorieController.text.trim().isNotEmpty) {
                  try {
                    // Déterminer l'ordre de la nouvelle catégorie
                    int ordre =
                        _categories.isNotEmpty
                            ? _categories
                                    .map((c) => c.ordre)
                                    .reduce((a, b) => a > b ? a : b) +
                                1
                            : 1;

                    // Ajouter la catégorie à Firestore
                    DocumentReference docRef = await _firestore
                        .collection('etablissements')
                        .doc(widget.partenaireId)
                        .collection('categories')
                        .add({
                          'nom': categorieController.text.trim(),
                          'ordre': ordre,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                    // Ajouter la catégorie à la liste locale
                    setState(() {
                      _categories.add(
                        Categorie(
                          id: docRef.id,
                          nom: categorieController.text.trim(),
                          ordre: ordre,
                        ),
                      );
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Catégorie ajoutée avec succès!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de l\'ajout de la catégorie: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _supprimerCategorie(Categorie categorie) async {
    // Vérifier si des plats utilisent cette catégorie
    List<Plat> platsAssocies =
        _plats.where((p) => p.categorieId == categorie.id).toList();

    if (platsAssocies.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer cette catégorie : ${platsAssocies.length} plat(s) y sont associés.',
          ),
        ),
      );
      return;
    }

    bool confirmation =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer la catégorie "${categorie.nom}" ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmation) {
      try {
        // Supprimer la catégorie de Firestore
        await _firestore
            .collection('etablissements')
            .doc(widget.partenaireId)
            .collection('categories')
            .doc(categorie.id)
            .delete();

        // Supprimer la catégorie de la liste locale
        setState(() {
          _categories.removeWhere((c) => c.id == categorie.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catégorie supprimée avec succès!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de la catégorie: $e'),
          ),
        );
      }
    }
  }

  Future<void> _ajouterPlat() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez d\'abord ajouter une catégorie.')),
      );
      return;
    }

    Plat nouveauPlat = Plat(
      id: '',
      nom: '',
      description: '',
      prix: 0,
      categorieId: _categories.first.id,
      disponible: true,
    );

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ajouter un plat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nom du plat',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => nouveauPlat.nom = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => nouveauPlat.description = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Prix (FCFA)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged:
                          (value) =>
                              nouveauPlat.prix = int.tryParse(value) ?? 0,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      value: nouveauPlat.categorieId,
                      items:
                          _categories.map((categorie) {
                            return DropdownMenuItem<String>(
                              value: categorie.id,
                              child: Text(categorie.nom),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            nouveauPlat.categorieId = value;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('Disponible'),
                      value: nouveauPlat.disponible,
                      onChanged: (value) {
                        setState(() {
                          nouveauPlat.disponible = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nouveauPlat.nom.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez entrer un nom de plat'),
                        ),
                      );
                      return;
                    }

                    try {
                      // Ajouter le plat à Firestore
                      DocumentReference docRef = await _firestore
                          .collection('etablissements')
                          .doc(widget.partenaireId)
                          .collection('plats')
                          .add({
                            'nom': nouveauPlat.nom.trim(),
                            'description': nouveauPlat.description.trim(),
                            'prix': nouveauPlat.prix,
                            'categorieId': nouveauPlat.categorieId,
                            'disponible': nouveauPlat.disponible,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      // Ajouter le plat à la liste locale
                      nouveauPlat.id = docRef.id;
                      this.setState(() {
                        _plats.add(nouveauPlat);
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Plat ajouté avec succès!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'ajout du plat: $e'),
                        ),
                      );
                    }
                  },
                  child: Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _modifierPlat(Plat plat) async {
    Plat platModifie = Plat(
      id: plat.id,
      nom: plat.nom,
      description: plat.description,
      prix: plat.prix,
      categorieId: plat.categorieId,
      imageUrl: plat.imageUrl,
      disponible: plat.disponible,
    );

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier le plat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nom du plat',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: platModifie.nom),
                      onChanged: (value) => platModifie.nom = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: platModifie.description,
                      ),
                      maxLines: 3,
                      onChanged: (value) => platModifie.description = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Prix (FCFA)',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: platModifie.prix.toString(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged:
                          (value) =>
                              platModifie.prix = int.tryParse(value) ?? 0,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      value: platModifie.categorieId,
                      items:
                          _categories.map((categorie) {
                            return DropdownMenuItem<String>(
                              value: categorie.id,
                              child: Text(categorie.nom),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            platModifie.categorieId = value;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('Disponible'),
                      value: platModifie.disponible,
                      onChanged: (value) {
                        setState(() {
                          platModifie.disponible = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (platModifie.nom.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez entrer un nom de plat'),
                        ),
                      );
                      return;
                    }

                    try {
                      // Mettre à jour le plat dans Firestore
                      await _firestore
                          .collection('etablissements')
                          .doc(widget.partenaireId)
                          .collection('plats')
                          .doc(platModifie.id)
                          .update({
                            'nom': platModifie.nom.trim(),
                            'description': platModifie.description.trim(),
                            'prix': platModifie.prix,
                            'categorieId': platModifie.categorieId,
                            'disponible': platModifie.disponible,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      // Mettre à jour le plat dans la liste locale
                      this.setState(() {
                        int index = _plats.indexWhere(
                          (p) => p.id == platModifie.id,
                        );
                        if (index != -1) {
                          _plats[index] = platModifie;
                        }
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Plat modifié avec succès!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur lors de la modification du plat: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _supprimerPlat(Plat plat) async {
    bool confirmation =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer le plat "${plat.nom}" ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmation) {
      try {
        // Supprimer le plat de Firestore
        await _firestore
            .collection('etablissements')
            .doc(widget.partenaireId)
            .collection('plats')
            .doc(plat.id)
            .delete();

        // Si le plat a une image, la supprimer du storage
        if (plat.imageUrl != null && plat.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(plat.imageUrl!).delete();
          } catch (e) {
            print('Erreur lors de la suppression de l\'image: $e');
          }
        }

        // Supprimer le plat de la liste locale
        setState(() {
          _plats.removeWhere((p) => p.id == plat.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Plat supprimé avec succès!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression du plat: $e')),
        );
      }
    }
  }

  Future<void> _ajouterImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        String fileName =
            'etablissements/${widget.partenaireId}/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(fileName);

        await ref.putFile(File(image.path));
        String downloadUrl = await ref.getDownloadURL();

        setState(() {
          _photosUrls.add(downloadUrl);
        });

        // Mettre à jour la liste des photos dans Firestore
        await _firestore
            .collection('etablissements')
            .doc(widget.partenaireId)
            .update({'photos': _photosUrls});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image ajoutée avec succès!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de l\'image: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _supprimerImage(int index) async {
    bool confirmation =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer cette image ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Supprimer'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmation) {
      setState(() {
        _isSaving = true;
      });

      try {
        String imageUrl = _photosUrls[index];

        // Supprimer l'image du storage
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Erreur lors de la suppression de l\'image du storage: $e');
        }

        // Supprimer l'URL de la liste locale
        setState(() {
          _photosUrls.removeAt(index);
        });

        // Mettre à jour la liste des photos dans Firestore
        await _firestore
            .collection('etablissements')
            .doc(widget.partenaireId)
            .update({'photos': _photosUrls});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image supprimée avec succès!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de l\'image: $e'),
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectionnerImageCouverture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _coverImageFile = File(image.path);
      });
    }
  }

  String _formatHoraire(TimeOfDay? time) {
    if (time == null) return 'Non défini';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier établissement'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _isSaving ? null : _sauvegarderDonnees,
              tooltip: 'Sauvegarder',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.info_outline), text: 'Infos'),
            Tab(icon: Icon(Icons.access_time), text: 'Horaires'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Informations
                    _buildInfosTab(),

                    // Onglet Horaires
                    _buildHorairesTab(),

                    // Onglet Menu
                    _buildMenuTab(),

                    // Onglet Photos
                    _buildPhotosTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfosTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de couverture
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _coverImageFile != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _coverImageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : _coverImageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: _coverImageUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      Center(child: Icon(Icons.error)),
                            ),
                          )
                          : Center(
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: _selectionnerImageCouverture,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.edit),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Nom de l'établissement
          TextFormField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom de l\'établissement',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer une description';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Adresse
          TextFormField(
            controller: _adresseController,
            decoration: InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer une adresse';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Téléphone
          TextFormField(
            controller: _telephoneController,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un numéro de téléphone';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer un email';
              }
              // Validation simple de l'email
              if (!value.contains('@') || !value.contains('.')) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
          ),

          SizedBox(height: 24),

          // Bouton sauvegarder
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _sauvegarderDonnees,
              icon:
                  _isSaving
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.save),
              label: Text(_isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorairesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Gestion des horaires d\'ouverture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Définissez vos horaires d\'ouverture pour chaque jour de la semaine. Si vous êtes fermé un jour particulier, laissez les champs vides.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),

          ..._horaires.entries.map((entry) {
            String jour = entry.key;
            Map<String, TimeOfDay?> heures = entry.value;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jour,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectionnerHeure(jour, 'debut'),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Heure d\'ouverture',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_formatHoraire(heures['debut'])),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectionnerHeure(jour, 'fin'),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Heure de fermeture',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_formatHoraire(heures['fin'])),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (heures['debut'] != null && heures['fin'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Ouvert de ${_formatHoraire(heures['debut'])} à ${_formatHoraire(heures['fin'])}',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (heures['debut'] == null && heures['fin'] == null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Fermé',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),

          SizedBox(height: 24),

          // Bouton sauvegarder
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _sauvegarderDonnees,
              icon:
                  _isSaving
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(Icons.save),
              label: Text(_isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    // Regrouper les plats par catégorie
    Map<String, List<Plat>> platParCategorie = {};

    for (Plat plat in _plats) {
      if (!platParCategorie.containsKey(plat.categorieId)) {
        platParCategorie[plat.categorieId] = [];
      }
      platParCategorie[plat.categorieId]!.add(plat);
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _ajouterCategorie,
                    icon: Icon(Icons.add),
                    label: Text('Catégorie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _ajouterPlat,
                    icon: Icon(Icons.add),
                    label: Text('Plat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          if (_categories.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune catégorie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Commencez par ajouter une catégorie',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _ajouterCategorie,
                      icon: Icon(Icons.add),
                      label: Text('Ajouter une catégorie'),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                Categorie categorie = _categories[index];
                List<Plat> platsDeCategorie =
                    platParCategorie[categorie.id] ?? [];

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de la catégorie
                      ListTile(
                        title: Text(
                          categorie.nom,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _ajouterPlat,
                              tooltip: 'Ajouter un plat dans cette catégorie',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () => _supprimerCategorie(categorie),
                              tooltip: 'Supprimer cette catégorie',
                              color: Colors.red[400],
                            ),
                          ],
                        ),
                      ),

                      // Liste des plats de cette catégorie
                      if (platsDeCategorie.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Aucun plat dans cette catégorie',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),

                      ...platsDeCategorie.map((plat) {
                        return ListTile(
                          leading:
                              plat.imageUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: plat.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.restaurant,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                    ),
                                  )
                                  : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plat.nom,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(plat.prix)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (plat.description.isNotEmpty)
                                Text(
                                  plat.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Row(
                                children: [
                                  Icon(
                                    plat.disponible
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color:
                                        plat.disponible
                                            ? Colors.green
                                            : Colors.red[400],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    plat.disponible
                                        ? 'Disponible'
                                        : 'Non disponible',
                                    style: TextStyle(
                                      color:
                                          plat.disponible
                                              ? Colors.green
                                              : Colors.red[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _modifierPlat(plat),
                                tooltip: 'Modifier ce plat',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline),
                                onPressed: () => _supprimerPlat(plat),
                                tooltip: 'Supprimer ce plat',
                                color: Colors.red[400],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Galerie photos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _ajouterImage,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Ajouter'),
              ),
            ],
          ),

          SizedBox(height: 16),

          if (_photosUrls.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez des photos pour mettre en valeur votre établissement',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _ajouterImage,
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Ajouter une photo'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _photosUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _photosUrls[index],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: Center(child: Icon(Icons.error)),
                              ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _supprimerImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          SizedBox(height: 16),

          if (_photosUrls.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _sauvegarderDonnees,
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder',
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Categorie {
  final String id;
  final String nom;
  final int ordre;

  Categorie({required this.id, required this.nom, required this.ordre});
}

class Plat {
  String id;
  String nom;
  String description;
  int prix;
  String categorieId;
  String? imageUrl;
  bool disponible;

  Plat({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.categorieId,
    this.imageUrl,
    required this.disponible,
  });
}
