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

  // Récupérer toutes les commandes - CORRIGÉ pour gérer les erreurs de type
  Stream<List<Map<String, dynamic>>> getCommandes() {
    return _firestore
        .collection('commandes')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            // Vérifier que le client est bien un Map
            if (data['client'] is String) {
              // Si client est une chaîne, convertir en Map
              data['client'] = {
                'nom': data['client'],
                'prenom': '',
                'imageUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
              };
            } else if (data['client'] == null) {
              // Si client est null, créer un client par défaut
              data['client'] = {
                'nom': 'Client',
                'prenom': 'Inconnu',
                'imageUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
              };
            }

            // Vérifier que items est bien une liste
            if (data['items'] == null) {
              data['items'] = [];
            }

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

  // Créer une nouvelle commande - méthode d'exemple
  Future<void> creerNouvelleCommande(Map<String, dynamic> commandeData) async {
    try {
      // S'assurer que la structure des données est correcte
      if (commandeData['client'] is String) {
        String clientNom = commandeData['client'];
        commandeData['client'] = {
          'nom': clientNom,
          'prenom': '',
          'imageUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
        };
      }

      await _firestore.collection('commandes').add(commandeData);
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      throw e;
    }
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
      // Ajout d'un FAB pour créer une nouvelle commande
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NouvelleCommandePage(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1a73e8),
        child: const Icon(Icons.add),
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

        // CORRECTION: Vérifier que client est bien un Map avant de l'utiliser
        final client =
            commande['client'] is Map
                ? commande['client'] as Map<String, dynamic>
                : {
                  'nom': commande['client'] ?? 'Client',
                  'prenom': '',
                  'imageUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
                };

        final DateTime commandeDate = (commande['date'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              // CORRECTION: Vérifier que l'imageUrl existe
              backgroundImage: NetworkImage(
                client['imageUrl'] ??
                    'https://randomuser.me/api/portraits/lego/1.jpg',
              ),
              radius: 24,
            ),
            title: Text(
              '${client['prenom'] ?? ''} ${client['nom'] ?? 'Client'}',
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
                      '${commande['heure'] ?? ''} - ${formatDate.format(commandeDate).split(' ')[0]}',
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
                    commande['status'] ?? 'Inconnu',
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
              formatCurrency.format((commande['montant'] ?? 0) / 100),
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
                    // CORRECTION: Vérifier que items est une liste avant d'itérer dessus
                    if (commande['items'] != null && commande['items'] is List)
                      ...(commande['items'] as List).map<Widget>((item) {
                        // S'assurer que item est un Map
                        if (item is! Map) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['quantite'] ?? 1}x ${item['nom'] ?? 'Article'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                formatCurrency.format(
                                  ((item['prix'] ?? 0) *
                                          (item['quantite'] ?? 1)) /
                                      100,
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
                            formatCurrency.format(
                              (commande['montant'] ?? 0) / 100,
                            ),
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
                    // Informations client
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations client',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  client['imageUrl'] ??
                                      'https://randomuser.me/api/portraits/lego/1.jpg',
                                ),
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${client['prenom'] ?? ''} ${client['nom'] ?? 'Client'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Commande #${commande['id'].toString().substring(0, 8)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (commande['status'] == 'En préparation')
                          ElevatedButton(
                            onPressed: () {
                              _updateCommandeStatus(commande['id'], 'Terminée');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a73e8),
                            ),
                            child: const Text('Marquer comme terminée'),
                          )
                        else if (commande['status'] == 'Terminée')
                          ElevatedButton(
                            onPressed: () {
                              _updateCommandeStatus(
                                commande['id'],
                                'En préparation',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                            ),
                            child: const Text('Remettre en préparation'),
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

// Classe pour la recherche
class CommandeSearchDelegate extends SearchDelegate<String> {
  final _CommandesPageState _parentState;

  CommandeSearchDelegate(this._parentState);

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
    _parentState._searchQuery = query;
    return Container(); // On ferme immédiatement
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Recherchez par nom de client ou ID de commande'),
      );
    }

    final suggestions =
        _parentState._allCommandes.where((commande) {
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

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final commande = suggestions[index];
        final client = commande['client'] as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              client['imageUrl'] ??
                  'https://randomuser.me/api/portraits/lego/1.jpg',
            ),
          ),
          title: Text('${client['prenom']} ${client['nom']}'),
          subtitle: Text(
            'Commande #${commande['id'].toString().substring(0, 8)}',
          ),
          onTap: () {
            _parentState._searchQuery = query;
            close(context, query);
          },
        );
      },
    );
  }
}

// Page pour créer une nouvelle commande
class NouvelleCommandePage extends StatefulWidget {
  const NouvelleCommandePage({Key? key}) : super(key: key);

  @override
  _NouvelleCommandePageState createState() => _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends State<NouvelleCommandePage> {
  final _formKey = GlobalKey<FormState>();
  final CommandeService _commandeService = CommandeService();

  // Contrôleurs pour les champs
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  // Liste des articles dans la commande
  List<Map<String, dynamic>> _items = [];

  // Article temporaire en cours d'ajout
  String _nouveauNomArticle = '';
  int _nouvelleQuantite = 1;
  int _nouveauPrix = 0;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  void _ajouterArticle() {
    if (_nouveauNomArticle.isNotEmpty && _nouveauPrix > 0) {
      setState(() {
        _items.add({
          'nom': _nouveauNomArticle,
          'quantite': _nouvelleQuantite,
          'prix': _nouveauPrix,
        });
        // Réinitialiser pour le prochain article
        _nouveauNomArticle = '';
        _nouvelleQuantite = 1;
        _nouveauPrix = 0;
      });
    }
  }

  void _supprimerArticle(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  int get _montantTotal {
    int total = 0;
    for (var item in _items) {
      total += (item['prix'] * item['quantite'] * 100) as int;
    }
    return total;
  }

  Future<void> _soumettreCommande() async {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      try {
        final now = DateTime.now();

        final commandeData = {
          'client': {
            'nom': _nomController.text,
            'prenom': _prenomController.text,
            'imageUrl':
                'https://randomuser.me/api/portraits/lego/1.jpg', // Image par défaut
          },
          'date': Timestamp.now(),
          'montant': _montantTotal,
          'status': 'En préparation',
          'heure': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          'items': _items,
        };

        await _commandeService.creerNouvelleCommande(commandeData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande créée avec succès')),
          );
          Navigator.pop(context); // Retour à la liste
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } else if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un article à la commande'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Commande'),
        backgroundColor: const Color(0xFF1a73e8),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations client
            const Text(
              'Informations du client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 24),

            // Articles de la commande
            const Text(
              'Articles de la commande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Liste des articles ajoutés
            if (_items.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['nom']),
                      subtitle: Text(
                        '${item['quantite']}x à ${formatCurrency.format(item['prix'] / 100)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _supprimerArticle(index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Formulaire pour ajouter un article
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajouter un article',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'article',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _nouveauNomArticle = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Quantité',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: '1',
                            onChanged: (value) {
                              _nouvelleQuantite = int.tryParse(value) ?? 1;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Prix (FCFA)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _nouveauPrix =
                                  (double.tryParse(value) ?? 0 * 100).toInt();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        onPressed: _ajouterArticle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a73e8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Total
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                      formatCurrency.format(_montantTotal / 100),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a73e8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de soumission
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _soumettreCommande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a73e8),
                ),
                child: const Text(
                  'Créer la commande',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
