import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe/details.dart';
import 'package:du_agbe/details_partenaire.dart';
import 'package:du_agbe/itineraire.dart';
import 'package:du_agbe/opeinai_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _text = '';
  String _errorMessage = '';
  
  // Données
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> _generatedItineraries = [];
  
  // États de chargement
  bool _isLoading = true;
  bool _isLoadingCategories = false;
  bool _isLoadingPartners = false;
  bool _isLoadingEvents = false;
  bool _isGeneratingItinerary = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPermissions();
      await _initSpeech();
    });
    _fetchPublishedEvents();
    _fetchCategories();
    _fetchPartners();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = "Permission microphone refusée");
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('Status de reconnaissance vocale: $status');
          setState(() {
            _isListening = status == 'listening';
          });
        },
        onError: (error) {
          print('Erreur de reconnaissance vocale: ${error.errorMsg}');
          setState(() {
            _errorMessage = "Erreur microphone: ${error.errorMsg}";
            _isListening = false;
          });
        },
      );
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = "Erreur d'initialisation du micro: $e");
    }
  }

  Future<void> _listen() async {
    if (!_speechEnabled) {
      setState(() => _errorMessage = "Micro non disponible");
      await _initSpeech();
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _text = '';
        _errorMessage = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
            if (result.finalResult) {
              if (_text.isNotEmpty) {
                _generateAIResponse();
              } else {
                _errorMessage = "Aucun mot reconnu, veuillez réessayer";
              }
            }
          });
        },
        localeId: 'fr_FR',
        listenMode: stt.ListenMode.confirmation,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
      );
    }
  }

  Future<void> _generateAIResponse() async {
    if (_text.isEmpty) return;

    setState(() => _isGeneratingItinerary = true);

    try {
      final response = await OpenAIService.getAIResponse(_text);
      
      setState(() {
        _generatedItineraries = [
          {
            'name': 'Réponse à votre question',
            'time': 'Maintenant',
            'price': 'Gratuit',
            'description': response,
          }
        ];
        _isGeneratingItinerary = false;
      });
      
      if (_text.toLowerCase().contains('parcours') || 
          _text.toLowerCase().contains('itinéraire') ||
          _text.toLowerCase().contains('visite') || 
          _text.toLowerCase().contains('voyage')) {
        _generateItineraryFromText();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de génération: $e';
        _isGeneratingItinerary = false;
      });
    }
  }

  Map<String, dynamic> _extractDetailsFromText(String text) {
  // Définir des mots-clés pour les moods
  final List<String> availableMoods = ["Relax", "Romantique", "Calme", "Joie"];
  
  // Extraire le budget (exemple : "10000 FCFA" ou "10 000")
  final budgetRegex = RegExp(r'(\d{1,3}(?:[ \.,]?\d{3})*)\s*(FCFA|f|cfa)?', caseSensitive: false);
  final budgetMatch = budgetRegex.firstMatch(text);
  final budget = budgetMatch != null ? budgetMatch.group(1)?.replaceAll(RegExp(r'[ \.,]'), '') : null;

  // Extraire la location (exemple : "à Cotonou" ou "dans Porto-Novo")
  final locationRegex = RegExp(r'\b(?:à|dans|en|au|aux)\s+([A-Za-zÀ-ÖØ-öø-ÿ\s\-]+)', caseSensitive: false);
  final locationMatch = locationRegex.firstMatch(text);
  final location = locationMatch != null ? locationMatch.group(1)?.trim() : null;

  // Identifier les moods dans le texte
  final userMoods = availableMoods.where((mood) => text.toLowerCase().contains(mood.toLowerCase())).toList();

  return {
    'budget': budget ?? "10000", // Valeur par défaut si aucun budget n'est trouvé
    'location': location ?? "Cotonou", // Valeur par défaut si aucune location n'est trouvée
    'moods': userMoods.isNotEmpty ? userMoods : ["Relax"], // Valeur par défaut si aucun mood n'est trouvé
  };
}

  Future<void> _generateItineraryFromText() async {
    if (_text.isEmpty) return;

    setState(() {
      _isGeneratingItinerary = true;
      _generatedItineraries = [];
    });

    try {
      final details = _extractDetailsFromText(_text);
      
      final response = await OpenAIService.generateItinerary(
        userPrompt: _text,
        budget: details['budget'],
        location: details['location'],
        userMoods: details['moods'],
      );

      final List<Map<String, dynamic>> formattedItineraries = [];
      
      if (response['parcours'] != null) {
        for (var parcours in response['parcours']) {
          formattedItineraries.add({
            'title': parcours['titre'] ?? 'Parcours',
            'description': 'Budget total: ${parcours['budget_total'] ?? 'N/A'}',
            'activities': (parcours['etapes'] as List?)?.map((etape) => {
              'activity': '${etape['nom']} (${etape['type']})',
              'time': etape['horaires'] ?? '--',
              'price': etape['prix'] ?? '0',
            }).toList() ?? [],
            'totalPrice': parcours['budget_total'] ?? '0',
          });
        }
      }

      setState(() {
        _generatedItineraries = formattedItineraries;
        _isGeneratingItinerary = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de génération: $e';
        _isGeneratingItinerary = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('categories').get();
      
      List<Map<String, dynamic>> fetchedCategories = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        IconData getIconFromName(String iconName) {
          switch (iconName) {
            case 'utensils': return FontAwesomeIcons.utensils;
            case 'shoppingBag': return FontAwesomeIcons.shoppingBag;
            case 'umbrellaBeach': return FontAwesomeIcons.umbrellaBeach;
            case 'music': return FontAwesomeIcons.music;
            case 'mugHot': return FontAwesomeIcons.mugHot;
            case 'landmark': return FontAwesomeIcons.landmark;
            case 'hotel': return FontAwesomeIcons.hotel;
            case 'church': return FontAwesomeIcons.church;
            default: return FontAwesomeIcons.tag;
          }
        }
        
        IconData iconData = getIconFromName(data['icon'] ?? 'tag');
        
        Color color;
        try {
          color = Color(int.parse(data['color'].replaceFirst('#', '0xff')));
        } catch (e) {
          color = Colors.blue;
        }

        fetchedCategories.add({
          'id': doc.id,
          'icon': iconData,
          'label': data['name'] ?? 'Catégorie',
          'color': color,
        });
      }

      setState(() {
        categories = fetchedCategories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = 'Erreur de chargement des catégories: ${e.toString()}';
      });
      print('Erreur Firestore (catégories): $e');
    }
  }

  Future<void> _fetchPartners() async {
    setState(() {
      _isLoadingPartners = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('partenaires').get();
      
      // Récupérer tous les menus en une seule requête
      final menusSnapshot = await _firestore.collection('menus').get();
      final allMenus = menusSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      List<Map<String, dynamic>> fetchedPartners = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final partnerId = doc.id;
        
        // Filtrer les menus pour ce partenaire
        final partnerMenus = allMenus.where(
          (menu) => menu['partenaire_Id'] == partnerId
        ).toList();
        
        // Compter les menus par catégorie
        final menuCategories = {};
        for (var menu in partnerMenus) {
          final category = menu['categorie'] ?? 'Autre';
          menuCategories[category] = (menuCategories[category] ?? 0) + 1;
        }

        fetchedPartners.add({
          'id': doc.id,
          'name': data['nom'] ?? 'Partenaire',
          'description': data['description'] ?? '',
          'category': data['categorie'] ?? 'Autre',
          'contact': data['phone'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'hasMenus': partnerMenus.isNotEmpty,
          'menuCategories': menuCategories,
        });
      }

      setState(() {
        _partners = fetchedPartners;
        _isLoadingPartners = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPartners = false;
        _errorMessage = 'Erreur de chargement des partenaires: ${e.toString()}';
      });
      print('Erreur Firestore (partenaires): $e');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMenusByCategory(String partnerId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('menus')
          .where('partenaire_Id', isEqualTo: partnerId)
          .get();

      Map<String, List<Map<String, dynamic>>> result = {};
      for (var doc in querySnapshot.docs) {
        final menu = doc.data() as Map<String, dynamic>;
        final category = menu['categorie'] ?? 'Autre';
        
        if (!result.containsKey(category)) {
          result[category] = [];
        }
        
        result[category]!.add({
          'id': doc.id,
          'name': menu['nom'] ?? 'Menu',
          'description': menu['description'] ?? '',
          'price': menu['prix'] ?? '0',
          'imageUrl': menu['imageUrl'] ?? '',
        });
      }
      
      return result;
    } catch (e) {
      debugPrint('Erreur de chargement des menus: $e');
      return {};
    }
  }

  Future<void> _fetchPublishedEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'published')
          .get();
      
      List<Map<String, dynamic>> fetchedEvents = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        String imageUrl = '';
        if (data['imageUrls'] != null && data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty) {
          final firstImage = data['imageUrls'][0];
          if (firstImage is String) {
            if (firstImage.startsWith('data:image')) {
              imageUrl = firstImage;
            } else if (firstImage.startsWith('http')) {
              imageUrl = firstImage;
            } else {
              imageUrl = 'data:image/jpeg;base64,$firstImage';
            }
          }
        }

        fetchedEvents.add({
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'description': data['description'] ?? '',
          'location': data['location'] ?? 'Lieu non spécifié',
          'imageUrl': imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
          'isFavorite': false,
          'date': data['date'],
        });
      }

      setState(() {
        events = fetchedEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
      print('Erreur Firestore: $e');
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      events[index]['isFavorite'] = !events[index]['isFavorite'];
    });
  }

  void _showItineraryDetails(Map<String, dynamic> itinerary) {
    final activities = itinerary['activities'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                itinerary['title'] ?? 'Parcours',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 10),
              Text(
                itinerary['description'] ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                "Activités du parcours:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...activities.map((activity) => Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: MarkdownBody(
                    data: activity['activity'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: 16),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(activity['time'] ?? ''),
                      SizedBox(width: 15),
                      Text(
                        '${activity['price'] == '0' ? 'Gratuit' : '${activity['price']} FCFA'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )).toList(),
              SizedBox(height: 15),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total estimé:", style: TextStyle(fontSize: 16)),
                      Text(
                        "${itinerary['totalPrice'] ?? '0'} FCFA",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Parcours sélectionné!")),
                        );
                        Navigator.pop(context);
                      },
                      child: Text("Adopter ce parcours"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Retour"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPartnerDetails(Map<String, dynamic> partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerDetailsPage(partner: partner),
      ),
    );
  }

  Widget _buildMenuCategories(Map<String, dynamic> categories) {
    final entries = categories.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length && i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entries[i].key} (${entries[i].value})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        if (entries.length > 2)
          const Text(
            '+ autres catégories...',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildEventImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final encodedString = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(encodedString),
          height: 150,
          width: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } catch (e) {
        return _buildErrorImage();
      }
    } else {
      return Image.network(
        imageUrl,
        height: 150,
        width: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }
  }

  Widget _buildPartnerImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 100,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.business, size: 50, color: Colors.grey)),
      );
    }
    return Image.network(
      imageUrl,
      height: 100,
      width: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 100,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text('Image non disponible', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/images/avatar.jpeg'),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello,", style: TextStyle(fontSize: 16)),
                      Text("Prêt pour une belle journée ?",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 30),

              // Barre de recherche
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _text),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Parlez maintenant...'
                            : 'Dites-nous ce que vous voulez...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red
                            : _speechEnabled
                                ? Colors.orange
                                : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              if (_text.isNotEmpty) ...[
                SizedBox(height: 20),
                Text('Vous avez dit :', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_text),
                ),
              ],

              if (_isGeneratingItinerary) ...[
                SizedBox(height: 20),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 10),
                Text("Génération de vos parcours..."),
              ],

              if (_generatedItineraries.isNotEmpty) ...[
                SizedBox(height: 20),
                Text("Parcours suggérés:", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ..._generatedItineraries.map((itinerary) => ItineraryCard(
                  itinerary: itinerary,
                  onSelect: () => _showItineraryDetails(itinerary),
                )).toList(),
              ],

              SizedBox(height: 30),

              // Section Catégories
              Text("Catégories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              SizedBox(height: 15),

              _isLoadingCategories
                  ? Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? Center(child: Text("Aucune catégorie disponible"))
                      : Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: categories[index]["color"]!.withOpacity(0.2),
                                      child: Icon(
                                        categories[index]["icon"],
                                        color: categories[index]["color"],
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      categories[index]["label"],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

              SizedBox(height: 30),

              // Section Événements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Événements",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text("Voir tout", style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),

              SizedBox(height: 15),
              
              _isLoadingEvents 
                  ? Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? Center(child: Text("Aucun événement à afficher"))
                      : Container(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return Container(
                                width: 250,
                                margin: EdgeInsets.only(right: 15),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailsPage(event: event),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                          child: _buildEventImage(event['imageUrl']),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      event['title'],
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      event['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                                                      color: event['isFavorite'] ? Colors.red : Colors.grey,
                                                    ),
                                                    onPressed: () => _toggleFavorite(index),
                                                  ),
                                                ],
                                              ),
                                              
                                              SizedBox(height: 5),
                                              
                                              Text(
                                                event['description'].length > 50
                                                    ? '${event['description'].substring(0, 20)}...'
                                                    : event['description'],
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                              
                                              SizedBox(height: 10),
                                              
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                  SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      event['location'],
                                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                        
              SizedBox(height: 30),
              
              // Section Lieux partenaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Lieux partenaires",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text("Voir tout", style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),

              SizedBox(height: 15),

              _isLoadingPartners 
                  ? Center(child: CircularProgressIndicator())
                  : _partners.isEmpty
                      ? Center(child: Text("Aucun partenaire à afficher"))
                      : Container(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _partners.length,
                            itemBuilder: (context, index) {
                              final partner = _partners[index];
                              return GestureDetector(
                                onTap: () => _navigateToPartnerDetails(partner),
                                child: Container(
                                  width: 220,
                                  margin: EdgeInsets.only(right: 15),
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildPartnerImage(partner['imageUrl']),
                                        Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                partner['name'],
                                                style: TextStyle(
                                                  fontSize: 16, 
                                                  fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                partner['category'],
                                                style: TextStyle(
                                                  fontSize: 12, 
                                                  color: Colors.grey),
                                              ),
                                              if (partner['hasMenus'] == true) ...[
                                                SizedBox(height: 8),
                                                _buildMenuCategories(partner['menuCategories']),
                                              ],
                                            ],
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
            ],
          ),
        ),
      ),
    );
  }
}