import 'package:du_agbe_pro/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class Chiffre extends StatelessWidget {
  const Chiffre({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaJournée',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1a73e8),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const SalesDetailPage(),
    );
  }
}

class SalesDetailPage extends StatefulWidget {
  const SalesDetailPage({Key? key}) : super(key: key);

  @override
  _SalesDetailPageState createState() => _SalesDetailPageState();
}

class _SalesDetailPageState extends State<SalesDetailPage> {
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  int _selectedPeriodIndex = 0;
  final List<String> _periods = ['Jour', 'Semaine', 'Mois', 'Année'];

  // Données fictives pour chaque période
  final Map<String, Map<String, dynamic>> _salesData = {
    'Jour': {
      'total': 125000,
      'percentage': 12,
      'hourlyData': [
        {'hour': '8h', 'sales': 8000},
        {'hour': '10h', 'sales': 12000},
        {'hour': '12h', 'sales': 26000},
        {'hour': '14h', 'sales': 18000},
        {'hour': '16h', 'sales': 14000},
        {'hour': '18h', 'sales': 22000},
        {'hour': '20h', 'sales': 19000},
        {'hour': '22h', 'sales': 6000},
      ],
      'categories': [
        {'name': 'Plats principaux', 'amount': 65500},
        {'name': 'Boissons', 'amount': 32500},
        {'name': 'Desserts', 'amount': 18750},
        {'name': 'Entrées', 'amount': 8250},
      ]
    },
    'Semaine': {
      'total': 825000,
      'percentage': 8,
      'hourlyData': [
        {'hour': 'Lun', 'sales': 125000},
        {'hour': 'Mar', 'sales': 110000},
        {'hour': 'Mer', 'sales': 105000},
        {'hour': 'Jeu', 'sales': 120000},
        {'hour': 'Ven', 'sales': 180000},
        {'hour': 'Sam', 'sales': 135000},
        {'hour': 'Dim', 'sales': 50000},
      ],
      'categories': [
        {'name': 'Plats principaux', 'amount': 430000},
        {'name': 'Boissons', 'amount': 210000},
        {'name': 'Desserts', 'amount': 125000},
        {'name': 'Entrées', 'amount': 60000},
      ]
    },
    'Mois': {
      'total': 3200000,
      'percentage': 5,
      'hourlyData': [
        {'hour': 'S1', 'sales': 800000},
        {'hour': 'S2', 'sales': 750000},
        {'hour': 'S3', 'sales': 850000},
        {'hour': 'S4', 'sales': 800000},
      ],
      'categories': [
        {'name': 'Plats principaux', 'amount': 1700000},
        {'name': 'Boissons', 'amount': 820000},
        {'name': 'Desserts', 'amount': 450000},
        {'name': 'Entrées', 'amount': 230000},
      ]
    },
    'Année': {
      'total': 38500000,
      'percentage': 15,
      'hourlyData': [
        {'hour': 'Jan', 'sales': 2800000},
        {'hour': 'Fév', 'sales': 2600000},
        {'hour': 'Mar', 'sales': 3100000},
        {'hour': 'Avr', 'sales': 3000000},
        {'hour': 'Mai', 'sales': 3400000},
        {'hour': 'Jun', 'sales': 3600000},
        {'hour': 'Jul', 'sales': 3900000},
        {'hour': 'Aoû', 'sales': 4200000},
        {'hour': 'Sep', 'sales': 3500000},
        {'hour': 'Oct', 'sales': 3200000},
        {'hour': 'Nov', 'sales': 2800000},
        {'hour': 'Déc', 'sales': 2400000},
      ],
      'categories': [
        {'name': 'Plats principaux', 'amount': 20000000},
        {'name': 'Boissons', 'amount': 10500000},
        {'name': 'Desserts', 'amount': 5000000},
        {'name': 'Entrées', 'amount': 3000000},
      ]
    },
  };

