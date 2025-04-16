// lib/presentation/screens/orders/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/common_widgets/app_bar.dart';
import 'package:patenaire/presentation/common_widgets/loading_indicator.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:patenaire/data/models/order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(
        context,
        listen: false,
      ).getOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Détails de la commande"),
      body: Consumer<OrderProvider>(
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
                    "Erreur lors du chargement des détails",
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
                      orderProvider.getOrderDetails(widget.orderId);
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

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return Center(child: Text("Commande non trouvée"));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order),
                SizedBox(height: 24),
                _buildCustomerInfo(order),
                SizedBox(height: 24),
                _buildOrderItems(order),
                SizedBox(height: 24),
                _buildOrderSummary(order),
                SizedBox(height: 32),
                if (['pending', 'accepted', 'preparing'].contains(order.status))
                  _buildActionButtons(context, order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Commande #${order.orderNumber}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildStatusChip(order.status),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              DateFormat('dd MMMM yyyy - HH:mm').format(order.createdAt),
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              "Retrait prévu: ${DateFormat('HH:mm').format(order.pickupTime)}",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(Order order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations client",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, size: 20, color: ColorConstants.accentColor),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      order.customerPhone,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            if (order.customerNotes.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 20, color: ColorConstants.accentColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notes:",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          order.customerNotes,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Articles commandés",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.quantity}x",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          if (item.options.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                item.options.join(', '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          if (item.notes.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "Note: ${item.notes}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      "${(item.price * item.quantity).toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Récapitulatif",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildSummaryRow("Sous-total", formatter.format(order.subtotal)),
            _buildSummaryRow(
              "Frais de service",
              formatter.format(order.serviceFee),
            ),
            _buildSummaryRow(
              "Réduction",
              "-${formatter.format(order.discount)}",
            ),
            Divider(height: 24),
            _buildSummaryRow(
              "Total",
              formatter.format(order.total),
              isTotal: true,
            ),
            if (order.paymentMethod != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Moyen de paiement :",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Chip(
                      label: Text(
                        order.paymentMethod!,
                        style: TextStyle(color: ColorConstants.primaryColor),
                      ),
                      backgroundColor: ColorConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? ColorConstants.primaryColor : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? ColorConstants.primaryColor : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = 'En attente';
        color = Colors.orange;
        break;
      case 'accepted':
        label = 'Acceptée';
        color = Colors.blue;
        break;
      case 'preparing':
        label = 'En préparation';
        color = Colors.deepPurple;
        break;
      case 'ready':
        label = 'Prête';
        color = Colors.teal;
        break;
      case 'completed':
        label = 'Terminée';
        color = Colors.green;
        break;
      case 'cancelled':
        label = 'Annulée';
        color = Colors.red;
        break;
      default:
        label = 'Inconnue';
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildActionButtons(BuildContext context, Order order) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Déterminer les actions possibles en fonction du statut actuel
    String nextStatus;
    String buttonText;
    IconData buttonIcon;

    switch (order.status) {
      case 'pending':
        nextStatus = 'accepted';
        buttonText = 'Accepter la commande';
        buttonIcon = Icons.check_circle;
        break;
      case 'accepted':
        nextStatus = 'preparing';
        buttonText = 'Commencer la préparation';
        buttonIcon = Icons.restaurant;
        break;
      case 'preparing':
        nextStatus = 'ready';
        buttonText = 'Commande prête';
        buttonIcon = Icons.done_all;
        break;
      default:
        nextStatus = '';
        buttonText = '';
        buttonIcon = Icons.error;
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await orderProvider.updateOrderStatus(
              order.id,
              OrderStatus.values.firstWhere(
                (e) => e.name == nextStatus,
                orElse: () => OrderStatus.pending,
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut de la commande mis à jour'),
                backgroundColor: ColorConstants.successColor,
              ),
            );
          },
          icon: Icon(buttonIcon),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        if (order.status != 'cancelled')
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Annuler la commande'),
                        content: Text(
                          'Êtes-vous sûr de vouloir annuler cette commande ? Cette action ne peut pas être annulée.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Non'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Oui, annuler'),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorConstants.errorColor,
                            ),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  await orderProvider.updateOrderStatus(
                    order.id,
                    OrderStatus.cancelled,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Commande annulée'),
                      backgroundColor: ColorConstants.errorColor,
                    ),
                  );
                }
              },
              icon: Icon(Icons.cancel),
              label: Text('Annuler la commande'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                foregroundColor: ColorConstants.errorColor,
                side: BorderSide(color: ColorConstants.errorColor),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
      ],
    );
  }
}
