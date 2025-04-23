import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PartnerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> partner;
  const PartnerDetailsPage({Key? key, required this.partner}) : super(key: key);
  @override
  State<PartnerDetailsPage> createState() => _PartnerDetailsPageState();
}

class _PartnerDetailsPageState extends State<PartnerDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  Map<String, List<Map<String, dynamic>>> _menusByCategory = {};
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  bool _isLoading = true;
  bool _isLoadingEvents = true;
  bool _isCartVisible = false;
  bool _isProcessingOrder = false;
  bool _isSubmittingRating = false;
  
  String _errorMessage = '';
  double _totalAmount = 0;
  double _userRating = 0;
  
  // Pour la navigation entre les onglets
  late TabController _tabController;
  
  // Pour la carte
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  double? _partnerLat;
  double? _partnerLng;
  Position? _userPosition;
  bool _isLoadingLocation = false;
  
  // Palette de couleurs simplifiée
  final Color _primaryColor = const Color(0xFF3F51B5);  // Indigo plus doux
  final Color _accentColor = const Color(0xFFFF9800);   // Orange plus doux
  final Color _bgColor = const Color(0xFFF5F5F5);       // Gris très clair
  final Color _textColor = const Color(0xFF424242);     // Gris foncé
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMenus();
    _fetchEvents();
    _getUserRating();
    _setupMapData();
    _getUserLocation();
  }
  
  void _setupMapData() {
    // Vérifier si le partenaire a des coordonnées de localisation
    if (widget.partner['localisation'] != null) {
      try {
        final dynamic locationData = widget.partner['localisation'];
        if (locationData is Map<String, dynamic>) {
          setState(() {
            _partnerLat = locationData['lat'] != null ? double.parse(locationData['lat'].toString()) : null;
            _partnerLng = locationData['long'] != null ? double.parse(locationData['long'].toString()) : null;
            
            if (_partnerLat != null && _partnerLng != null) {
              // Créer un marqueur pour la position du partenaire
              _markers.add(
                Marker(
                  markerId: MarkerId('partner_${widget.partner['id']}'),
                  position: LatLng(_partnerLat!, _partnerLng!),
                  infoWindow: InfoWindow(
                    title: widget.partner['name'],
                    snippet: widget.partner['address'] ?? '',
                  ),
                ),
              );
            }
          });
        }
      } catch (e) {
        debugPrint('Erreur lors de l\'extraction des coordonnées: $e');
      }
    }
  }
  
  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Les permissions de localisation sont définitivement refusées');
      }
      
      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _userPosition = position;
        
        // Ajouter un marqueur pour la position de l'utilisateur
        _markers.add(
          Marker(
            markerId: const MarkerId('user_position'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: "Votre position",
            ),
          ),
        );
      });
      
    } catch (e) {
      debugPrint('Erreur de localisation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'obtenir votre position: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserRating() async {
    try {
      // Vérifier si l'utilisateur est connecté
      final user = _auth.currentUser;
      if (user == null) return;
      
      final ratingDoc = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('partnerId', isEqualTo: widget.partner['id'])
          .limit(1)
          .get();
      
      if (ratingDoc.docs.isNotEmpty) {
        setState(() {
          _userRating = (ratingDoc.docs.first.data()['rating'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la note: $e');
    }
  }
  
  Future<void> _submitRating(double rating) async {
    // Vérifier si l'utilisateur est connecté
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour noter')),
      );
      return;
    }
    
    setState(() {
      _isSubmittingRating = true;
    });
    
    try {
      // Vérifier si l'utilisateur a déjà noté ce partenaire
      final ratingsQuery = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .where('partnerId', isEqualTo: widget.partner['id'])
          .limit(1)
          .get();
      
      if (ratingsQuery.docs.isNotEmpty) {
        // Mettre à jour la note existante
        await _firestore.collection('ratings').doc(ratingsQuery.docs.first.id).update({
          'rating': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Créer une nouvelle note
        await _firestore.collection('ratings').add({
          'userId': user.uid,
          'partnerId': widget.partner['id'],
          'partnerName': widget.partner['name'],
          'rating': rating,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Mettre à jour la note moyenne du partenaire
      await _updatePartnerAverageRating(widget.partner['id']);
      
      setState(() {
        _userRating = rating;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre note!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la notation: ${e.toString()}')),
      );
      debugPrint('Erreur lors de la notation: $e');
    } finally {
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }
  
  Future<void> _updatePartnerAverageRating(String partnerId) async {
    try {
      // Récupérer toutes les notes pour ce partenaire
      final ratingsQuery = await _firestore
          .collection('ratings')
          .where('partnerId', isEqualTo: partnerId)
          .get();
      
      if (ratingsQuery.docs.isEmpty) return;
      
      // Calculer la note moyenne
      double sum = 0;
      for (var doc in ratingsQuery.docs) {
        sum += (doc.data()['rating'] as num).toDouble();
      }
      double average = sum / ratingsQuery.docs.length;
      
      // Mettre à jour la note moyenne dans la collection partenaires
      await _firestore.collection('partenaires').doc(partnerId).update({
        'rating': average,
        'ratingCount': ratingsQuery.docs.length,
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la note moyenne: $e');
    }
  }
  
  Future<void> _fetchMenus() async {
    try {
      final querySnapshot = await _firestore
          .collection('menus')
          .where('id_partenaire', isEqualTo: widget.partner['id'])
          .get();
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ce partenaire n\'a pas encore de menus';
        });
        return;
      }
      Map<String, List<Map<String, dynamic>>> groupedMenus = {};
      for (var doc in querySnapshot.docs) {
        final menu = doc.data();
        final category = menu['categorie'] ?? 'Autre';
        if (!groupedMenus.containsKey(category)) {
          groupedMenus[category] = [];
        }
        groupedMenus[category]!.add({
          'id': doc.id,
          'name': menu['nom'] ?? 'Menu sans nom',
          'description': menu['description'] ?? '',
          'price': menu['prix']?.toString() ?? '0',
          'imageUrl': menu['photo'] ?? '', // Utiliser le champ 'photo' pour les images
          'quantity': 0,
        });
      }
      setState(() {
        _menusByCategory = groupedMenus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des menus: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Erreur de chargement des menus: $e');
    }
  }
  
  Future<void> _fetchEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('partnerId', isEqualTo: widget.partner['id'])
          .orderBy('date', descending: false)
          .get();
      
      List<Map<String, dynamic>> events = [];
      for (var doc in querySnapshot.docs) {
        final event = doc.data();
        events.add({
          'id': doc.id,
          'title': event['title'] ?? 'Événement sans titre',
          'description': event['description'] ?? '',
          'date': event['date'] != null ? (event['date'] as Timestamp).toDate() : DateTime.now(),
          'imageUrl': event['imageUrl'] ?? '',
        });
      }
      
      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
      debugPrint('Erreur de chargement des événements: $e');
    }
  }
  
  void _addToCart(Map<String, dynamic> menu) {
    setState(() {
      // Chercher si l'article est déjà dans le panier
      int existingIndex = _cartItems.indexWhere((item) => item['id'] == menu['id']);
      
      if (existingIndex != -1) {
        // Augmenter la quantité si l'article existe déjà
        _cartItems[existingIndex]['quantity']++;
      } else {
        // Ajouter le nouvel article au panier
        Map<String, dynamic> cartItem = {...menu};
        cartItem['quantity'] = 1;
        _cartItems.add(cartItem);
      }
      
      // Mettre à jour le montant total
      _calculateTotal();
    });
    
    // Afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${menu['name']} ajouté au panier"),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Voir panier',
          onPressed: () {
            setState(() {
              _isCartVisible = true;
            });
          },
        ),
      ),
    );
  }
  
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateTotal();
    });
  }
  
  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }
    
    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
      _calculateTotal();
    });
  }
  
  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += (double.tryParse(item['price']) ?? 0) * (item['quantity'] ?? 1);
    }
    _totalAmount = total;
  }
  
  Future<void> _processOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Votre panier est vide")),
      );
      return;
    }
    
    // Éviter les soumissions multiples
    if (_isProcessingOrder) return;
    
    setState(() {
      _isProcessingOrder = true;
    });
    
    try {
      // Obtenir l'ID de l'utilisateur connecté
      String? userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        throw Exception("Vous devez être connecté pour passer une commande");
      }
      
      // Créer un ID unique pour la commande
      String orderId = const Uuid().v4();
      
      // Préparer les articles pour la commande
      List<Map<String, dynamic>> orderItems = _cartItems.map((item) {
        return {
          'menuId': item['id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'imageUrl': item['imageUrl'],
        };
      }).toList();
      
      // Créer la commande dans Firestore
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'partnerId': widget.partner['id'],
        'partnerName': widget.partner['name'],
        'items': orderItems,
        'totalAmount': _totalAmount,
        'status': 'pending', // pending, confirmed, ready, delivered, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Sauvegarder également l'historique de commande pour l'utilisateur
      await _firestore.collection('users').doc(userId).collection('orderHistory').doc(orderId).set({
        'orderId': orderId,
        'partnerId': widget.partner['id'],
        'partnerName': widget.partner['name'],
        'partnerImage': widget.partner['imageUrl'] ?? '',
        'totalAmount': _totalAmount,
        'itemCount': _cartItems.length,
        'mainItem': _cartItems.isNotEmpty ? _cartItems[0]['name'] : '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Envoyer une notification au partenaire
      await _sendPartnerNotification(orderId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commande envoyée avec succès!"),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _cartItems.clear();
        _totalAmount = 0;
        _isCartVisible = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessingOrder = false;
      });
    }
  }
  
  Future<void> _sendPartnerNotification(String orderId) async {
    try {
      // Récupérer les informations du partenaire
      final partnerDoc = await _firestore
          .collection('partenaires')
          .doc(widget.partner['id'])
          .get();
          
      if (!partnerDoc.exists) return;
      
      final partnerData = partnerDoc.data();
      if (partnerData == null) return;
      
      // Récupérer le token FCM du partenaire
      String? fcmToken = partnerData['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;
      
      // Récupérer les informations de l'utilisateur
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Créer la notification dans Firestore
      await _firestore.collection('notifications').add({
        'recipientId': widget.partner['id'],
        'recipientType': 'partner',
        'title': 'Nouvelle commande',
        'body': 'Vous avez reçu une nouvelle commande de ${user.displayName ?? "un client"}',
        'type': 'newOrder',
        'data': {
          'orderId': orderId,
          'userId': user.uid,
          'userName': user.displayName ?? "Client",
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification au partenaire: $e');
    }
  }
  
  Future<void> _launchMaps(double lat, double lng, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir Google Maps")),
      );
    }
  }
  
  Future<void> _launchWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: _buildPartnerHeader(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTabBar(),
                  ),
                ];
              },
              body: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMenuTab(),
                      _buildEventsTab(),
                      _buildInfoTab(),
                    ],
                  ),
                  // Afficher le panier
                  if (_isCartVisible) _buildCartOverlay(),
                ],
              ),
            ),
      floatingActionButton: _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isCartVisible = !_isCartVisible;
                });
              },
              label: Text(
                '${_cartItems.length} ${_cartItems.length > 1 ? 'articles' : 'article'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: _accentColor,
            )
          : null,
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.partner['name'] ?? 'Détails du lieu',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 5)]
          ),
        ),
        background: Hero(
          tag: 'partner-${widget.partner['id']}',
          child: widget.partner['imageUrl']?.isNotEmpty == true
              ? CachedNetworkImage(
                  imageUrl: widget.partner['imageUrl'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.business, size: 50, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.business, size: 50, color: Colors.grey),
                ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ajouté aux favoris')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Option de partage')),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildPartnerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.partner['category'] ?? 'Restaurant',
                  style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              RatingBar.builder(
                initialRating: _userRating > 0 ? _userRating : (widget.partner['rating']?.toDouble() ?? 4.5),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                ignoreGestures: false, // Permettre la notation
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: _accentColor,
                ),
                onRatingUpdate: (rating) {
                  // Enregistrer la note de l'utilisateur
                  _submitRating(rating);
                },
              ),
              const SizedBox(width: 5),
              Text(
                '(${widget.partner['ratingCount'] ?? 45})',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          if (_isSubmittingRating) ...[
            const SizedBox(height: 5),
            Text(
              'Enregistrement de votre notation...',
              style: TextStyle(color: _primaryColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            widget.partner['description'] ?? 'Description non disponible',
            style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.restaurant_menu),
            text: 'Menu',
          ),
          Tab(
            icon: Icon(Icons.event),
            text: 'Événements',
          ),
          Tab(
            icon: Icon(Icons.info),
            text: 'Infos',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuTab() {
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }
    
    if (_menusByCategory.isEmpty) {
      return const Center(child: Text('Aucun menu disponible'));
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._menusByCategory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10, top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              ...entry.value.map((menu) => _buildMenuCard(menu)).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildMenuCard(Map<String, dynamic> menu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          _showMenuDetails(menu);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: menu['imageUrl']?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: menu['imageUrl'],
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 85,
                          height: 85,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => _buildMenuPlaceholder(),
                      )
                    : _buildMenuPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    if (menu['description']?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        menu['description'],
                        style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${menu['price']} FCFA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                        Material(
                          borderRadius: BorderRadius.circular(20),
                          color: _primaryColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _addToCart(menu);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: const Text(
                                'Ajouter',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
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
  }
  
  Widget _buildMenuPlaceholder() {
    return Container(
      width: 85,
      height: 85,
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, color: Colors.grey[400], size: 30),
    );
  }
  
  void _showMenuDetails(Map<String, dynamic> menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 200,
                child: menu['imageUrl']?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: menu['imageUrl'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        menu['name'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${menu['price']} FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (menu['description']?.isNotEmpty == true) ...[
                    Text(
                      menu['description'],
                      style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Quantité selector
                  StatefulBuilder(
                    builder: (context, setState) {
                      int quantity = 1;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantité',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: _primaryColor,
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() {
                                      quantity--;
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: _primaryColor,
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // Ajouter plusieurs fois selon la quantité
                                final cartItem = Map<String, dynamic>.from(menu);
                                cartItem['quantity'] = quantity;
                                
                                // Ajouter au panier et fermer la modal
                                Navigator.pop(context);
                                
                                setState(() {
                                  // Chercher si l'article est déjà dans le panier
                                  int existingIndex = _cartItems.indexWhere((item) => item['id'] == cartItem['id']);
                                  
                                  if (existingIndex != -1) {
                                    // Remplacer l'article existant avec la nouvelle quantité
                                    _cartItems[existingIndex]['quantity'] = quantity;
                                  } else {
                                    // Ajouter le nouvel article au panier
                                    _cartItems.add(cartItem);
                                  }
                                  
                                  // Mettre à jour le montant total et afficher le panier
                                  _calculateTotal();
                                  _isCartVisible = true;
                                });
                              },
                              child: const Text(
                                'Ajouter au panier',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun événement à venir',
              style: TextStyle(
                fontSize: 18, 
                color: _textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.black12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event['imageUrl']?.isNotEmpty == true)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: event['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.event, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy • HH:mm').format(event['date']),
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event['description'],
                      style: TextStyle(fontSize: 15, color: _textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Ajouter au calendrier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fonctionnalité à venir')),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Partager'),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryColor,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fonctionnalité à venir')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Heures d'ouverture
        _buildInfoSection(
          title: 'Horaires',
          icon: Icons.access_time,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHourRow('Lundi - Vendredi', '08:00 - 22:00'),
              _buildHourRow('Samedi', '09:00 - 23:00'),
              _buildHourRow('Dimanche', '10:00 - 20:00'),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Contact
        _buildInfoSection(
          title: 'Contact',
          icon: Icons.contact_phone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.partner['phone'] != null) ...[
                _buildContactRow(
                  Icons.phone, 
                  widget.partner['phone'],
                  onTap: () => launch('tel:${widget.partner['phone']}'),
                ),
              ],
              if (widget.partner['email'] != null) ...[
                _buildContactRow(
                  Icons.email, 
                  widget.partner['email'],
                  onTap: () => launch('mailto:${widget.partner['email']}'),
                ),
              ],
              if (widget.partner['whatsapp'] != null) ...[
                _buildContactRow(
                  Icons.phone_iphone, 
                  'WhatsApp',
                  onTap: () => _launchWhatsApp(widget.partner['whatsapp']),
                ),
              ],
              if (widget.partner['website'] != null) ...[
                _buildContactRow(
                  Icons.language, 
                  widget.partner['website'],
                  onTap: () => launch(widget.partner['website']),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Adresse avec carte
        _buildInfoSection(
          title: 'Localisation',
          icon: Icons.location_on,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.partner['address'] != null) ...[
                Text(
                  widget.partner['address'],
                  style: TextStyle(fontSize: 15, color: _textColor.withOpacity(0.8)),
                ),
                const SizedBox(height: 12),
              ],
              
              // Carte Google Maps
              if (_partnerLat != null && _partnerLng != null) ...[
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_partnerLat!, _partnerLng!),
                        zoom: 14,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Itinéraire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _partnerLat != null && _partnerLng != null
                            ? () => _launchMaps(_partnerLat!, _partnerLng!, widget.partner['name'] ?? '')
                            : null,
                      ),
                    ),
                    if (_mapController != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _isLoadingLocation
                            ? null
                            : () {
                                if (_userPosition != null && _mapController != null) {
                                  _mapController!.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(_userPosition!.latitude, _userPosition!.longitude),
                                      15,
                                    ),
                                  );
                                } else {
                                  _getUserLocation();
                                }
                              },
                        tooltip: 'Ma position',
                        color: _primaryColor,
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Text(
                  'Localisation non disponible',
                  style: TextStyle(color: _textColor.withOpacity(0.6), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Moyens de paiement acceptés
        _buildInfoSection(
          title: 'Moyens de paiement acceptés',
          icon: Icons.payment,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPaymentMethod('Espèces', Icons.money),
              _buildPaymentMethod('Carte bancaire', Icons.credit_card),
              _buildPaymentMethod('Mobile Money', Icons.phone_android),
              _buildPaymentMethod('PayPal', Icons.payment),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
      ],
    );
  }
  
  Widget _buildHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 15,
              color: _textColor.withOpacity(0.8),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactRow(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: onTap != null ? _primaryColor : _textColor.withOpacity(0.8),
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: _primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethod(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          // En-tête du panier
          Container(
            color: _primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Votre panier',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isCartVisible = false;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Liste des articles
          Expanded(
            child: Container(
              color: Colors.white,
              child: _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Votre panier est vide',
                            style: TextStyle(
                              fontSize: 18,
                              color: _textColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isCartVisible = false;
                                _tabController.animateTo(0); // Revenir à l'onglet menu
                              });
                            },
                            child: Text(
                              'Parcourir le menu',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        return _buildCartItem(_cartItems[index], index);
                      },
                    ),
            ),
          ),
          
          // Pied du panier (total + bouton commander)
          if (_cartItems.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isProcessingOrder ? null : _processOrder,
                      child: _isProcessingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Passer la commande',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['imageUrl']?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(double.tryParse(item['price']) ?? 0).toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 14,
                      color: _accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _updateQuantity(index, (item['quantity'] ?? 1) - 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: _textColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                '${item['quantity'] ?? 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _textColor,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _updateQuantity(index, (item['quantity'] ?? 1) + 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: _textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeFromCart(index),
                        tooltip: 'Supprimer',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
  }
}