import 'package:flutter/material.dart';

class ClientsPage extends StatelessWidget {
  final String restaurantName;
  final List<Client> clients;

  ClientsPage(this.restaurantName, this.clients);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clients de $restaurantName"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blueAccent),
                ),
                title: Text(client.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🛍️ ${client.orders} commandes  |  💰 ${client.totalSpent} FCFA"),
                    Text("📅 Dernière visite : ${client.lastVisit}"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Client {
  final String name;
  final int orders;
  final int totalSpent;
  final String lastVisit;

  Client(this.name, this.orders, this.totalSpent, this.lastVisit);
}

// Exemple d’utilisation
void main() {
  runApp(MaterialApp(
    home: ClientsPage("La Détente", [
      Client("Jean Dupont", 8, 45000, "14 avril"),
      Client("Aïcha Traoré", 3, 13500, "10 avril"),
      Client("Carlos Gomez", 5, 23000, "12 avril"),
    ]),
  ));
}
