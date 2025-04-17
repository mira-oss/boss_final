import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// Modèles pour les données
class Order {
  final String id;
  final String customerName;
  final String time;
  final String status;
  final List<String> items;
  final String amount;
  final String imageUrl;

  Order({
    required this.id,
    required this.customerName,
    required this.time,
    required this.status,
    required this.items,
    required this.amount,
    required this.imageUrl,
  });
}

class Promotion {
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final String discount;
  final String? imageUrl;

  Promotion({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.discount,
    this.imageUrl,
  });
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

  // Liste des promotions
  List<Promotion> activePromotions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    // Cette fonction sera à adapter selon votre système de navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers: $pageName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Utiliser Navigator.pushNamed si vous avez configuré des routes nommées
    // Navigator.pushNamed(context, pageName);

    // Ou utiliser ceci si vous préférez créer les pages à la volée
    /*
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        switch (pageName) {
          case 'FichePage':
            return const FichePage();
          case 'MenuPage':
            return const MenuPage();
          // Ajoutez d'autres cas selon vos pages
          default:
            return const DashboardPage();
        }
      }),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MJ',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MaJournée',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            color: Colors.white,
            onPressed: () {
              _showNotificationDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Naviguer vers la page profil
                _navigateTo(context, 'ProfilePage');
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1565C0), size: 20),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simuler un chargement de données
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            // Actualiser les données
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              _buildStatsGrid(),
              _buildQuickAccessMenu(),
              _buildTabSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddPromoDialog(context);
        },
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter une promo',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF1565C0)),
              const SizedBox(width: 10),
              const Text('Notifications'),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.check_circle_outline, color: Colors.grey[600]),
                onPressed: () {
                  // Marquer toutes les notifications comme lues
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Toutes les notifications ont été marquées comme lues',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Tout marquer comme lu',
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildNotificationItem(
                  'Nouvelle commande reçue',
                  'CMD-004 de Jean Kouassi - il y a 5 min',
                  Icons.shopping_bag_outlined,
                  () {
                    Navigator.pop(context);
                    _navigateTo(context, 'OrderDetailsPage?orderId=CMD-004');
                  },
                ),
                const Divider(),
                _buildNotificationItem(
                  'Nouvel avis client',
                  'Koffi Annan vous a laissé 5 étoiles - il y a 30 min',
                  Icons.star_outline,
                  () {
                    Navigator.pop(context);
                    _navigateTo(context, 'ReviewsPage');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF1565C0)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
      trailing: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _showAddPromoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final discountController = TextEditingController();

    // Préremplir avec des valeurs par défaut pour faciliter les tests
    startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    endDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.now().add(const Duration(days: 7)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nouvelle promotion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Titre de la promotion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Happy Hour -50% sur tous les plats',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Détails de la promotion...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date de début',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: startDateController,
                              decoration: InputDecoration(
                                hintText: 'JJ/MM/AAAA',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              readOnly: true,
                              onTap: () async {
                                // Afficher le sélecteur de date
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                if (pickedDate != null) {
                                  startDateController.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(pickedDate);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date de fin',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: endDateController,
                              decoration: InputDecoration(
                                hintText: 'JJ/MM/AAAA',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              readOnly: true,
                              onTap: () async {
                                // Afficher le sélecteur de date
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                if (pickedDate != null) {
                                  endDateController.text = DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(pickedDate);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Réduction appliquée',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      hintText: 'Ex: 20%',
                      prefixIcon: const Icon(Icons.percent, size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Image de promotion (optionnel)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Logique pour sélectionner une image
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fonctionnalité de sélection d\'image à implémenter',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajouter une image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validation des champs
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            startDateController.text.isEmpty ||
                            endDateController.text.isEmpty ||
                            discountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez remplir tous les champs obligatoires',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Créer une nouvelle promotion
                        final newPromo = Promotion(
                          title: titleController.text,
                          description: descriptionController.text,
                          startDate: startDateController.text,
                          endDate: endDateController.text,
                          discount: '${discountController.text}%',
                          imageUrl: 'https://via.placeholder.com/300x200',
                        );

                        // Ajouter la promotion à la liste
                        setState(() {
                          activePromotions.add(newPromo);
                        });

                        // Fermer la boîte de dialogue
                        Navigator.pop(context);

                        // Afficher une confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promotion ajoutée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Ajouter la promotion',
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
          ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1976D2), const Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restaurant Ouvert',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Horaire: 08:00 - 22:00',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Switch(
                value: isOpen,
                onChanged: (value) {
                  setState(() {
                    isOpen = value;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Commandes', '12', Icons.shopping_bag_outlined),
              _buildStatusItem('En cuisine', '3', Icons.restaurant_outlined),
              _buildStatusItem('À livrer', '2', Icons.delivery_dining_outlined),
              _buildStatusItem('Clients', '25', Icons.people_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance du jour',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.payments_outlined,
                  value: '125,000',
                  label: 'Chiffre d\'affaires',
                  color: const Color(0xFF4CAF50),
                  change: '+12%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.shopping_cart_outlined,
                  value: '28',
                  label: 'Commandes',
                  color: const Color(0xFF2196F3),
                  change: '+5%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_outline,
                  value: '4.8',
                  label: 'Satisfaction',
                  color: const Color(0xFFFFC107),
                  change: '+0.2',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline,
                  value: '42',
                  label: 'Nouveaux clients',
                  color: const Color(0xFFFF5722),
                  change: '+8%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQuickAccessMenu() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accès rapide',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAccessItem(
                context,
                'Menu',
                Icons.restaurant_menu,
                Colors.orange,
                () => _navigateTo(context, 'MenuPage'),
              ),
              _buildQuickAccessItem(
                context,
                'Commandes',
                Icons.receipt_long,
                Colors.blue,
                () => _navigateTo(context, 'OrdersPage'),
              ),
              _buildQuickAccessItem(
                context,
                'Clients',
                Icons.people,
                Colors.purple,
                () => _navigateTo(context, 'CustomersPage'),
              ),
              _buildQuickAccessItem(
                context,
                'Analyses',
                Icons.insert_chart,
                Colors.green,
                () => _navigateTo(context, 'AnalyticsPage'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1565C0),
            tabs: const [
              Tab(text: 'Commandes'),
              Tab(text: 'Avis'),
              Tab(text: 'Menu'),
              Tab(text: 'Statistiques'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildReviewsTab(),
                _buildMenuTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return ListView.builder(
      itemCount: recentOrders.length,
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(order.imageUrl),
            ),
            title: Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.items.join(', '),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${order.time} • ${order.status}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.amount} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              _navigateTo(context, 'OrderDetailsPage?orderId=${order.id}');
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'en préparation':
        return Colors.blue;
      case 'prêt':
        return Colors.green;
      case 'livré':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      itemCount: recentReviews.length,
      itemBuilder: (context, index) {
        final review = recentReviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                review['imageUrl'] as String,
              ),
            ),
            title: Text(
              review['customerName'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i <
                              (review['rating']
                                  as int) // Parenthèses ajoutées pour plus de clarté
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review['comment'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Il y a ${review['time']}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTab() {
    return ListView.builder(
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['imageUrl'] as String,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              item['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['orderCount']} commandes ce mois',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Text(
              '${item['price']} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            onTap: () {
              _navigateTo(context, 'MenuItemPage?itemId=${item['name']}');
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_chart_outlined, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Statistiques détaillées',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consultez vos performances complètes',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _navigateTo(context, 'AnalyticsPage');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Voir les statistiques complètes'),
          ),
        ],
      ),
    );
  }

  // Fonction pour envoyer les données à Firebase
  void _sendDataToFirebase() {
    // Exemple d'envoi des commandes récentes
    for (var order in recentOrders) {
      // Envoyer chaque commande à Firebase
      // firestore.collection('orders').add(order.toMap());
    }

    // Exemple d'envoi des avis
    for (var review in recentReviews) {
      // firestore.collection('reviews').add(review);
    }

    // Exemple d'envoi des éléments du menu
    for (var item in menuItems) {
      // firestore.collection('menuItems').add(item);
    }
  }
}
