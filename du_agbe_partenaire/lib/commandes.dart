import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser Firebase ici si nécessaire
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Commandes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1a73e8),
      ),
      home: const CommandesPage(),
    );
  }
}

// Service de gestion des commandes
class CommandeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer la collection commandes et y ajouter des exemples réalistes
  Future<void> creerCommandes() async {
    // Vérifier d'abord si la collection est vide
    QuerySnapshot snapshot =
        await _firestore.collection('commandes').limit(1).get();

    if (snapshot.docs.isEmpty) {
      // Ajouter des commandes réalistes avec noms de clients
      final List<Map<String, dynamic>> exemplesCommandes = [
        {
          'client': {
            'nom': 'Dupont',
            'prenom': 'Marie',
            'imageUrl': 'https://randomuser.me/api/portraits/women/42.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          'montant': 6850,
          'status': 'En préparation',
          'heure': '12:45',
          'items': [
            {'nom': 'Steak frites', 'quantite': 2, 'prix': 1650},
            {'nom': 'Salade César', 'quantite': 1, 'prix': 1250},
            {'nom': 'Coca Cola', 'quantite': 3, 'prix': 380},
            {'nom': 'Tiramisu', 'quantite': 1, 'prix': 650},
          ],
        },
        {
          'client': {
            'nom': 'Martin',
            'prenom': 'Thomas',
            'imageUrl': 'https://randomuser.me/api/portraits/men/22.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          'montant': 5200,
          'status': 'En préparation',
          'heure': '12:30',
          'items': [
            {'nom': 'Pizza Margherita', 'quantite': 1, 'prix': 1350},
            {'nom': 'Pâtes Carbonara', 'quantite': 1, 'prix': 1450},
            {'nom': 'Vin Rouge (verre)', 'quantite': 2, 'prix': 550},
            {'nom': 'Café', 'quantite': 2, 'prix': 180},
          ],
        },
        {
          'client': {
            'nom': 'Dubois',
            'prenom': 'Sophie',
            'imageUrl': 'https://randomuser.me/api/portraits/women/65.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1)),
          ),
          'montant': 9200,
          'status': 'Terminée',
          'heure': '12:00',
          'items': [
            {'nom': 'Plateau de fruits de mer', 'quantite': 1, 'prix': 4500},
            {'nom': 'Salade verte', 'quantite': 1, 'prix': 850},
            {'nom': 'Bouteille Chablis', 'quantite': 1, 'prix': 3200},
            {'nom': 'Assortiment de desserts', 'quantite': 1, 'prix': 650},
          ],
        },
        {
          'client': {
            'nom': 'Leroy',
            'prenom': 'Jean',
            'imageUrl': 'https://randomuser.me/api/portraits/men/45.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
          'montant': 4300,
          'status': 'Terminée',
          'heure': '11:00',
          'items': [
            {'nom': 'Burger Maison', 'quantite': 1, 'prix': 1550},
            {'nom': 'Frites Maison', 'quantite': 1, 'prix': 450},
            {'nom': 'Bière pression', 'quantite': 2, 'prix': 580},
            {'nom': 'Crème brûlée', 'quantite': 1, 'prix': 550},
          ],
        },
        {
          'client': {
            'nom': 'Petit',
            'prenom': 'Claire',
            'imageUrl': 'https://randomuser.me/api/portraits/women/32.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 45)),
          ),
          'montant': 7600,
          'status': 'En préparation',
          'heure': '12:15',
          'items': [
            {'nom': 'Entrecôte', 'quantite': 1, 'prix': 2300},
            {'nom': 'Gratin Dauphinois', 'quantite': 1, 'prix': 750},
            {'nom': 'Salade composée', 'quantite': 1, 'prix': 950},
            {'nom': 'Vin Rosé (bouteille)', 'quantite': 1, 'prix': 2450},
            {'nom': 'Crème glacée', 'quantite': 2, 'prix': 580},
          ],
        },
        {
          'client': {
            'nom': 'Lefebvre',
            'prenom': 'Antoine',
            'imageUrl': 'https://randomuser.me/api/portraits/men/67.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 3)),
          ),
          'montant': 5700,
          'status': 'Terminée',
          'heure': '10:00',
          'items': [
            {'nom': 'Poulet rôti', 'quantite': 1, 'prix': 1850},
            {'nom': 'Légumes de saison', 'quantite': 1, 'prix': 650},
            {'nom': 'Eau minérale', 'quantite': 2, 'prix': 280},
            {'nom': 'Mousse au chocolat', 'quantite': 2, 'prix': 550},
          ],
        },
        {
          'client': {
            'nom': 'Moreau',
            'prenom': 'Nathalie',
            'imageUrl': 'https://randomuser.me/api/portraits/women/17.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          'montant': 3450,
          'status': 'En préparation',
          'heure': '12:50',
          'items': [
            {'nom': 'Quiche Lorraine', 'quantite': 1, 'prix': 1250},
            {'nom': 'Salade verte', 'quantite': 1, 'prix': 550},
            {'nom': 'Jus d\'orange', 'quantite': 2, 'prix': 420},
            {'nom': 'Tarte aux pommes', 'quantite': 1, 'prix': 650},
          ],
        },
        {
          'client': {
            'nom': 'Simon',
            'prenom': 'Pierre',
            'imageUrl': 'https://randomuser.me/api/portraits/men/36.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 4)),
          ),
          'montant': 8200,
          'status': 'Terminée',
          'heure': '09:00',
          'items': [
            {'nom': 'Couscous royal', 'quantite': 2, 'prix': 1950},
            {'nom': 'Pain maison', 'quantite': 1, 'prix': 250},
            {'nom': 'Vin rouge (bouteille)', 'quantite': 1, 'prix': 2800},
            {'nom': 'Café gourmand', 'quantite': 2, 'prix': 750},
          ],
        },
        {
          'client': {
            'nom': 'Bertrand',
            'prenom': 'Julie',
            'imageUrl': 'https://randomuser.me/api/portraits/women/8.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          'montant': 4100,
          'status': 'En préparation',
          'heure': '12:55',
          'items': [
            {'nom': 'Risotto aux champignons', 'quantite': 1, 'prix': 1750},
            {'nom': 'Bruschetta', 'quantite': 1, 'prix': 850},
            {'nom': 'Vin blanc (verre)', 'quantite': 2, 'prix': 480},
            {'nom': 'Panna cotta', 'quantite': 1, 'prix': 550},
          ],
        },
        {
          'client': {
            'nom': 'Roux',
            'prenom': 'Marc',
            'imageUrl': 'https://randomuser.me/api/portraits/men/91.jpg',
          },
          'date': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 5)),
          ),
          'montant': 6200,
          'status': 'Terminée',
          'heure': '08:00',
          'items': [
            {'nom': 'Magret de canard', 'quantite': 1, 'prix': 2300},
            {'nom': 'Pommes de terre sautées', 'quantite': 1, 'prix': 550},
            {'nom': 'Champagne (verre)', 'quantite': 2, 'prix': 950},
            {'nom': 'Assortiment de fromages', 'quantite': 1, 'prix': 1450},
          ],
        },
      ];

      // Utiliser un batch pour ajouter plusieurs documents en une seule opération
      WriteBatch batch = _firestore.batch();

      for (var commande in exemplesCommandes) {
        DocumentReference docRef = _firestore.collection('commandes').doc();
        batch.set(docRef, commande);
      }

      await batch.commit();
    }
  }

  // Récupérer toutes les commandes
  Stream<List<Map<String, dynamic>>> getCommandes() {
    return _firestore
        .collection('commandes')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            // Ajouter l'ID du document aux données
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Mettre à jour le statut d'une commande
  Future<void> updateCommandeStatus(String commandeId, String newStatus) {
    return _firestore.collection('commandes').doc(commandeId).update({
      'status': newStatus,
    });
  }
}

class CommandesPage extends StatefulWidget {
  const CommandesPage({Key? key}) : super(key: key);

  @override
  _CommandesPageState createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommandeService _commandeService = CommandeService();
  final formatCurrency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final formatDate = DateFormat('dd/MM/yyyy HH:mm');

  bool _isLoading = true;
  bool _isInitializing = false;
  List<Map<String, dynamic>> _allCommandes = [];

  String _searchQuery = '';
  bool _showFilters = false;
  String _selectedStatus = 'Tous';
  String _selectedDate = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Créer les commandes dans Firebase
      await _commandeService.creerCommandes();

      // Commencer à écouter les changements
      _commandeService.getCommandes().listen(
        (commandes) {
          setState(() {
            _allCommandes = commandes;
            _isLoading = false;
            _isInitializing = false;
          });
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de chargement: $error')),
          );
          setState(() {
            _isLoading = false;
            _isInitializing = false;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur d\'initialisation: $e')));
      setState(() {
        _isInitializing = false;
        _isLoading = false;
      });
    }
  }

  void _updateCommandeStatus(String commandeId, String newStatus) {
    _commandeService
        .updateCommandeStatus(commandeId, newStatus)
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
        });
  }

  // Filtrer les commandes selon les critères
  List<Map<String, dynamic>> get _filteredCommandes {
    List<Map<String, dynamic>> result = [];

    // Filtrer par status selon le tab
    switch (_tabController.index) {
      case 0: // Toutes
        result = List.from(_allCommandes);
        break;
      case 1: // En préparation
        result =
            _allCommandes
                .where((cmd) => cmd['status'] == 'En préparation')
                .toList();
        break;
      case 2: // Terminées
        result =
            _allCommandes.where((cmd) => cmd['status'] == 'Terminée').toList();
        break;
    }

    // Appliquer recherche
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((cmd) {
            final client = cmd['client'] as Map<String, dynamic>;
            return cmd['id'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                client['nom'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                client['prenom'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    // Filtrer par statut
    if (_selectedStatus != 'Tous') {
      result = result.where((cmd) => cmd['status'] == _selectedStatus).toList();
    }

    // Filtrer par date
    if (_selectedDate != 'Tous') {
      final now = DateTime.now();
      if (_selectedDate == 'Aujourd\'hui') {
        result =
            result.where((cmd) {
              DateTime date = (cmd['date'] as Timestamp).toDate();
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            }).toList();
      } else if (_selectedDate == 'Cette semaine') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        result =
            result.where((cmd) {
              DateTime date = (cmd['date'] as Timestamp).toDate();
              return date.isAfter(startDate);
            }).toList();
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        backgroundColor: const Color(0xFF1a73e8),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CommandeSearchDelegate(this),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Toutes (${_allCommandes.length})'),
            Tab(
              text:
                  'En préparation (${_allCommandes.where((cmd) => cmd['status'] == 'En préparation').length})',
            ),
            Tab(
              text:
                  'Terminées (${_allCommandes.where((cmd) => cmd['status'] == 'Terminée').length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message d'initialisation
          if (_isInitializing)
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1a73e8)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Création et chargement des commandes en cours...',
                      style: TextStyle(color: Color(0xFF1a73e8)),
                    ),
                  ),
                ],
              ),
            ),

          // Filtres (visible uniquement quand activé)
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedStatus,
                          items:
                              ['Tous', 'En préparation', 'Terminée']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Période',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedDate,
                          items:
                              ['Tous', 'Aujourd\'hui', 'Cette semaine']
                                  .map(
                                    (date) => DropdownMenuItem(
                                      value: date,
                                      child: Text(date),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDate = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'Tous';
                            _selectedDate = 'Tous';
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showFilters = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a73e8),
                        ),
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Liste des commandes
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCommandesList(),
                        _buildCommandesList(),
                        _buildCommandesList(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandesList() {
    final commandes = _filteredCommandes;

    if (commandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'Aucune commande disponible'
                  : _tabController.index == 1
                  ? 'Aucune commande en préparation'
                  : 'Aucune commande terminée',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: commandes.length,
      itemBuilder: (context, index) {
        final commande = commandes[index];
        final client = commande['client'] as Map<String, dynamic>;
        final DateTime commandeDate = (commande['date'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(client['imageUrl']),
              radius: 24,
            ),
            title: Text(
              '${client['prenom']} ${client['nom']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${commande['heure']} - ${formatDate.format(commandeDate).split(' ')[0]}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        commande['status'] == 'En préparation'
                            ? Colors.amber[50]
                            : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          commande['status'] == 'En préparation'
                              ? Colors.amber
                              : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    commande['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          commande['status'] == 'En préparation'
                              ? Colors.amber[800]
                              : Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              formatCurrency.format(commande['montant'] / 100),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Liste des articles
                    ...(commande['items'] as List).map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['quantite']}x ${item['nom']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              formatCurrency.format(
                                (item['prix'] * item['quantite']) / 100,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    // Total
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            formatCurrency.format(commande['montant'] / 100),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1a73e8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Informations client
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(client['imageUrl']),
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${client['prenom']} ${client['nom']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Client régulier',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (commande['status'] == 'En préparation')
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Terminer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _updateCommandeStatus(commande['id'], 'Terminée');
                            },
                          ),
                        if (commande['status'] == 'Terminée')
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('En préparation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _updateCommandeStatus(
                                commande['id'],
                                'En préparation',
                              );
                            },
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print),
                              tooltip: 'Imprimer la facture',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Impression demandée'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Partager la commande',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Partage non disponible'),
                                  ),
                                );
                              },
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
}

// Delegate pour la recherche de commandes
class CommandeSearchDelegate extends SearchDelegate<String> {
  final _CommandesPageState _commandesPageState;

  CommandeSearchDelegate(this._commandesPageState);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _commandesPageState._searchQuery = query;
    return Container(); // Retourne un widget vide car nous reviendrons à l'écran principal
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Recherchez par nom ou ID de commande',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Filtrer les commandes selon la requête
    final suggestions =
        _commandesPageState._allCommandes.where((commande) {
          final client = commande['client'] as Map<String, dynamic>;
          return commande['id'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              client['nom'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              client['prenom'].toString().toLowerCase().contains(
                query.toLowerCase(),
              );
        }).toList();

    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$query"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final commande = suggestions[index];
        final client = commande['client'] as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(client['imageUrl']),
          ),
          title: Text('${client['prenom']} ${client['nom']}'),
          subtitle: Text(
            'ID: ${commande['id']} - Statut: ${commande['status']}',
            style: TextStyle(
              color:
                  commande['status'] == 'En préparation'
                      ? Colors.amber[800]
                      : Colors.green[800],
            ),
          ),
          trailing: Text(
            _commandesPageState.formatCurrency.format(
              commande['montant'] / 100,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            _commandesPageState._searchQuery = query;
            close(context, query);
          },
        );
      },
    );
  }
}

// Classe pour créer une nouvelle commande
class NouvelleCommandePage extends StatefulWidget {
  const NouvelleCommandePage({Key? key}) : super(key: key);

  @override
  _NouvelleCommandePageState createState() => _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends State<NouvelleCommandePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  final List<Map<String, dynamic>> _itemsCommande = [];
  final CommandeService _commandeService = CommandeService();
  final formatCurrency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  // Liste d'articles disponibles
  final List<Map<String, dynamic>> _menuItems = [
    {'nom': 'Steak frites', 'prix': 1650},
    {'nom': 'Salade César', 'prix': 1250},
    {'nom': 'Pizza Margherita', 'prix': 1350},
    {'nom': 'Pâtes Carbonara', 'prix': 1450},
    {'nom': 'Burger Maison', 'prix': 1550},
    {'nom': 'Poulet rôti', 'prix': 1850},
    {'nom': 'Coca Cola', 'prix': 380},
    {'nom': 'Jus d\'orange', 'prix': 420},
    {'nom': 'Vin Rouge (verre)', 'prix': 550},
    {'nom': 'Bière pression', 'prix': 580},
    {'nom': 'Tiramisu', 'prix': 650},
    {'nom': 'Crème brûlée', 'prix': 550},
    {'nom': 'Mousse au chocolat', 'prix': 550},
  ];

  String? _selectedItem;
  int _quantite = 1;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  void _ajouterItem() {
    if (_selectedItem == null) return;

    final itemIndex = _menuItems.indexWhere(
      (item) => item['nom'] == _selectedItem,
    );
    if (itemIndex == -1) return;

    final menuItem = _menuItems[itemIndex];

    setState(() {
      // Vérifier si l'article existe déjà dans la commande
      final existingIndex = _itemsCommande.indexWhere(
        (item) => item['nom'] == menuItem['nom'],
      );

      if (existingIndex != -1) {
        // Mettre à jour la quantité
        _itemsCommande[existingIndex]['quantite'] += _quantite;
      } else {
        // Ajouter un nouvel article
        _itemsCommande.add({
          'nom': menuItem['nom'],
          'prix': menuItem['prix'],
          'quantite': _quantite,
        });
      }

      // Réinitialiser les champs
      _selectedItem = null;
      _quantite = 1;
    });
  }

  void _supprimerItem(int index) {
    setState(() {
      _itemsCommande.removeAt(index);
    });
  }

  num get _totalCommande {
    return _itemsCommande.fold(
      0,
      (sum, item) => sum + (item['prix'] * item['quantite']),
    );
  }

  Future<void> _enregistrerCommande() async {
    if (_formKey.currentState!.validate() && _itemsCommande.isNotEmpty) {
      try {
        // Créer un document pour la nouvelle commande
        final nouvelleCommande = {
          'client': {
            'nom': _nomController.text.trim(),
            'prenom': _prenomController.text.trim(),
            'imageUrl':
                'https://randomuser.me/api/portraits/${_nomController.text.length % 2 == 0 ? 'men' : 'women'}/${(_nomController.text.length + _prenomController.text.length) % 99}.jpg',
          },
          'date': Timestamp.now(),
          'montant': _totalCommande,
          'status': 'En préparation',
          'heure': DateFormat('HH:mm').format(DateTime.now()),
          'items': _itemsCommande,
        };

        // Ajouter la commande à Firebase
        await FirebaseFirestore.instance
            .collection('commandes')
            .add(nouvelleCommande);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande enregistrée avec succès')),
        );

        // Retourner à l'écran précédent
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } else if (_itemsCommande.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un article à la commande'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Commande'),
        backgroundColor: const Color(0xFF1a73e8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations Client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nom du client';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le prénom du client';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Ajouter des articles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Articles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sélection d'article
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Article',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedItem,
                              items:
                                  _menuItems
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item['nom'] as String,
                                          child: Text(
                                            '${item['nom']} - ${formatCurrency.format(item['prix'] / 100)}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedItem = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantité
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Qté',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _quantite.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _quantite = int.tryParse(value) ?? 1;
                                  if (_quantite < 1) _quantite = 1;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bouton d'ajout
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ElevatedButton(
                              onPressed: _ajouterItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1a73e8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Liste des articles ajoutés
                      if (_itemsCommande.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Aucun article ajouté',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < _itemsCommande.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(_itemsCommande[i]['nom']),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${_itemsCommande[i]['quantite']}x',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatCurrency.format(
                                          (_itemsCommande[i]['prix'] *
                                                  _itemsCommande[i]['quantite']) /
                                              100,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _supprimerItem(i),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(thickness: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formatCurrency.format(_totalCommande / 100),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1a73e8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bouton de validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enregistrerCommande,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a73e8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Enregistrer la commande',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Ajout d'un FAB pour aller à la page d'accueil
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CommandesPage()),
          );
        },
        backgroundColor: const Color(0xFF1a73e8),
        child: const Icon(Icons.home),
      ),
    );
  }
}
