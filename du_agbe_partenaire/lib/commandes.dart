import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({Key? key}) : super(key: key);

  @override
  _CommandesPageState createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final formatDate = DateFormat('dd/MM/yyyy HH:mm');
  
  // Filtres
  String _searchQuery = '';
  bool _showFilters = false;
  String _selectedStatus = 'Tous';
  String _selectedDate = 'Aujourd\'hui';
  
  // Liste des commandes fictives
  final List<Map<String, dynamic>> _allCommandes = [
    {
      'id': 'CMD-001',
      'client': 'Table 5',
      'date': DateTime.now().subtract(const Duration(minutes: 15)),
      'montant': 6850,
      'status': 'En préparation',
      'items': [
        {'nom': 'Steak frites', 'quantite': 2, 'prix': 1650},
        {'nom': 'Salade César', 'quantite': 1, 'prix': 1250},
        {'nom': 'Coca Cola', 'quantite': 3, 'prix': 380},
        {'nom': 'Tiramisu', 'quantite': 1, 'prix': 650},
      ]
    },
    {
      'id': 'CMD-002',
      'client': 'Table 3',
      'date': DateTime.now().subtract(const Duration(minutes: 30)),
      'montant': 5200,
      'status': 'En préparation',
      'items': [
        {'nom': 'Pizza Margherita', 'quantite': 1, 'prix': 1350},
        {'nom': 'Pâtes Carbonara', 'quantite': 1, 'prix': 1450},
        {'nom': 'Vin Rouge (verre)', 'quantite': 2, 'prix': 550},
        {'nom': 'Café', 'quantite': 2, 'prix': 180},
      ]
    },
    {
      'id': 'CMD-003',
      'client': 'Table 8',
      'date': DateTime.now().subtract(const Duration(hours: 1)),
      'montant': 9200,
      'status': 'Terminée',
      'items': [
        {'nom': 'Plateau de fruits de mer', 'quantite': 1, 'prix': 4500},
        {'nom': 'Salade verte', 'quantite': 1, 'prix': 850},
        {'nom': 'Bouteille Chablis', 'quantite': 1, 'prix': 3200},
        {'nom': 'Assortiment de desserts', 'quantite': 1, 'prix': 650},
      ]
    },
    {
      'id': 'CMD-004',
      'client': 'Table 2',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'montant': 4300,
      'status': 'Terminée',
      'items': [
        {'nom': 'Burger Maison', 'quantite': 1, 'prix': 1550},
        {'nom': 'Frites Maison', 'quantite': 1, 'prix': 450},
        {'nom': 'Bière pression', 'quantite': 2, 'prix': 580},
        {'nom': 'Crème brûlée', 'quantite': 1, 'prix': 550},
      ]
    },
    {
      'id': 'CMD-005',
      'client': 'Table 10',
      'date': DateTime.now().subtract(const Duration(minutes: 45)),
      'montant': 7600,
      'status': 'En préparation',
      'items': [
        {'nom': 'Entrecôte', 'quantite': 1, 'prix': 2300},
        {'nom': 'Gratin Dauphinois', 'quantite': 1, 'prix': 750},
        {'nom': 'Salade composée', 'quantite': 1, 'prix': 950},
        {'nom': 'Vin Rosé (bouteille)', 'quantite': 1, 'prix': 2450},
        {'nom': 'Crème glacée', 'quantite': 2, 'prix': 580},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filtrer les commandes selon le tab actif et les critères de recherche
  List<Map<String, dynamic>> get _filteredCommandes {
    List<Map<String, dynamic>> result = [];
    
    // D'abord filtrer par status selon le tab
    switch (_tabController.index) {
      case 0: // Toutes
        result = List.from(_allCommandes);
        break;
      case 1: // En préparation
        result = _allCommandes.where((cmd) => cmd['status'] == 'En préparation').toList();
        break;
      case 2: // Terminées
        result = _allCommandes.where((cmd) => cmd['status'] == 'Terminée').toList();
        break;
    }
    
    // Ensuite appliquer les filtres de recherche
    if (_searchQuery.isNotEmpty) {
      result = result.where((cmd) => 
        cmd['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        cmd['client'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Trier par date (plus récent en premier)
    result.sort((a, b) => b['date'].compareTo(a['date']));
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Container(
              color: const Color(0xFF1a73e8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Commandes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // Afficher barre de recherche
                      showSearch(
                        context: context,
                        delegate: CommandeSearchDelegate(this),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Filtres (visible seulement quand activé)
            if (_showFilters)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                              labelText: 'Statut',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            value: _selectedStatus,
                            items: ['Tous', 'En préparation', 'Terminée']
                                .map((String status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            value: _selectedDate,
                            items: ['Aujourd\'hui', 'Cette semaine', 'Ce mois-ci']
                                .map((String date) => DropdownMenuItem(
                                      value: date,
                                      child: Text(date),
                                    ))
                                .toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDate = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Réinitialiser'),
                          onPressed: () {
                            setState(() {
                              _selectedStatus = 'Tous';
                              _selectedDate = 'Aujourd\'hui';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1a73e8),
                          ),
                          child: const Text('Appliquer'),
                          onPressed: () {
                            setState(() {
                              _showFilters = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // TabBar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1a73e8),
                unselectedLabelColor: const Color(0xFF5F6368),
                indicatorColor: const Color(0xFF1a73e8),
                tabs: [
                  Tab(
                    text: 'Toutes (${_allCommandes.length})',
                  ),
                  Tab(
                    text: 'En préparation (${_allCommandes.where((cmd) => cmd['status'] == 'En préparation').length})',
                  ),
                  Tab(
                    text: 'Terminées (${_allCommandes.where((cmd) => cmd['status'] == 'Terminée').length})',
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pour chaque tab, afficher la liste filtrée
                  _buildCommandesList(),
                  _buildCommandesList(),
                  _buildCommandesList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1a73e8),
        child: const Icon(Icons.add),
        onPressed: () {
          // Ajouter une nouvelle commande
          _showNouvelleCommandeDialog(context);
        },
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
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Color(0xFFDADCE0),
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'Aucune commande disponible'
                  : _tabController.index == 1
                      ? 'Aucune commande en préparation'
                      : 'Aucune commande terminée',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5F6368),
              ),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              '${commande['id']} - ${commande['client']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF202124),
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  formatDate.format(commande['date']),
                  style: const TextStyle(
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: commande['status'] == 'En préparation'
                        ? const Color(0xFFFEF7E0)
                        : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    commande['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: commande['status'] == 'En préparation'
                          ? const Color(0xFFEE8100)
                          : const Color(0xFF137333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              formatCurrency.format(commande['montant'] / 100),
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
                    ...commande['items'].map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['quantite']}x ${item['nom']}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              formatCurrency.format(item['prix'] * item['quantite'] / 100),
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    // Actions
                    Row(
                      
                      children: [
                        if (commande['status'] == 'En préparation')
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marquer comme terminée'),
                            onPressed: () {
                             
                              setState(() {
                                int index = _allCommandes.indexOf(commande);
                                _allCommandes[index]['status'] = 'Terminée';
                              });
                            },
                          ),
                        
                        TextButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Imprimer'),
                          onPressed: () {
                        
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impression en cours...')),
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

  void _showNouvelleCommandeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle commande'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

// Delegate pour la recherche
class CommandeSearchDelegate extends SearchDelegate<String> {
  final _CommandesPageState _state;

  CommandeSearchDelegate(this._state);

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
    _state.setState(() {
      _state._searchQuery = query;
    });
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _state._allCommandes
        .where((commande) =>
            commande['id'].toLowerCase().contains(query.toLowerCase()) ||
            commande['client'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final commande = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.receipt),
          title: Text('${commande['id']} - ${commande['client']}'),
          subtitle: Text(_state.formatCurrency.format(commande['montant'] / 100)),
          onTap: () {
            _state.setState(() {
              _state._searchQuery = commande['id'];
            });
            close(context, commande['id']);
          },
        );
      },
    );
  }
}