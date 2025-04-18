import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:du_agbe/details.dart';
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
  final List<Map<String, dynamic>> categories = [
    {"icon": FontAwesomeIcons.utensils, "label": "Restaurants", "color": Colors.red},
    {"icon": FontAwesomeIcons.shoppingBag, "label": "Shopping", "color": Colors.blue},
    {"icon": FontAwesomeIcons.umbrellaBeach, "label": "Plages", "color": Colors.teal},
    {"icon": FontAwesomeIcons.music, "label": "Événements", "color": Colors.purple},
    {"icon": FontAwesomeIcons.mugHot, "label": "Cafés", "color": Colors.brown},
    {"icon": FontAwesomeIcons.landmark, "label": "Culture", "color": Colors.orange},
  ];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _text = '';
  String _errorMessage = '';
  List<Map<String, dynamic>> events = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _generatedItineraries = [];
  bool _isGeneratingItinerary = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkPermissions() ;
    _fetchPublishedEvents();
    _initSpeech();
  }

  void _toggleFavorite(int index) {
    setState(() {
      events[index]['isFavorite'] = !events[index]['isFavorite'];
    });
  }

  Future<void> _fetchPublishedEvents() async {
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
        });
      }

      setState(() {
        events = fetchedEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
      print('Erreur Firestore: $e');
    }
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
    await _initSpeech(); // Tentative de ré-init
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
          
          // Si la reconnaissance est terminée et que nous avons du texte
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
      listenFor: Duration(seconds: 30), // Durée maximale d'écoute
      pauseFor: Duration(seconds: 3),   // Pause après laquelle on considère que l'utilisateur a fini de parler
    );
  }
}


Future<void> _generateItineraryFromText() async {
  if (_text.isEmpty) return;

  setState(() {
    _isGeneratingItinerary = true;
    _generatedItineraries = [];
  });

  try {
    final response = await OpenAIService.generateItinerary(
      userPrompt: _text,
      budget: "10000", // Vous pouvez rendre ce paramètre dynamique
      location: "Cotonou",
    );

    // Transformez la réponse de l'IA en format utilisable
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

Future<void> _generateAIResponse() async {
  if (_text.isEmpty) return;

  setState(() => _isGeneratingItinerary = true);

  try {
    // Pour une réponse simple de l'IA
    final response = await OpenAIService.getAIResponse(_text);
    
    setState(() {
      // Afficher la réponse texte simple
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
    
    // Si la demande concerne un itinéraire, générer un itinéraire
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
  Text("Parcours suggérés:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  SizedBox(height: 10),
  ..._generatedItineraries.map((itinerary) => ItineraryCard(
    itinerary: itinerary,
    onSelect: () => _showItineraryDetails(itinerary),
  )).toList(),
],

      if (_generatedItineraries.isNotEmpty) ...[
        SizedBox(height: 30),
        Text("Vos parcours personnalisés",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
      ],

              SizedBox(height: 30),

              // Titre section catégories
              Text("Catégories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              SizedBox(height: 15),

              // Liste horizontale des catégories
              Container(
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
                            backgroundColor:
                                categories[index]["color"]!.withOpacity(0.2),
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
                  Text("Événements récents",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text("Voir tout", style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),

              SizedBox(height: 15),
              
              _isLoading 
                  ? Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? Center(child: Text("Aucun événement à afficher"))
                      : Container(
                          height: 300, // Hauteur fixe pour le conteneur horizontal
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return Container(
                                width: 250, // Largeur fixe pour chaque carte
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
                                        // Image de l'événement
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                          child: _buildEventImage(event['imageUrl']),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Titre et bouton favori
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
                                              
                                              // Description réduite
                                              Text(
                                                event['description'].length > 50
                                                    ? '${event['description'].substring(0, 50)}...'
                                                    : event['description'],
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                              
                                              SizedBox(height: 10),
                                              
                                              // Localisation en bas
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
            ],
          ),
        ),
      ),
    );
  }
 void _showItineraryDetails(Map<String, dynamic> itinerary) {
  final activities = itinerary['activities'] as List<dynamic>? ?? [];
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Pour permettre plus d'espace
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
              itinerary['name'] ?? 'Parcours',
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
                    Text(
                      "Total estimé:",
                      style: TextStyle(fontSize: 16),
                    ),
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
                      // Ajouter ici la fonctionnalité pour sauvegarder ou partager le parcours
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
}