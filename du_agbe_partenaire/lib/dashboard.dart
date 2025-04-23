import 'package:du_agbe_pro/Auth/clients.dart';
import 'package:du_agbe_pro/Auth/menu.dart';
import 'package:du_agbe_pro/chiffre.dart';
import 'package:du_agbe_pro/commandes.dart';
import 'package:du_agbe_pro/promotion.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'Profil.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'gestion_visuel.dart';
import 'promotion.dart';
import 'Profil.dart';

// Modèles pour les données
class Order {
  final String id;
  final String customerName;
  final String time;
  final String status;
  final List<String> items;
  final String amount;
  final String imageUrl;
  final DateTime date;

  Order({
    required this.id,
    required this.customerName,
    required this.time,
    required this.status,
    required this.items,
    required this.amount,
    required this.imageUrl,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

class Promotion {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String discount;
  final DateTime? createdAt;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.discount,
    this.createdAt,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'discount': discount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Créer une Promotion à partir d'un DocumentSnapshot
  factory Promotion.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      discount: data['discount'] ?? '',
      createdAt: data['createdAt']?.toDate(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  bool isOpen = true;
  int selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changé de 4 à 3
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Données fictives - À remplacer avec Firebase plus tard
  final List<Order> recentOrders = [
    Order(
      id: 'CMD-001',
      customerName: 'Sophie Adegbite',
      time: '10:25',
      status: 'En attente',
      items: ['Plat à Pufut x1', 'Jus d\'orange x2'],
      amount: '13500',
      imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    ),
    Order(
      id: 'CMD-002',
      customerName: 'Éric Koudou',
      time: '11:10',
      status: 'En préparation',
      items: ['Plat à Large x2'],
      amount: '20000',
      imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
    Order(
      id: 'CMD-003',
      customerName: 'Marie Dupont',
      time: '12:05',
      status: 'Prêt',
      items: ['Plat à Cocke x3', 'Eau minérale x3'],
      amount: '24000',
      imageUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
    ),
  ];

  final List<Map<String, dynamic>> recentReviews = [
    {
      'customerName': 'Annie Vauce',
      'time': '28 min',
      'rating': 5,
      'comment':
          'Cuisine délicieuse comme toujours, et un service très agréable !',
      'imageUrl': 'https://randomuser.me/api/portraits/women/22.jpg',
    },
    {
      'customerName': 'Martin Harson',
      'time': '2 heures',
      'rating': 4,
      'comment': 'Bonne cuisine, mais service un peu lent aujourd\'hui.',
      'imageUrl': 'https://randomuser.me/api/portraits/men/56.jpg',
    },
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Plat à Cocke',
      'price': '6000',
      'description': 'Cabillaud, riz sauvage',
      'imageUrl': 'https://via.placeholder.com/100',
      'orderCount': 34,
    },
    {
      'name': 'Plat à Pufut',
      'price': '12000',
      'description': 'Gambas, riz créole',
      'imageUrl': 'https://via.placeholder.com/100',
      'orderCount': 28,
    },
    {
      'name': 'Plat à Large',
      'price': '10000',
      'description': 'Poisson entier, manioc',
      'imageUrl': 'https://via.placeholder.com/100',
      'orderCount': 22,
    },
  ];

  // Naviguer vers une page spécifique
  void _navigateTo(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers: $pageName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1. Status Card at the top of the dashboard
  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue de retour !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aujourd\'hui: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.watch_later_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text('En ligne', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '2 nouvelles commandes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Stats Grid showing key metrics
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aperçu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Revenus du jour',
                '45 000 FCFA',
                Icons.attach_money,
                Colors.green,
                true,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Commandes',
                '18',
                Icons.shopping_bag_outlined,
                Colors.blue,
                false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Clients',
                '12',
                Icons.people_outline,
                Colors.orange,
                false,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Panier moyen',
                '3 750 FCFA',
                Icons.shopping_cart_outlined,
                Colors.purple,
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for stat cards
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool showTrend,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (showTrend)
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                      Text(
                        '12%',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Quick Access Menu with shortcuts
  Widget _buildQuickAccessMenu() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accès rapide',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAccessButton(
                  Icons.restaurant_menu, 
                  'Menu', 
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RestaurantApp()),
                    );
                  },
                  Colors.orange, // Correction de l'erreur: null remplacé par une couleur
                ),
                _buildQuickAccessButton(
                  Icons.shopping_bag_outlined,
                  'Commandes',
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CommandesPage()));
                  },
                  Colors.blue
                ),
                _buildQuickAccessButton(
                  Icons.people,
                  'Clients',
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Chiffre()));
                  },
                  Colors.purple
                ),
                _buildQuickAccessButton(
                  Icons.insert_chart,
                  'Analyses',
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Chiffre()));
                  },
                  Colors.green
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for quick access buttons
  Widget _buildQuickAccessButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Tab Section with Recent Orders, Reviews, and Popular Menu Items
  Widget _buildTabSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1565C0),
            tabs: const [
              Tab(text: 'Commandes récentes'),
              Tab(text: 'Avis clients'),
              Tab(text: 'Plats populaires'),
              // Supprimé le Tab 'Marketing'
            ],
          ),
          SizedBox(
            height: 300, // Fixed height for the tab content
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildRecentOrdersTab(),
                _buildReviewsTab(),
                _buildPopularItemsTab(),
                // Supprimé _buildMarketingTab()
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab content for Recent Orders
  Widget _buildRecentOrdersTab() {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final formatDate = DateFormat('HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length,
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              '${order.id} - ${order.customerName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF202124),
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  order.time,
                  style: const TextStyle(color: Color(0xFF5F6368)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        order.status == 'En préparation'
                            ? const Color(0xFFFEF7E0)
                            : order.status == 'En attente'
                            ? const Color(0xFFE8F0FE)
                            : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${order.amount} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF202124),
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      'Détail de la commande',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Liste des articles
                    ...order.items.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    // Actions
                    Row(
                      children: [
                        if (order.status != 'Prêt' && order.status != 'Terminé')
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              order.status == 'En attente'
                                  ? 'Marquer comme en préparation'
                                  : 'Marquer comme prêt',
                            ),
                            onPressed: () {
                              // Mettre à jour le statut
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Statut mis à jour'),
                                ),
                              );
                            },
                          ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Imprimer'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Impression en cours...'),
                              ),
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

  // Helper method for status colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'En préparation':
        return Colors.blue;
      case 'Prêt':
        return Colors.green;
      case 'Terminé':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Tab content for Reviews
  Widget _buildReviewsTab() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentReviews.length,
      itemBuilder: (context, index) {
        final review = recentReviews[index];
        final rating =
            (review['rating'] as num).toInt(); // Convertir num en int

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      review['imageUrl'],
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customerName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            rating,
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          ...List.generate(
                            5 - rating,
                            (index) => Icon(
                              Icons.star_outline,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'il y a ${review['time']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review['comment'],
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab content for Popular Menu Items
  Widget _buildPopularItemsTab() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(item['imageUrl']),
                    fit: BoxFit.cover,
                  ),
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['price']} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item['orderCount']} commandes',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Du Agbe Pro',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Colors.grey[800],
            onPressed: () {
              _navigateTo(context, 'NotificationsPage');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: Colors.grey[800],
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsWrapper(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            _buildStatsGrid(),
            _buildQuickAccessMenu(),
            _buildTabSection(),
            // Supprimé _buildPromotionsSection() car maintenant dans une page dédiée
          ],
        ),
      ),
    );
  }
}