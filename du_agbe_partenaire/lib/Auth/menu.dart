import 'package:du_agbe_pro/pageAjoutmenu.dart';
import 'package:flutter/material.dart';



class RestaurantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Restaurant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: RestaurantHomePage(),
    );
  }
}

class RestaurantHomePage extends StatefulWidget {
  @override
  _RestaurantHomePageState createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _selectedIndex = 1; // Index pour la navigation bottom bar
  String _selectedCategory = 'Tous'; // Catégorie sélectionnée
  
  // Liste des catégories disponibles
  final List<String> _categories = [
    'Tous', 
    'Entrées', 
    'Plats', 
    'Pâtes', 
    'Pizzas', 
    'Desserts', 
    'Boissons'
  ];

  // Map pour associer chaque catégorie à ses plats
  final Map<String, List<MenuItem>> _menuItems = {
    'Tous': [], // Sera rempli avec tous les plats
    'Entrées': [
      MenuItem(
        name: 'Salade César',
        description: 'Salade romaine, poulet grillé, croûtons, parmesan, sauce César maison',
        price: 12.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Carpaccio de Bœuf',
        description: 'Fines tranches de bœuf cru, huile d\'olive, parmesan, roquette',
        price: 13.90,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
    'Plats': [
      MenuItem(
        name: 'Burger Gourmet',
        description: 'Steak de bœuf, cheddar, bacon, oignons caramélisés, sauce barbecue',
        price: 15.90,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Filet de Saumon',
        description: 'Filet de saumon grillé, risotto aux légumes, sauce citron',
        price: 18.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
    'Pâtes': [
      MenuItem(
        name: 'Pâtes Carbonara',
        description: 'Spaghetti, pancetta, jaune d\'œuf, parmesan, poivre noir',
        price: 14.90,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Penne Arrabiata',
        description: 'Penne, sauce tomate piquante, ail, persil',
        price: 13.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
    'Pizzas': [
      MenuItem(
        name: 'Pizza Margherita',
        description: 'Sauce tomate, mozzarella, basilic frais',
        price: 11.00,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Pizza 4 Fromages',
        description: 'Sauce tomate, mozzarella, gorgonzola, chèvre, parmesan',
        price: 14.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
    'Desserts': [
      MenuItem(
        name: 'Tiramisu',
        description: 'Biscuits, café, mascarpone, cacao',
        price: 7.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Crème Brûlée',
        description: 'Crème vanille, caramel croustillant',
        price: 6.90,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
    'Boissons': [
      MenuItem(
        name: 'Vin Rouge (verre)',
        description: 'Bordeaux, Côtes du Rhône ou Bourgogne',
        price: 5.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
      MenuItem(
        name: 'Eau Minérale',
        description: 'Plate ou pétillante (75cl)',
        price: 3.50,
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    // Remplir la catégorie "Tous" avec tous les plats
    _menuItems['Tous'] = [];
    _menuItems.forEach((category, items) {
      if (category != 'Tous') {
        _menuItems['Tous']!.addAll(items);
      }
    });
  }

  // Changement de l'index de la bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Changement de la catégorie sélectionnée
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'La Bonne Table',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un plat...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
          
          // Liste des catégories
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return GestureDetector(
                  onTap: () => _onCategorySelected(category),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5.0),
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Liste des plats
          Expanded(
            child: _buildMenuList(),
          ),
        ],
      ),
   floatingActionButton: FloatingActionButton(onPressed: (){
    setState(() {
      Navigator.push(context, MaterialPageRoute(builder: (context)=>AddMenuPage()));
    });
   },
   backgroundColor:const Color.fromARGB(255, 53, 161, 249), 
   child: Icon(Icons.add)));
    
  }

  // Construction de la liste des plats en fonction de la catégorie sélectionnée
  Widget _buildMenuList() {
    final items = _menuItems[_selectedCategory] ?? [];
    
    if (items.isEmpty) {
      return Center(child: Text('Aucun plat disponible dans cette catégorie'));
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              // Image du plat
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  bottomLeft: Radius.circular(10.0),
                ),
                child: Image.network(
                  item.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  // En cas d'erreur, afficher une image par défaut
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(Icons.restaurant, color: Colors.grey[500]),
                    );
                  },
                ),
              ),
              
              // Détails du plat
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        '${item.price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Classe pour les éléments du menu
class MenuItem {
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}