import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Découvrir le Bénin"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌍 Lieux Populaires
            const Text("Lieux populaires", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lieux')
                  .orderBy('popularite', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                
                final lieux = snapshot.data!.docs;
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lieux.length,
                    itemBuilder: (context, index) {
                      final data = lieux[index].data() as Map<String, dynamic>;
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context, 
                            '/lieu-details',
                            arguments: lieux[index].id,
                          );
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: Column(
                            children: [
                              // Image du lieu
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                    image: data['imagesBase64'] != null && 
                                           data['imagesBase64'].isNotEmpty
                                        ? DecorationImage(
                                            image: MemoryImage(
                                              base64Decode(data['imagesBase64'][0].split(',').last)
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: data['imagesBase64'] == null || 
                                         data['imagesBase64'].isEmpty
                                      ? const Center(
                                          child: Icon(Icons.photo, size: 50, color: Colors.grey))
                                      : null,
                                ),
                              ),
                              // Info du lieu
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['nom'] ?? 'Nom inconnu',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          data['popularite']?.toString() ?? '0',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 📊 Statistiques améliorées
            const Text("Statistiques", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Utilisation d'un StreamBuilder pour chaque statistique avec animation
            Row(
              children: [
                // Nombre de lieux
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('lieux').snapshots(),
                    builder: (context, snapshot) {
                      return AnimatedStatCard(
                        icon: Icons.place,
                        title: "Lieux",
                        value: snapshot.hasData ? snapshot.data!.docs.length.toString() : "--",
                        color: Colors.blue.shade100,
                        iconColor: Colors.blue.shade700,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Nombre d'événements
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('events').snapshots(),
                    builder: (context, snapshot) {
                      return AnimatedStatCard(
                        icon: Icons.event,
                        title: "Événements",
                        value: snapshot.hasData ? snapshot.data!.docs.length.toString() : "--",
                        color: Colors.green.shade100,
                        iconColor: Colors.green.shade700,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Nombre de partenaires
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('partenaires').snapshots(),
                    builder: (context, snapshot) {
                      return AnimatedStatCard(
                        icon: Icons.handshake,
                        title: "Partenaires",
                        value: snapshot.hasData ? snapshot.data!.docs.length.toString() : "--",
                        color: Colors.orange.shade100,
                        iconColor: Colors.orange.shade700,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🎯 Raccourcis fonctionnels
            const Text("Navigation rapide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                quickAccess(Icons.place, "Lieux", () => Navigator.pushNamed(context, '/lieux')),
                quickAccess(Icons.event, "Événements", () => Navigator.pushNamed(context, '/creatEvent')),
                quickAccess(Icons.handshake, "Partenaires", () => Navigator.pushNamed(context, '/partenaires')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 Widget raccourci
  Widget quickAccess(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color iconColor;

  const AnimatedStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.iconColor = Colors.blue,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 30, color: widget.iconColor),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}