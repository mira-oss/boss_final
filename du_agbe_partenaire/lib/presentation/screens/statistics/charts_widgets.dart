import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:patenaire/core/constants/color_constants.dart';

class SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;

  const SalesLineChart({Key? key, required this.salesData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Créer les points pour le graphique
    final spots = List.generate(salesData.length, (index) {
      final item = salesData[index];
      return FlSpot(index.toDouble(), (item['sales'] as num).toDouble());
    });

    // Trouver la valeur maximum pour l'axe Y
    double maxY = 0;
    for (var data in salesData) {
      if ((data['sales'] as num).toDouble() > maxY) {
        maxY = (data['sales'] as num).toDouble();
      }
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(
                    color: Color(0xff72719b),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );

                  final index = value.toInt();
                  if (index >= 0 && index < salesData.length) {
                    // Format date for display
                    final dateStr = salesData[index]['date'];
                    final date = DateTime.parse(dateStr);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: style,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final currencyFormat = NumberFormat.currency(
                    locale: 'fr_FR',
                    symbol: '€',
                    decimalDigits: 0,
                  );

                  return Text(
                    currencyFormat.format(value),
                    style: TextStyle(
                      color: Color(0xff75729e),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
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
          maxX: (salesData.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2, // add 20% padding to the top
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
      ),
    );
  }
}

class PaymentMethodPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> paymentMethodData;

  const PaymentMethodPieChart({Key? key, required this.paymentMethodData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (paymentMethodData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Calculer le total pour les pourcentages
    double total = 0;
    for (var data in paymentMethodData) {
      total += (data['amount'] as num).toDouble();
    }

    // Définir les couleurs du graphique
    final List<Color> colors = [
      ColorConstants.primaryColor,
      ColorConstants.accentColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(paymentMethodData.length, (index) {
                  final data = paymentMethodData[index];
                  final value = (data['amount'] as num).toDouble();
                  final percentage = (value / total) * 100;

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(paymentMethodData.length, (index) {
                final data = paymentMethodData[index];
                final color = colors[index % colors.length];
                final amount = (data['amount'] as num).toDouble();
                final currencyFormat = NumberFormat.currency(
                  locale: 'fr_FR',
                  symbol: '€',
                  decimalDigits: 2,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['method'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currencyFormat.format(amount),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SalesByHourBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> hourlyData;

  const SalesByHourBarChart({Key? key, required this.hourlyData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Trouver la valeur maximum pour l'axe Y
    double maxY = 0;
    for (var data in hourlyData) {
      if ((data['orders'] as num).toDouble() > maxY) {
        maxY = (data['orders'] as num).toDouble();
      }
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2, // add 20% padding to the top
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(
                    color: Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );

                  final index = value.toInt();
                  if (index >= 0 && index < hourlyData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${hourlyData[index]['hour']}h',
                        style: style,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xffe7e8ec), width: 1),
          ),
          barGroups: List.generate(hourlyData.length, (index) {
            final item = hourlyData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['orders'] as num).toDouble(),
                  color: ColorConstants.accentColor,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class TopProductsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> productData;

  const TopProductsBarChart({Key? key, required this.productData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (productData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Limite aux 5 premiers produits pour la lisibilité
    final topProducts =
        productData.length > 5 ? productData.sublist(0, 5) : productData;

    // Trouver la valeur maximum pour l'axe Y
    double maxY = 0;
    for (var data in topProducts) {
      if ((data['quantity'] as num).toDouble() > maxY) {
        maxY = (data['quantity'] as num).toDouble();
      }
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2, // add 20% padding to the top
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(
                    color: Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );

                  final index = value.toInt();
                  if (index >= 0 && index < topProducts.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _truncateWithEllipsis(12, topProducts[index]['name']),
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xffe7e8ec), width: 1),
          ),
          barGroups: List.generate(topProducts.length, (index) {
            final item = topProducts[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['quantity'] as num).toDouble(),
                  color: ColorConstants.primaryColor,
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _truncateWithEllipsis(int cutoff, String myString) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }
}

class CategoryPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;

  const CategoryPieChart({Key? key, required this.categoryData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Calculer le total pour les pourcentages
    double total = 0;
    for (var data in categoryData) {
      total += (data['revenue'] as num).toDouble();
    }

    // Définir les couleurs du graphique
    final List<Color> colors = [
      ColorConstants.primaryColor,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      ColorConstants.accentColor,
      Colors.green,
      Colors.amber,
      Colors.indigo,
    ];

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(categoryData.length, (index) {
                  final data = categoryData[index];
                  final value = (data['revenue'] as num).toDouble();
                  final percentage = (value / total) * 100;

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(categoryData.length, (index) {
                final data = categoryData[index];
                final color = colors[index % colors.length];
                final amount = (data['revenue'] as num).toDouble();
                final currencyFormat = NumberFormat.currency(
                  locale: 'fr_FR',
                  symbol: '€',
                  decimalDigits: 2,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['category'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currencyFormat.format(amount),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerTypePieChart extends StatelessWidget {
  final List<Map<String, dynamic>> customerTypeData;

  const CustomerTypePieChart({Key? key, required this.customerTypeData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (customerTypeData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Calculer le total pour les pourcentages
    double total = 0;
    for (var data in customerTypeData) {
      total += (data['count'] as num).toDouble();
    }

    // Définir les couleurs du graphique
    final List<Color> colors = [
      ColorConstants.primaryColor,
      ColorConstants.accentColor,
    ];

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(customerTypeData.length, (index) {
                  final data = customerTypeData[index];
                  final value = (data['count'] as num).toDouble();
                  final percentage = (value / total) * 100;

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(customerTypeData.length, (index) {
                final data = customerTypeData[index];
                final color = colors[index % colors.length];
                final count = (data['count'] as num).toInt();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['type'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$count clients',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerTrafficBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> trafficData;

  const CustomerTrafficBarChart({Key? key, required this.trafficData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trafficData.isEmpty) {
      return Center(child: Text('Aucune donnée disponible'));
    }

    // Trouver la valeur maximum pour l'axe Y
    double maxY = 0;
    for (var data in trafficData) {
      if ((data['visits'] as num).toDouble() > maxY) {
        maxY = (data['visits'] as num).toDouble();
      }
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2, // add 20% padding to the top
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(
                    color: Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );

                  final index = value.toInt();
                  if (index >= 0 && index < trafficData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${trafficData[index]['hour']}h',
                        style: style,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Color(0xff7589a2),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xffe7e8ec), width: 1),
          ),
          barGroups: List.generate(trafficData.length, (index) {
            final item = trafficData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['visits'] as num).toDouble(),
                  color: Colors.teal,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
