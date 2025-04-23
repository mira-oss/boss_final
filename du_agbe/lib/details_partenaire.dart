import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PartnerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> partner;
  const PartnerDetailsPage({Key? key, required this.partner}) : super(key: key);
  @override
  State<PartnerDetailsPage> createState() => _PartnerDetailsPageState();
}

class _PartnerDetailsPageState extends State<PartnerDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> _menusByCategory = {};
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isLoadingEvents = true;
  bool _isCartVisible = false;
  String _errorMessage = '';
  double _totalAmount = 0;
  
  // Pour la navigation entre les onglets
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMenus();
    _fetchEvents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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
  
  void _processOrder() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Votre panier est vide")),
      );
      return;
    }
    
    // Ici vous implementeriez la logique pour créer la commande
    // et l'envoyer au partenaire
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Commande envoyée avec succès!")),
    );
    
    setState(() {
      _cartItems.clear();
      _totalAmount = 0;
      _isCartVisible = false;
    });
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
              label: Text('${_cartItems.length} articles'),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
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
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.partner['category'] ?? 'Restaurant',
                  style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
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
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
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
            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
        labelColor: Colors.orange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.orange,
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
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade200],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 18,
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
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showMenuDetails(menu);
        },
        borderRadius: BorderRadius.circular(12),
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
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (menu['description']?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        menu['description'],
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${menu['price']} FCFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addToCart(menu),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '${menu['price']} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                menu['description'] ?? 'Pas de description disponible',
                style: const TextStyle(fontSize: 16),
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
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      width: 100,
      height: 100,
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
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy - HH:mm').format(event['date']),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
                              const SnackBar(content: Text('Événement ajouté à votre agenda')),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('Ajouter à lagenda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: const Text('Adresse'),
                subtitle: Text(widget.partner['address'] ?? 'Adresse non disponible'),
                onTap: () {
                  // Ouvrir la carte
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.orange),
                title: const Text('Contact'),
                subtitle: Text(widget.partner['contact'] ?? 'Contact non disponible'),
                onTap: widget.partner['contact'] != null
                    ? () => _launchWhatsApp(widget.partner['contact'])
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.orange),
                title: const Text('Horaires d\'ouverture'),
                subtitle: Text(widget.partner['hours'] ?? 'Lun-Dim: 08:00 - 22:00'),
              ),
              const Divider(height: 1),
              if (widget.partner['website'] != null)
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text('Site web'),
                  subtitle: Text(widget.partner['website']),
                  onTap: () {
                    // Ouvrir le site web
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'À propos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.partner['about'] ?? 
                  'Ce partenaire s\'engage à vous offrir une expérience unique avec des produits de qualité et un service exceptionnel.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avis et commentaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      '${widget.partner['rating'] ?? 4.5}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBar.builder(
                          initialRating: widget.partner['rating']?.toDouble() ?? 4.5,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 20,
                          ignoreGestures: true,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {},
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${widget.partner['ratingCount'] ?? 45} avis',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    // Afficher tous les avis
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Voir tous les avis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCartOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          AppBar(
            title: const Text('Votre Panier'),
            backgroundColor: Colors.orange,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isCartVisible = false;
                });
              },
            ),
          ),
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Votre panier est vide',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCartVisible = false;
                              _tabController.animateTo(0); // Retour à l'onglet menu
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Voir le menu'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item['imageUrl']?.isNotEmpty == true
                                    ? CachedNetworkImage(
                                        imageUrl: item['imageUrl'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.restaurant, color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.restaurant, color: Colors.grey),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['price']} FCFA',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => _updateQuantity(index, item['quantity'] - 1),
                                    color: Colors.red,
                                    iconSize: 28,
                                  ),
                                  Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _updateQuantity(index, item['quantity'] + 1),
                                    color: Colors.green,
                                    iconSize: 28,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Valider la commande',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}