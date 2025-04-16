import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../presentation/common_widgets/loading_indicator.dart';

class SalesStatsScreen extends StatefulWidget {
  final String establishmentId;

  const SalesStatsScreen({Key? key, required this.establishmentId})
    : super(key: key);

  @override
  _SalesStatsScreenState createState() => _SalesStatsScreenState();
}

class _SalesStatsScreenState extends State<SalesStatsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'semaine';
  Map<String, dynamic> _salesData = {};
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderRepository = Provider.of<OrderRepository>(
        context,
        listen: false,
      );

      // Correction: utiliser les paramètres nommés correctement
      final salesData = await orderRepository.getSalesStats(
        establishmentId: widget.establishmentId,
        period: _selectedPeriod,
      );

      setState(() {
        _salesData = salesData;
        _totalRevenue = salesData['totalRevenue'] ?? 0;
        _totalOrders = salesData['totalOrders'] ?? 0;
        _averageOrderValue =
            _totalOrders > 0 ? _totalRevenue / _totalOrders : 0;
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
    _loadSalesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques de vente'),
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
                          _periodButton('jour', 'Jour'),
                          _periodButton('semaine', 'Semaine'),
                          _periodButton('mois', 'Mois'),
                          _periodButton('année', 'Année'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary stats
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total des ventes',
                            '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_totalRevenue)}',
                            Icons.euro,
                            ColorConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            'Commandes',
                            '$_totalOrders',
                            Icons.shopping_bag,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _statCard(
                      'Valeur moyenne',
                      '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_averageOrderValue)}',
                      Icons.trending_up,
                      Colors.teal,
                    ),
                    const SizedBox(height: 24),

                    // Sales chart
                    if (_salesData.containsKey('timeData'))
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
                                'Évolution des ventes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(height: 250, child: _buildSalesChart()),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Peak hours
                    if (_salesData.containsKey('peakHours'))
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
                                'Heures de pointe',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: _buildPeakHoursChart(),
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

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final timeData = _salesData['timeData'] as List<dynamic>;

    if (timeData.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final spots = List.generate(timeData.length, (index) {
      final item = timeData[index];
      return FlSpot(index.toDouble(), (item['amount'] as num).toDouble());
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine:
              (value) => FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1),
          getDrawingVerticalLine:
              (value) => FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final style = const TextStyle(
                  color: Color(0xff72719b),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                );

                final index = value.toInt();
                if (index >= 0 && index < timeData.length) {
                  final item = timeData[index];
                  String text;
                  if (_selectedPeriod == 'jour') {
                    text = '${item['hour']}h';
                  } else if (_selectedPeriod == 'semaine') {
                    const days = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
                    text = days[index % 7];
                  } else if (_selectedPeriod == 'mois') {
                    text = '${index + 1}';
                  } else {
                    text = item['label'];
                  }
                  return Text(text, style: style);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (value, meta) => Text(
                    '${value.toInt()}€',
                    style: const TextStyle(
                      color: Color(0xff75729e),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xffe7e8ec), width: 1),
        ),
        minX: 0,
        maxX: (timeData.length - 1).toDouble(),
        minY: 0,
        maxY: (_salesData['maxSales'] as num).toDouble() * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: ColorConstants.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: ColorConstants.primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    final peakHours = _salesData['peakHours'] as List<dynamic>;

    if (peakHours.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_salesData['maxOrders'] as num).toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < peakHours.length) {
                  return Text(
                    '${peakHours[index]['hour']}h',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
              reservedSize: 28,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(peakHours.length, (index) {
          final item = peakHours[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (item['orders'] as num).toDouble(),
                color: ColorConstants.primaryColor,
                width: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
