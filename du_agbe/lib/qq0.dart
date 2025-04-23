/*import 'dart:convert';

import 'package:du_agbe/details_partenaire.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late stt.SpeechToText _speech;
  
  // États et données
  bool _isLoading = true;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _text = '';
  String _errorMessage = '';
  
  // Données
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _events = [];
  
  // États de chargement
  bool _isLoadingCategories = false;
  bool _isLoadingPartners = false;
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initApp();
  }

  Future<void> _initApp() async {
    await _checkPermissions();
    await _initSpeech();
    await Future.wait([
      _fetchCategories(),
      _fetchPartners(),
      _fetchPublishedEvents(),
    ]);
    setState(() => _isLoading = false);
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
        onStatus: (status) => setState(() => _isListening = status == 'listening'),
        onError: (error) => setState(() => _errorMessage = "Erreur microphone: ${error.errorMsg}"),
      );
    } catch (e) {
      setState(() => _errorMessage = "Erreur d'initialisation: $e");
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final snapshot = await _firestore.collection('categories').get();
      _categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'label': data['name'] ?? 'Catégorie',
          'icon': _getIconFromName(data['icon'] ?? 'tag'),
          'color': _parseColor(data['color'] ?? '#4285F4'),
        };
      }).toList();
    } catch (e) {
      _errorMessage = 'Erreur de chargement des catégories';
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

 Future<void> _fetchPartners() async {
  setState(() => _isLoadingPartners = true);
  try {
    final snapshot = await _firestore.collection('partenaires').get();
    
    // Nouveau : Récupérer tous les menus en une seule requête
    final menusSnapshot = await _firestore.collection('menus').get();
    final allMenus = menusSnapshot.docs.map((doc) => doc.data()).toList();

    _partners = snapshot.docs.map((doc) {
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

      return {
        'id': partnerId,
        'name': data['nom'] ?? 'Partenaire',
        'description': data['description'] ?? '',
        'category': data['categorie'] ?? 'Autre',
        'contact': data['phone'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
        'hasMenus': partnerMenus.isNotEmpty, // Nouveau champ
        'menuCategories': menuCategories, // Catégories disponibles
      };
    }).toList();
  } catch (e) {
    _errorMessage = 'Erreur de chargement des partenaires: $e';
  } finally {
    setState(() => _isLoadingPartners = false);
  }
}

  Future<void> _fetchPublishedEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'published')
          .get();
      
      _events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Événement',
          'description': data['description'] ?? '',
          'location': data['location'] ?? '',
          'imageUrl': _parseImageUrl(data['imageUrls']),
          'date': data['date'],
        };
      }).toList();
    } catch (e) {
      _errorMessage = 'Erreur de chargement des événements';
    } finally {
      setState(() => _isLoadingEvents = false);
    }
  }

  String _parseImageUrl(dynamic imageUrls) {
    if (imageUrls is List && imageUrls.isNotEmpty) {
      final firstImage = imageUrls[0];
      if (firstImage is String) {
        if (firstImage.startsWith('http')) return firstImage;
        if (firstImage.startsWith('data:image')) return firstImage;
        return 'data:image/jpeg;base64,$firstImage';
      }
    }
    return '';
  }

  IconData _getIconFromName(String iconName) {
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

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _navigateToPartnerDetails(BuildContext context, Map<String, dynamic> partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerDetailsPage(partner: partner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSearchBar(),
              if (_errorMessage.isNotEmpty) _buildError(),
              const SizedBox(height: 30),
              _buildCategoriesSection(),
              const SizedBox(height: 30),
              _buildEventsSection(),
              const SizedBox(height: 30),
              _buildPartnersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/images/avatar.jpeg')),
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
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: _isListening ? 'Parlez maintenant...' : 'Rechercher...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _isListening ? _speech.stop() : _speech.listen(
            onResult: (result) => setState(() => _text = result.recognizedWords),
            localeId: 'fr_FR',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _isListening ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        _errorMessage,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Catégories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: category['color'].withOpacity(0.2),
                            child: Icon(category['icon'], color: category['color']),
                          ),
                          const SizedBox(height: 5),
                          Text(category['label'], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Événements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("Voir tout", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 300,
          child: _isLoadingEvents
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 15),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEventImage(event['imageUrl']),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['title'],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    event['description'].length > 50
                                        ? '${event['description'].substring(0, 50)}...'
                                        : event['description'],
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        event['location'],
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPartnersSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Lieux partenaires", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {},
            child: const Text("Voir tout", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      const SizedBox(height: 15),
      SizedBox(
        height: 180, // Augmenté pour afficher les infos des menus
        child: _isLoadingPartners
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _partners.length,
                itemBuilder: (context, index) {
                  final partner = _partners[index];
                  return GestureDetector(
                    onTap: () => _navigateToPartnerDetails(context, partner),
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 15),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPartnerImage(partner['imageUrl']),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partner['name'],
                                    style: const TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    partner['category'],
                                    style: const TextStyle(
                                      fontSize: 12, 
                                      color: Colors.grey),
                                  ),
                                  // Afficher le nombre de menus si disponible
                                  if (partner['hasMenus'] == true) ...[
                                    const SizedBox(height: 8),
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
    if (imageUrl.isEmpty) {
      return Container(
        height: 150,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.event, size: 50, color: Colors.grey)),
      );
    }
    
    if (imageUrl.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        height: 150,
        width: 250,
        fit: BoxFit.cover,
      );
    }
    
    return Image.network(
      imageUrl,
      height: 150,
      width: 250,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 150,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
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
}*/