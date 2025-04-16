// lib/presentation/screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/common_widgets/app_bar.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:patenaire/routes/app_router.dart';
import 'package:patenaire/data/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Toutes';
  final List<String> _filters = [
    'Toutes',
    'En attente',
    'En cours',
    'Terminées',
    'Annulées',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On vérifie si un ID d'établissement est défini
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (orderProvider.currentEstablishmentId != null) {
        orderProvider.fetchOrders(orderProvider.currentEstablishmentId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Commandes"),
      body: Column(
        children: [
          // Onglets En cours / Historique
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: ColorConstants.primaryColor,
              unselectedLabelColor: ColorConstants.secondaryTextColor,
              indicatorColor: ColorConstants.accentColor,
              tabs: [Tab(text: "En cours"), Tab(text: "Historique")],
            ),
          ),

          // Filtres
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          selectedColor: ColorConstants.primaryColorLight
                              .withOpacity(0.2),
                          labelStyle: TextStyle(
                            color:
                                _selectedFilter == filter
                                    ? ColorConstants.primaryColor
                                    : ColorConstants.secondaryTextColor,
                            fontWeight:
                                _selectedFilter == filter
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet En cours
                _buildOrdersList(true),

                // Onglet Historique
                _buildOrdersList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(bool isActive) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return Center(child: LoadingIndicator());
        }

        if (orderProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Erreur lors du chargement des commandes",
                  style: TextStyle(
                    color: ColorConstants.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(orderProvider.error!),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Vérifier si l'ID d'établissement est disponible
                    if (orderProvider.currentEstablishmentId != null) {
                      orderProvider.fetchOrders(
                        orderProvider.currentEstablishmentId!,
                      );
                    }
                  },
                  child: Text("Réessayer"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final List<Order> filteredOrders = _filterOrders(
          orderProvider.orders,
          isActive,
          _selectedFilter,
        );

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.receipt_long : Icons.history,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  isActive
                      ? "Aucune commande en cours"
                      : "Aucune commande dans l'historique",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Vérifier si l'ID d'établissement est disponible
            if (orderProvider.currentEstablishmentId != null) {
              await orderProvider.fetchOrders(
                orderProvider.currentEstablishmentId!,
              );
            }
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _buildOrderCard(context, order);
            },
          ),
        );
      },
    );
  }

  List<Order> _filterOrders(List<Order> orders, bool isActive, String filter) {
    // Filtrer d'abord par actif/inactif
    List<Order> result =
        orders.where((order) {
          if (isActive) {
            return [
              'pending',
              'accepted',
              'preparing',
              'ready',
            ].contains(order.status);
          } else {
            return ['completed', 'cancelled'].contains(order.status);
          }
        }).toList();

    // Appliquer ensuite le filtre sélectionné
    if (filter != 'Toutes') {
      String statusFilter = _getStatusFilterValue(filter);
      result = result.where((order) => order.status == statusFilter).toList();
    }

    // Trier par date, les plus récentes en premier
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  String _getStatusFilterValue(String filter) {
    switch (filter) {
      case 'En attente':
        return 'pending';
      case 'En cours':
        return 'preparing';
      case 'Terminées':
        return 'completed';
      case 'Annulées':
        return 'cancelled';
      default:
        return '';
    }
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.orderDetails,
            arguments: {'orderId': order.id},
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.orderNumber}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(order.createdAt),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${order.items.length} article${order.items.length > 1 ? 's' : ''}",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${order.total.toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (['pending', 'accepted', 'preparing'].contains(order.status))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      order,
                      currentStatus: order.status,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label = _getStatusLabel(status);
    Color color = _getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Order order, {
    required String currentStatus,
  }) {
    String nextStatus;
    String buttonLabel;
    Color buttonColor;

    switch (currentStatus) {
      case 'pending':
        nextStatus = 'accepted';
        buttonLabel = 'Accepter';
        buttonColor = ColorConstants.successColor;
        break;
      case 'accepted':
        nextStatus = 'preparing';
        buttonLabel = 'En préparation';
        buttonColor = ColorConstants.infoColor;
        break;
      case 'preparing':
        nextStatus = 'ready';
        buttonLabel = 'Prête';
        buttonColor = ColorConstants.warningColor;
        break;
      default:
        return SizedBox.shrink();
    }

    return Row(
      children: [
        if (currentStatus == 'pending')
          OutlinedButton(
            onPressed: () {
              _confirmOrderStatusChange(
                context,
                order,
                'cancelled',
                'Annuler la commande',
                'Êtes-vous sûr de vouloir annuler cette commande ?',
              );
            },
            child: Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.errorColor,
              side: BorderSide(color: ColorConstants.errorColor),
            ),
          ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            _confirmOrderStatusChange(
              context,
              order,
              nextStatus,
              'Changer le statut',
              'Changer le statut de la commande à "$buttonLabel" ?',
            );
          },
          child: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: buttonColor,
          ),
        ),
      ],
    );
  }

  void _confirmOrderStatusChange(
    BuildContext context,
    Order order,
    String newStatusStr,
    String title,
    String message,
  ) {
    // Conversion de String à OrderStatus
    OrderStatus newStatus = _stringToOrderStatus(newStatusStr);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Provider.of<OrderProvider>(
                  context,
                  listen: false,
                ).updateOrderStatus(order.id, newStatus);
              },
              child: Text('Confirmer'),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                // Correction: fontWeight n'est pas un paramètre valide ici
                // Le style de texte doit être appliqué directement au widget Text
              ),
            ),
          ],
        );
      },
    );
  }

  // Fonction utilitaire pour convertir String en OrderStatus
  OrderStatus _stringToOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending; // Valeur par défaut
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
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
      case 'accepted':
        return 'Acceptée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête à retirer';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }
}
