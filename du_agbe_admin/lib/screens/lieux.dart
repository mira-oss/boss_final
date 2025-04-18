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

  final List<String> types = ['Tous', 'Restaurant', 'Bar', 'Café', 'Hôtel', 'Plage'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorer les Lieux"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/ajout-lieu'); // ⚠️ à créer
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔍 Recherche
            TextField(
              onChanged: (value) => setState(() => _search = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Rechercher un lieu...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🧭 Filtres
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: types.map((type) {
                  final selected = _typeFiltre == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => setState(() => _typeFiltre = type),
                      selectedColor: Colors.deepOrange,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
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
                      final data = lieux[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(data['image'], width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          title: Text(data['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Type : ${data['type']}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/details-lieu',
                              arguments: data, // ou doc.id pour fetch ensuite
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