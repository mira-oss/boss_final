import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/common_widgets/app_bar.dart';
import 'package:patenaire/presentation/screens/dashboard/notification_widget.dart';
import 'package:patenaire/presentation/screens/dashboard/stats_summary_widget.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';
import 'package:patenaire/routes/app_router.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isEstablishmentOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Récupérer l'identifiant de l'établissement
      final establishmentProvider = Provider.of<EstablishmentProvider>(
        context,
        listen: false,
      );
      establishmentProvider.fetchEstablishmentDetails();

      // Utiliser l'ID de l'établissement pour récupérer les commandes
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (orderProvider.currentEstablishmentId != null) {
        orderProvider.fetchDailyOrders(orderProvider.currentEstablishmentId!);
      }
    });
  }

  void _toggleEstablishmentStatus() {
    setState(() {
      _isEstablishmentOpen = !_isEstablishmentOpen;
    });
    // TODO: Mettre à jour le statut dans la base de données
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final establishmentProvider = Provider.of<EstablishmentProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(title: "Tableau de bord"),
      body: RefreshIndicator(
        onRefresh: () async {
          await establishmentProvider.fetchEstablishmentDetails();
          if (orderProvider.currentEstablishmentId != null) {
            await orderProvider.fetchDailyOrders(
              orderProvider.currentEstablishmentId!,
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut d'ouverture
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Statut de l'établissement",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _isEstablishmentOpen ? "Ouvert" : "Fermé",
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  _isEstablishmentOpen
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isEstablishmentOpen,
                        onChanged: (value) => _toggleEstablishmentStatus(),
                        activeColor: ColorConstants.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Statistiques rapides
              StatsSummaryWidget(),
              SizedBox(height: 16),

              // Commandes du jour
              _buildTodayOrdersSection(orderProvider),
              SizedBox(height: 16),

              // Notifications importantes
              NotificationWidget(),
              SizedBox(height: 24),

              // Sections d'accès rapide
              Text(
                "Accès rapide",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              _buildQuickAccessGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayOrdersSection(OrderProvider orderProvider) {
    if (orderProvider.isLoading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final todayOrders = orderProvider.dailyOrders;

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
                  "Commandes du jour",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRouter.orders);
                  },
                  child: Text(
                    "Voir tout",
                    style: TextStyle(
                      color: ColorConstants.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (todayOrders.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Aucune commande aujourd'hui",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: todayOrders.length > 3 ? 3 : todayOrders.length,
                itemBuilder: (context, index) {
                  final order = todayOrders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order.status),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '#${order.id.substring(0, 6)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_getStatusLabel(order.status)),
                    trailing: Text(
                      '${order.total.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.orderDetails,
                        arguments: {'orderId': order.id},
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildQuickAccessCard(
          context,
          title: "Produits",
          icon: Icons.fastfood,
          color: Colors.orange,
          route: AppRouter.productsList,
        ),
        _buildQuickAccessCard(
          context,
          title: "Commandes",
          icon: Icons.receipt_long,
          color: Colors.blue,
          route: AppRouter.orders,
        ),
        _buildQuickAccessCard(
          context,
          title: "Statistiques",
          icon: Icons.bar_chart,
          color: Colors.purple,
          route: AppRouter.statistics,
        ),
        _buildQuickAccessCard(
          context,
          title: "Avis clients",
          icon: Icons.star,
          color: Colors.amber,
          route: AppRouter.reviews,
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivering':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'delivering':
        return 'En livraison';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }
}
