/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> partner;
  const PartnerDetailsPage({Key? key, required this.partner}) : super(key: key);
  @override
  State<PartnerDetailsPage> createState() => _PartnerDetailsPageState();
}

class _PartnerDetailsPageState extends State<PartnerDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  Map<String, List<Map<String, dynamic>>> _menusByCategory = {};
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  bool _isLoading = true;
  bool _isLoadingEvents = true;
  bool _isCartVisible = false;
  bool _isProcessingOrder = false;
  
  String _errorMessage = '';
  double _totalAmount = 0;
  
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
    _setupMapData();
    _getUserLocation();
  }
  
  void _setupMapData() {
    if (widget.partner['latitude'] != null && widget.partner['longitude'] != null) {
      setState(() {
        _partnerLat = double.parse(widget.partner['latitude'].toString());
        _partnerLng = double.parse(widget.partner['longitude'].toString());
        
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
      });
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
        final menu = doc.data() as Map<String, dynamic>;
        final category = menu['categorie'] ?? 'Autre';
        if (!groupedMenus.containsKey(category)) {
          groupedMenus[category] = [];
        }
        groupedMenus[category]!.add({
          'id': doc.id,
          'name': menu['nom'] ?? 'Menu sans nom',
          'description': menu['description'] ?? '',
          'price': menu['prix']?.toString() ?? '0',
          'imageUrl': menu['imageUrl'] ?? '',
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
        final event = doc.data() as Map<String, dynamic>;
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
                initialRating: widget.partner['rating']?.toDouble() ?? 4.5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                ignoreGestures: true,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: _accentColor,
                ),
                onRatingUpdate: (rating) {},
              ),
              const SizedBox(width: 5),
              Text(
                '(${widget.partner['ratingCount'] ?? 45})',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
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
                        TextButton.icon(
                          onPressed: () => _addToCart(menu),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Ajouter'),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
  
  void _showMenuDetails(Map<String, dynamic> menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: menu['imageUrl']?.isNotEmpty == true
                    ? Image.network(
                        menu['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                menu['name'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${menu['price']} FCFA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                menu['description'] ?? 'Pas de description disponible',
                style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.8)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _addToCart(menu);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Ajouter au panier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuPlaceholder() {
    return Container(
      width: 85,
      height: 85,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.restaurant, color: Colors.grey)),
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
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'Aucun événement à venir',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: event['imageUrl']?.isNotEmpty == true
                    ? Image.network(
                        event['imageUrl'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.event, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.event, size: 50, color: Colors.grey),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy - HH:mm').format(event['date']),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: _textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Logique pour ajouter à l'agenda
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
  content: Text('Événement ajouté à votre agenda'),
),
);
},
icon: const Icon(Icons.calendar_today),
label: const Text('Ajouter à l\'agenda'),
style: OutlinedButton.styleFrom(
  foregroundColor: _primaryColor,
),
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
  // Vérifier si les coordonnées du partenaire sont disponibles
  bool hasLocation = _partnerLat != null && _partnerLng != null;
  
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordonnées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 15),
              
              // Adresse
              if (widget.partner['address']?.isNotEmpty == true) ...[
                _buildInfoRow(
                  Icons.location_on,
                  widget.partner['address'],
                  onTap: hasLocation
                      ? () => _launchMaps(_partnerLat!, _partnerLng!, widget.partner['name'])
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              
              // Téléphone
              if (widget.partner['phone']?.isNotEmpty == true) ...[
                _buildInfoRow(
                  Icons.phone,
                  widget.partner['phone'],
                  onTap: () async {
                    final url = 'tel:${widget.partner['phone']}';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              
              // WhatsApp
              if (widget.partner['whatsapp']?.isNotEmpty == true) ...[
                _buildInfoRow(
                  Icons.telegram,
                  'WhatsApp',
                  onTap: () => _launchWhatsApp(widget.partner['whatsapp']),
                ),
                const SizedBox(height: 12),
              ],
              
              // Email
              if (widget.partner['email']?.isNotEmpty == true) ...[
                _buildInfoRow(
                  Icons.email,
                  widget.partner['email'],
                  onTap: () async {
                    final url = 'mailto:${widget.partner['email']}';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              
              // Site web
              if (widget.partner['website']?.isNotEmpty == true) ...[
                _buildInfoRow(
                  Icons.language,
                  widget.partner['website'],
                  onTap: () async {
                    if (await canLaunch(widget.partner['website'])) {
                      await launch(widget.partner['website']);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      
      // Horaires
      if (widget.partner['schedules'] != null) ...[
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horaires d\'ouverture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Afficher les horaires
                _buildSchedulesList(widget.partner['schedules']),
              ],
            ),
          ),
        ),
      ],
      
      // Carte
      if (hasLocation)
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              
              // Carte Google Maps
              Container(
                height: 200,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isLoadingLocation
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_partnerLat!, _partnerLng!),
                            zoom: 15,
                          ),
                          markers: _markers,
                          myLocationEnabled: _userPosition != null,
                          myLocationButtonEnabled: true,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          zoomControlsEnabled: true,
                        ),
                ),
              ),
              
              // Bouton pour ouvrir dans Google Maps
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMaps(_partnerLat!, _partnerLng!, widget.partner['name']),
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _buildInfoRow(IconData icon, String text, {Function()? onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: onTap != null ? _primaryColor : _textColor,
                decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSchedulesList(Map<String, dynamic> schedules) {
  final days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  
  final dayNames = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };
  
  return Column(
    children: days.map((day) {
      final schedule = schedules[day];
      String timeText = 'Fermé';
      
      if (schedule != null && schedule['isOpen'] == true) {
        final open = schedule['openTime'] ?? '08:00';
        final close = schedule['closeTime'] ?? '18:00';
        timeText = '$open - $close';
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayNames[day] ?? day,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 15,
                color: timeText == 'Fermé' ? Colors.red[400] : _textColor,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildCartOverlay() {
  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du panier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Votre panier',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'Votre panier est vide',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image miniature
                          if (item['imageUrl']?.isNotEmpty == true)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.restaurant, color: Colors.grey),
                            ),
                            
                          const SizedBox(width: 12),
                          
                          // Nom et prix
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _textColor,
                                  ),
                                ),
                                Text(
                                  '${item['price']} FCFA',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Contrôle de quantité
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _updateQuantity(index, (item['quantity'] as int) - 1),
                                color: _primaryColor,
                                iconSize: 20,
                              ),
                              Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _updateQuantity(index, (item['quantity'] as int) + 1),
                                color: _primaryColor,
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          
          // Pied de page avec le total et le bouton de commande
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
                    onPressed: _cartItems.isEmpty ? null : _processOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                            'Valider la commande',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}*/