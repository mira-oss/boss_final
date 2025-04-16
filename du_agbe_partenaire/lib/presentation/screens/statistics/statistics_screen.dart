// lib/presentation/screens/statistics/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/screens/statistics/charts_widgets.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'weekly'; // daily, weekly, monthly
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStatistics() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.fetchOrderStatistics(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;

      // Mettre à jour les dates en fonction de la période sélectionnée
      _endDate = DateTime.now();
      switch (period) {
        case 'daily':
          _startDate = DateTime.now().subtract(Duration(days: 1));
          break;
        case 'weekly':
          _startDate = DateTime.now().subtract(Duration(days: 7));
          break;
        case 'monthly':
          _startDate = DateTime.now().subtract(Duration(days: 30));
          break;
      }
    });

    _loadStatistics();
  }

  void _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });

      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Statistiques"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Ventes"),
            Tab(text: "Produits"),
            Tab(text: "Clients"),
          ],
          labelColor: ColorConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: ColorConstants.primaryColor,
        ),
      ),
      body: Column(
        children: [
          // Sélecteur de période
          _buildPeriodSelector(),

          // TabBarView pour le contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildProductsTab(),
                _buildCustomersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              final totalSales = provider.totalSales ?? 0.0;
              final salesChange = provider.salesChange ?? 0.0;
              final totalOrders = provider.totalOrders ?? 0;
              final ordersChange = provider.ordersChange ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: "Total des ventes",
                      value: currencyFormat.format(totalSales),
                      change: salesChange,
                      icon: Icons.euro_rounded,
                      isLoading: provider.isLoading,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: "Nombre de commandes",
                      value: totalOrders.toString(),
                      change: ordersChange,
                      icon: Icons.shopping_cart,
                      isLoading: provider.isLoading,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Période :", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip("Jour", "daily"),
                      SizedBox(width: 8),
                      _buildPeriodChip("Semaine", "weekly"),
                      SizedBox(width: 8),
                      _buildPeriodChip("Mois", "monthly"),
                      SizedBox(width: 8),
                      _buildPeriodChip(
                        _selectedPeriod == 'custom'
                            ? "${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}"
                            : "Personnalisé",
                        "custom",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedPeriod == value,
      onSelected: (_) {
        if (value == 'custom') {
          _selectCustomDateRange();
        } else {
          _onPeriodChanged(value);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: ColorConstants.accentColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color:
            _selectedPeriod == value
                ? ColorConstants.accentColor
                : Colors.black,
        fontWeight:
            _selectedPeriod == value ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: ColorConstants.accentColor,
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required double change,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 8),
            isLoading
                ? SizedBox(height: 20, child: LoadingIndicator(size: 14))
                : Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
            SizedBox(height: 4),
            isLoading
                ? SizedBox(height: 16)
                : Row(
                  children: [
                    Icon(
                      change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: change >= 0 ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 2),
                    Text(
                      "${change.abs().toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: change >= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      " par rapport à la période précédente",
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: LoadingIndicator());
        }

        // Vérifier si des données sont disponibles
        if (provider.salesData.isEmpty) {
          return _buildEmptyDataView(
            message: "Aucune donnée de vente disponible pour cette période",
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Graphique des ventes
              _buildSectionTitle("Évolution des ventes"),
              SizedBox(height: 8),
              SalesLineChart(salesData: provider.salesData),
              SizedBox(height: 24),

              // Répartition par méthode de paiement
              _buildSectionTitle("Répartition par méthode de paiement"),
              SizedBox(height: 8),
              PaymentMethodPieChart(
                paymentMethodData: provider.paymentMethodData,
              ),
              SizedBox(height: 24),

              // Ventes par heure
              _buildSectionTitle("Répartition des ventes par heure"),
              SizedBox(height: 8),
              SalesByHourBarChart(hourlyData: provider.hourlyData),
              SizedBox(height: 24),

              // Tableau des ventes par jour
              _buildSectionTitle("Détail des ventes par jour"),
              SizedBox(height: 8),
              _buildSalesByDayTable(provider.salesData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: LoadingIndicator());
        }

        // Vérifier si des données sont disponibles
        if (provider.productData.isEmpty) {
          return _buildEmptyDataView(
            message: "Aucune donnée de produit disponible pour cette période",
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top des produits les plus vendus
              _buildSectionTitle("Produits les plus vendus"),
              SizedBox(height: 8),
              TopProductsBarChart(productData: provider.productData),
              SizedBox(height: 24),

              // Répartition des ventes par catégorie
              _buildSectionTitle("Répartition des ventes par catégorie"),
              SizedBox(height: 8),
              CategoryPieChart(categoryData: provider.categoryData),
              SizedBox(height: 24),

              // Tableau des produits
              _buildSectionTitle("Détail des ventes par produit"),
              SizedBox(height: 8),
              _buildProductsTable(provider.productData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: LoadingIndicator());
        }

        // Vérifier si des données sont disponibles
        if (provider.customerData.isEmpty) {
          return _buildEmptyDataView(
            message: "Aucune donnée client disponible pour cette période",
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nouveaux clients vs clients réguliers
              _buildSectionTitle("Nouveaux clients vs clients réguliers"),
              SizedBox(height: 8),
              CustomerTypePieChart(customerTypeData: provider.customerTypeData),
              SizedBox(height: 24),

              // Heures d'affluence des clients
              _buildSectionTitle("Heures d'affluence"),
              SizedBox(height: 8),
              CustomerTrafficBarChart(trafficData: provider.trafficData),
              SizedBox(height: 24),

              // Top des clients
              _buildSectionTitle("Top clients"),
              SizedBox(height: 8),
              _buildTopCustomersTable(provider.customerData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ColorConstants.primaryColor,
      ),
    );
  }

  Widget _buildEmptyDataView({required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          OutlinedButton(
            onPressed: _selectCustomDateRange,
            child: Text("Changer de période"),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesByDayTable(List<Map<String, dynamic>> salesData) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Commandes')),
            DataColumn(label: Text('Ventes')),
            DataColumn(label: Text('Panier moyen')),
          ],
          rows:
              salesData.map((day) {
                final date = DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.parse(day['date']));
                final orders = day['orders'].toString();
                final sales = currencyFormat.format(day['sales']);
                final avgOrder = currencyFormat.format(
                  day['orders'] > 0 ? day['sales'] / day['orders'] : 0,
                );

                return DataRow(
                  cells: [
                    DataCell(Text(date)),
                    DataCell(Text(orders)),
                    DataCell(Text(sales)),
                    DataCell(Text(avgOrder)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsTable(List<Map<String, dynamic>> productData) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Produit')),
            DataColumn(label: Text('Catégorie')),
            DataColumn(label: Text('Quantité')),
            DataColumn(label: Text('CA')),
            DataColumn(label: Text('Prix moyen')),
          ],
          rows:
              productData.map((product) {
                final name = product['name'];
                final category = product['category'];
                final quantity = product['quantity'].toString();
                final revenue = currencyFormat.format(product['revenue']);
                final avgPrice = currencyFormat.format(
                  product['quantity'] > 0
                      ? product['revenue'] / product['quantity']
                      : 0,
                );

                return DataRow(
                  cells: [
                    DataCell(Text(name)),
                    DataCell(Text(category)),
                    DataCell(Text(quantity)),
                    DataCell(Text(revenue)),
                    DataCell(Text(avgPrice)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopCustomersTable(List<Map<String, dynamic>> customerData) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Client')),
            DataColumn(label: Text('Commandes')),
            DataColumn(label: Text('Dépenses')),
            DataColumn(label: Text('Panier moyen')),
            DataColumn(label: Text('Dernière visite')),
          ],
          rows:
              customerData.map((customer) {
                final name = customer['name'];
                final orders = customer['orders'].toString();
                final spent = currencyFormat.format(customer['spent']);
                final avgOrder = currencyFormat.format(
                  customer['orders'] > 0
                      ? customer['spent'] / customer['orders']
                      : 0,
                );
                final lastVisit = DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.parse(customer['lastVisit']));

                return DataRow(
                  cells: [
                    DataCell(Text(name)),
                    DataCell(Text(orders)),
                    DataCell(Text(spent)),
                    DataCell(Text(avgOrder)),
                    DataCell(Text(lastVisit)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
