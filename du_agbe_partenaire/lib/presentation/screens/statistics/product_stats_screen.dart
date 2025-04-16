import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';

class ProductStatsScreen extends StatefulWidget {
  final String establishmentId;

  const ProductStatsScreen({Key? key, required this.establishmentId})
    : super(key: key);

  @override
  _ProductStatsScreenState createState() => _ProductStatsScreenState();
}

class _ProductStatsScreenState extends State<ProductStatsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'mois';
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _categoryStats = [];

  @override
  void initState() {
    super.initState();
    _loadProductStats();
  }

  Future<void> _loadProductStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderRepository = Provider.of<OrderRepository>(
        context,
        listen: false,
      );
      final productRepository = Provider.of<ProductRepository>(
        context,
        listen: false,
      );

      final topProductsResult = await orderRepository.getTopProducts(
        establishmentId: widget.establishmentId,
        period: _selectedPeriod,
        limit: 10,
      );

      final categoryStatsResult = await productRepository.getCategoryStats(
        establishmentId: widget.establishmentId,
        period: _selectedPeriod,
      );

      setState(() {
        _topProducts = List<Map<String, dynamic>>.from(topProductsResult);
        _categoryStats = List<Map<String, dynamic>>.from(categoryStatsResult);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement des statistiques: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadProductStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques des produits'),
        backgroundColor: ColorConstants.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(
                child: LoadingIndicator(
                  message: 'Chargement des statistiques...',
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _periodButton('semaine', 'Semaine'),
                          _periodButton('mois', 'Mois'),
                          _periodButton('année', 'Année'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top products
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produits les plus vendus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _topProducts.isEmpty
                                ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Aucune donnée disponible'),
                                  ),
                                )
                                : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _topProducts.length,
                                  separatorBuilder:
                                      (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final product = _topProducts[index];
                                    return ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              index < 3
                                                  ? [
                                                    Colors.amber,
                                                    Colors.grey,
                                                    Colors.brown,
                                                  ][index]
                                                  : Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color:
                                                index < 3
                                                    ? Colors.white
                                                    : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        product['name'] ?? 'Produit sans nom',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Catégorie: ${product['category'] ?? 'Non catégorisé'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${product['quantity']} vendus',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(product['revenue'])}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  ColorConstants.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category pie chart
                    if (_categoryStats.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ventes par catégorie',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 250,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 40,
                                          sections: _getCategorySections(),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(
                                          _categoryStats.length,
                                          (index) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  color: _getCategoryColor(
                                                    index,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _categoryStats[index]['name'] ??
                                                        'Autre',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Performance indicators
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Indicateurs de performance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_topProducts.isNotEmpty) ...[
                              _performanceIndicator(
                                'Produit le plus vendu',
                                _topProducts[0]['name'] ?? 'N/A',
                                Icons.trending_up,
                                Colors.green,
                              ),
                              const SizedBox(height: 8),
                              _performanceIndicator(
                                'Quantité vendue',
                                '${_topProducts[0]['quantity']} unités',
                                Icons.shopping_cart,
                                Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              _performanceIndicator(
                                'Revenu généré',
                                NumberFormat.currency(
                                  locale: 'fr_FR',
                                  symbol: '€',
                                ).format(_topProducts[0]['revenue']),
                                Icons.euro,
                                ColorConstants.primaryColor,
                              ),
                            ] else
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('Aucune donnée disponible'),
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

  Widget _periodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => _changePeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _performanceIndicator(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getCategorySections() {
    final double totalRevenue = _categoryStats.fold(
      0,
      (sum, item) => sum + (item['revenue'] as num).toDouble(),
    );

    return List.generate(_categoryStats.length, (index) {
      final category = _categoryStats[index];
      final revenue = (category['revenue'] as num).toDouble();
      final percentage = totalRevenue == 0 ? 0 : (revenue / totalRevenue) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: revenue,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyan,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pinkAccent,
    ];
    return colors[index % colors.length];
  }
}