  // Calcul du maximum pour le graphique
  double _calculateMaxY(List<dynamic> data) {
    if (data.isEmpty) return 0;
    double maxSale = 0;
    for (var item in data) {
      double value = (item['sales'] as num).toDouble();
      if (value > maxSale) {
        maxSale = value;
      }
    }
    return maxSale * 1.2; // 20% de marge au-dessus du max
  }

  @override
  Widget build(BuildContext context) {
    final currentPeriod = _periods[_selectedPeriodIndex];
    final currentData = _salesData[currentPeriod]!;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                 Navigator.push(context, MaterialPageRoute(builder: (context)=> DashboardPage()) ); 
                }),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 13 ),
                  const Text(
                    'Détail du Chiffre d\'affaires',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () {
                     
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // Panneau principal - Chiffre d'affaires
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatCurrency.format(currentData['total'] / 100),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '+${currentData['percentage']}%',
                                    style: const TextStyle(
                                      color: Color(0xFF137333),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chiffre d\'affaires du ${currentPeriod.toLowerCase()}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'par rapport à la période précédente',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Onglets de période
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: List.generate(
                            _periods.length,
                            (index) => Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPeriodIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedPeriodIndex == index
                                        ? Theme.of(context).primaryColor
                                        : null,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _periods[index],
                                    style: TextStyle(
                                      color: _selectedPeriodIndex == index
                                          ? Colors.white
                                          : const Color(0xFF5F6368),
                                      fontWeight: _selectedPeriodIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Graphique
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentPeriod == 'Jour'
                                  ? 'Répartition horaire'
                                  : currentPeriod == 'Semaine'
                                      ? 'Répartition journalière'
                                      : currentPeriod == 'Mois'
                                          ? 'Répartition hebdomadaire'
                                          : 'Répartition mensuelle',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _calculateMaxY(currentData['hourlyData']),
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          final index = value.toInt();
                                          final hourlyData = currentData['hourlyData'] as List;
                                          if (index >= 0 && index < hourlyData.length) {
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                hourlyData[index]['hour'],
                                                style: const TextStyle(
                                                  color: Color(0xFF5F6368),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SideTitleWidget(
                                            axisSide: AxisSide.bottom,
                                            child: Text(''),
                                          );
                                        },
                                        reservedSize: 30,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _createBarGroups(currentData['hourlyData'], context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Détails par catégorie
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Détail par catégorie',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...(currentData['categories'] as List).map<Widget>((category) {
                              return Column(
                                children: [
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          category['name'],
                                          style: const TextStyle(
                                            color: Color(0xFF202124),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          formatCurrency.format(category['amount'] / 100),
                                          style: const TextStyle(
                                            color: Color(0xFF202124),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          _showPlusMenu(context);
        },
      ),
    );
  }

  // Méthode auxiliaire pour créer les barGroups
  List<BarChartGroupData> _createBarGroups(List<dynamic> data, BuildContext context) {
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (item['sales'] as num).toDouble(),
            color: i == 2 || i == 5 || i == 6
                ? Theme.of(context).primaryColor
                : const Color(0xFFC6DAFC),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          )
        ],
      ));
    }
    return groups;
  }

  void _showPlusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.compare_arrows),
                title: const Text('Comparer périodes'),
                onTap: () {
                  Navigator.pop(context);
                  _showComparePeriods(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Exporter en PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager le rapport'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres d\'affichage'),
                onTap: () {
                  Navigator.pop(context);
                  _showDisplaySettings(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComparePeriods(BuildContext context) {
    // Implémentation de la fonctionnalité de comparaison
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparaison des périodes sélectionnée')),
    );
  }

  void _exportToPDF() {
    // Implémentation de l'exportation PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportation en PDF en cours...')),
    );
  }

  void _shareReport() {
    // Implémentation du partage de rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport partagé')),
    );
  }

  void _showDisplaySettings(BuildContext context) {
    // Implémentation des paramètres d'affichage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres d\'affichage ouverts')),
    );
  }
}