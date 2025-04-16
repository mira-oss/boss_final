// lib/presentation/screens/dashboard/stats_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:patenaire/routes/app_router.dart';

class StatsSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Statistiques rapides",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRouter.statistics);
                  },
                  child: Text(
                    "Voir détails",
                    style: TextStyle(
                      color: ColorConstants.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    title: "Commandes",
                    value: orderProvider.dailyOrders.length.toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    title: "Chiffre",
                    value:
                        "${_calculateTotalRevenue(orderProvider).toStringAsFixed(2)} €",
                    icon: Icons.euro,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    title: "Vues",
                    value: "124", // Exemple statique
                    icon: Icons.visibility,
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context: context,
                    title: "Note",
                    value: "4.8/5", // Exemple statique
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotalRevenue(OrderProvider orderProvider) {
    return orderProvider.dailyOrders.fold(
      0,
      (total, order) => total + order.total,
    );
  }
}
