import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ItineraryCard extends StatelessWidget {
  final Map<String, dynamic> itinerary;
  final Function() onSelect;

  const ItineraryCard({
    Key? key,
    required this.itinerary,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = itinerary['name'] ?? 'Parcours';
    final activities = itinerary['activities'] as List<dynamic>? ?? [];
    final description = itinerary['description'] ?? '';
    final totalPrice = itinerary['totalPrice'] ?? '0';

    // Création du contenu Markdown
    String markdownContent = '**$name**\n\n';
    
    for (var activity in activities) {
      final time = activity['time'] ?? '';
      final activityName = activity['activity'] ?? '';
      final price = activity['price'] ?? '0';
      
      markdownContent += '• $time : $activityName (${price == '0' ? 'Gratuit' : '$price FCFA'})\n';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du contenu en Markdown pour conserver la mise en forme
            MarkdownBody(
              data: markdownContent,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                p: TextStyle(fontSize: 16),
                listBullet: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16),
                SizedBox(width: 5),
                Text('Total: $totalPrice FCFA', 
                     style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(description, 
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: onSelect,
              child: Text("Choisir ce parcours"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}