import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Lieux extends StatefulWidget {
  const Lieux({super.key});

  @override
  State<Lieux> createState() => _LieuxPageState();
}

class _LieuxPageState extends State<Lieux> {
  String _search = '';
  String _typeFiltre = 'Tous';
  bool _trierParPopularite = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> types = ['Tous', 'Restaurant', 'Bar', 'Café', 'Hôtel', 'Plage'];

  // Fonction pour supprimer un lieu
  Future<void> _supprimerLieu(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('lieux').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lieu supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  // Fonction pour confirmer la suppression
  void _confirmerSuppression(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce lieu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _supprimerLieu(docId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorer les Lieux"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/ajout-lieu');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Barre de recherche dynamique
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _search = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Rechercher un lieu...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _search = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🧭 Filtres avec sélection en bleu
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: types.map((type) {
                  final selected = _typeFiltre == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => setState(() => _typeFiltre = type),
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // 🔽 Trier
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Trier par :", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<bool>(
                  value: _trierParPopularite,
                  items: const [
                    DropdownMenuItem(value: true, child: Text("Popularité")),
                    DropdownMenuItem(value: false, child: Text("Nom")),
                  ],
                  onChanged: (val) => setState(() => _trierParPopularite = val!),
                )
              ],
            ),

            const SizedBox(height: 16),

            // 📍 Liste des lieux
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lieux')
                    .orderBy(_trierParPopularite ? 'popularite' : 'nom', descending: _trierParPopularite)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final lieux = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nom = data['nom'].toString().toLowerCase();
                    final type = data['type'];
                    final matchRecherche = _search.isEmpty || nom.contains(_search);
                    final matchType = _typeFiltre == 'Tous' || type == _typeFiltre;
                    return matchRecherche && matchType;
                  }).toList();

                  if (lieux.isEmpty) {
                    return const Center(child: Text("Aucun lieu trouvé."));
                  }

                  return ListView.builder(
                    itemCount: lieux.length,
                    itemBuilder: (context, index) {
                      final doc = lieux[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['image'], 
                              width: 60, 
                              height: 60, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.place, size: 40),
                            ),
                          ),
                          title: Text(data['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Type : ${data['type']}"),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'modifier',
                                child: Text('Modifier'),
                              ),
                              const PopupMenuItem(
                                value: 'supprimer',
                                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'modifier') {
                                Navigator.pushNamed(
                                  context, 
                                  '/ajout-lieu', 
                                  arguments: {'id': docId, ...data},
                                );
                              } else if (value == 'supprimer') {
                                _confirmerSuppression(docId);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/details-lieu',
                              arguments: {'id': docId, ...data},
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}