import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Jour';
  DateTime _selectedDate = DateTime.now();
  final List<String> _periods = ['Jour', 'Semaine', 'Mois'];
  bool _isLoading = true;

  // Sales data
  List<SalesData> _salesData = [];
  List<ProductSalesData> _topProducts = [];
  double _totalRevenue = 0;
  double _averageOrderValue = 0;
  int _totalOrders = 0;

  // Sales by hour for heatmap
  Map<int, double> _salesByHour = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Format currency in FCFA
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    );
    return formatter.format(amount);
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Change period
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });
    _fetchData();
  }

  // Change date
  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    _fetchData();
  }

  // Get date range based on selected period
  DateTimeRange _getDateRange() {
    final DateTime end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    DateTime start;

    switch (_selectedPeriod) {
      case 'Jour':
        start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        break;
      case 'Semaine':
        // Calculate start of week (Monday)
        start = end.subtract(Duration(days: end.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'Mois':
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        break;
      default:
        start = end;
    }

    return DateTimeRange(start: start, end: end);
  }

  // Fetch data from Firebase
  Future<void> _fetchData() async {
    try {
      final DateTimeRange range = _getDateRange();

      // In a real app, this would be a Firebase query
      // For this demo, we'll use sample data
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      // Generate sample data based on the selected period
      _generateSampleData(range);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données')),
      );
    }
  }

  // Generate sample data for demo
  void _generateSampleData(DateTimeRange range) {
    _salesData = [];
    _topProducts = [];
    _salesByHour = {};

    // Generate sales data
    final int daysDifference = range.end.difference(range.start).inDays + 1;

    double total = 0;
    int orders = 0;

    // Daily data
    for (int i = 0; i < daysDifference; i++) {
      final date = range.start.add(Duration(days: i));
      final double amount =
          15000 +
          (date.day % 3) * 5000 +
          (date.weekday == 6 || date.weekday == 7 ? 10000 : 0);
      final int dayOrders = 5 + (date.weekday % 3) * 2;

      _salesData.add(SalesData(date, amount, dayOrders));
      total += amount;
      orders += dayOrders;
    }

    // Top products
    final products = [
      ProductSalesData("Boisson Bissap", 120, 500),
      ProductSalesData("Riz au gras", 85, 1500),
      ProductSalesData("Poulet braisé", 60, 2000),
      ProductSalesData("Alloco", 95, 800),
      ProductSalesData("Riz cantonais", 65, 1200),
    ];
    _topProducts = List.from(products)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    // Sales by hour
    for (int hour = 8; hour <= 22; hour++) {
      double hourlyAmount = 0;

      // Peaks at lunch and dinner times
      if (hour >= 12 && hour <= 14) {
        hourlyAmount = 25000 + (hour - 11) * 5000;
      } else if (hour >= 18 && hour <= 21) {
        hourlyAmount = 30000 + (hour - 17) * 6000;
      } else {
        hourlyAmount = 8000 + (hour % 4) * 2000;
      }

      _salesByHour[hour] = hourlyAmount;
    }

    // Calculate metrics
    _totalRevenue = total;
    _totalOrders = orders;
    _averageOrderValue = orders > 0 ? total / orders : 0;
  }

  // Generate PDF report
  Future<void> _generateReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Rapport de ventes - ${_formatDate(_selectedDate)}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Période: $_selectedPeriod',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total des ventes: ${_formatCurrency(_totalRevenue)}'),
              pw.Text('Nombre de commandes: $_totalOrders'),
              pw.Text(
                'Valeur moyenne par commande: ${_formatCurrency(_averageOrderValue)}',
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Produits les plus vendus',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Produit',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Quantité',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Prix unitaire',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ..._topProducts
                      .map(
                        (product) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(product.name),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('${product.quantity}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                '${_formatCurrency(product.price)}',
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/rapport_ventes_${_formatDate(_selectedDate)}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'rapport_ventes_${_formatDate(_selectedDate)}.pdf',
    );
  }

  // Export to CSV
  Future<void> _exportToCsv() async {
    final StringBuffer csvContent = StringBuffer();

    // Headers
    csvContent.writeln('Date,Montant,Commandes');

    // Sales data
    for (final sale in _salesData) {
      csvContent.writeln(
        '${_formatDate(sale.date)},${sale.amount},${sale.orders}',
      );
    }

    // Write to file
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/ventes_${_formatDate(_selectedDate)}.csv',
    );
    await file.writeAsString(csvContent.toString());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Exportation des données de vente pour ${_selectedPeriod.toLowerCase()} du ${_formatDate(_selectedDate)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques de vente'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter en PDF',
            onPressed: _generateReport,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Exporter en CSV',
            onPressed: _exportToCsv,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'Détails'),
            Tab(text: 'Produits'),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildDetailsTab(),
                  _buildProductsTab(),
                ],
              ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildSalesChart(),
          const SizedBox(height: 20),
          _buildHourlyHeatmap(),
        ],
      ),
    );
  }

  // Details Tab
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détail des ventes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Montant',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Commandes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ..._salesData
                          .map(
                            (sale) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(_formatDate(sale.date)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(_formatCurrency(sale.amount)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${sale.orders}'),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Products Tab
  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produits les plus vendus',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _buildProductChart(),
                  const SizedBox(height: 20),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Produit',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Qté',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Prix unitaire',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      ..._topProducts
                          .map(
                            (product) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(product.name),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${product.quantity}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(_formatCurrency(product.price)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _formatCurrency(
                                      product.price * product.quantity,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Period Selector Widget
  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Période:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _changePeriod(newValue);
                    }
                  },
                  items:
                      _periods.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text(_formatDate(_selectedDate)),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != _selectedDate) {
                      _changeDate(picked);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Summary Cards
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Chiffre d\'affaires',
            value: _formatCurrency(_totalRevenue),
            icon: Icons.monetization_on,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Commandes',
            value: '$_totalOrders',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Panier moyen',
            value: _formatCurrency(_averageOrderValue),
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // Summary Card
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sales Chart
  Widget _buildSalesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution des ventes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _salesData.length) {
                            final date = _salesData[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              NumberFormat.compact().format(value),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(_salesData.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          _salesData[index].amount,
                        );
                      }),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hourly Heatmap
  Widget _buildHourlyHeatmap() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des ventes par heure',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              child: Row(
                children:
                    _salesByHour.entries.map((entry) {
                      final hour = entry.key;
                      final amount = entry.value;
                      final maxAmount = _salesByHour.values.reduce(
                        (value, element) => value > element ? value : element,
                      );

                      // Calculate intensity for heatmap
                      final intensity = amount / maxAmount;

                      return Expanded(
                        child: Tooltip(
                          message: '${hour}h: ${_formatCurrency(amount)}',
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(intensity),
                                ),
                              ),
                              Text('${hour}h', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product Chart
  Widget _buildProductChart() {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toString());
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'Produit ${value.toInt() + 1}',
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups:
              _topProducts.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.quantity.toDouble(),
                      color: Colors.blue,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

// Data models
class SalesData {
  final DateTime date;
  final double amount;
  final int orders;

  SalesData(this.date, this.amount, this.orders);
}

class ProductSalesData {
  final String name;
  final int quantity;
  final double price;

  ProductSalesData(this.name, this.quantity, this.price);
}
