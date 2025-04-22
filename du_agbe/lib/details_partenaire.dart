import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> partner;

  const PartnerDetailsPage({Key? key, required this.partner}) : super(key: key);

  @override
  State<PartnerDetailsPage> createState() => _PartnerDetailsPageState();
}

class _PartnerDetailsPageState extends State<PartnerDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> _menusByCategory = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMenus();
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

  Widget _buildInfoRow(IconData icon, String text, {String? phone, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhone && phone != null)
            IconButton(
              icon: Icon(icon, size: 24, color: Colors.green),
              onPressed: () => _launchWhatsApp(phone),
            )
          else
            Icon(icon, size: 24, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partner['name'] ?? 'Détails du lieu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerHeader(),
                  const SizedBox(height: 20),
                  
                  // Section Informations dans une Card
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
                          Text(
                            widget.partner['name'] ?? 'Lieu partenaire',
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          if (widget.partner['category'] != null)
                            _buildInfoRow(
                              Icons.category, 
                              widget.partner['category'],
                            ),
                          
                          if (widget.partner['contact'] != null)
                            _buildInfoRow(
                              Icons.phone, 
                              widget.partner['contact'],
                              phone: widget.partner['contact'],
                              isPhone: true,
                            ),
                          
                          const SizedBox(height: 10),
                          
                          if (widget.partner['description'] != null)
                            Text(
                              widget.partner['description'],
                              style: const TextStyle(fontSize: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildMenusSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPartnerHeader() {
    return Hero(
      tag: 'partner-${widget.partner['id']}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.partner['imageUrl']?.isNotEmpty == true
            ? Image.network(
                widget.partner['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.business, size: 50, color: Colors.grey),
    );
  }

  Widget _buildMenusSection() {
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_menusByCategory.isEmpty) {
      return const Center(child: Text('Aucun menu disponible'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nos Menus',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._menusByCategory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: menu['imageUrl']?.isNotEmpty == true
                  ? Image.network(
                      menu['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildMenuPlaceholder(),
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
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${menu['price']} FCFA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.restaurant, color: Colors.grey)),
    );
  }
}