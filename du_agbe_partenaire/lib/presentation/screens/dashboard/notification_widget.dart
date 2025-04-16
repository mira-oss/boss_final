// lib/presentation/screens/dashboard/notification_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patenaire/core/constants/color_constants.dart';
import 'package:patenaire/presentation/state/establishment_provider.dart';
import 'package:patenaire/presentation/state/order_provider.dart';
import 'package:patenaire/routes/app_router.dart';
import 'package:patenaire/data/models/order_model.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final establishmentProvider = Provider.of<EstablishmentProvider>(context);

    // Récupérer les notifications pertinentes
    final List<Map<String, dynamic>> notifications = _getNotifications(
      orderProvider,
      establishmentProvider,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications importantes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorConstants.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${notifications.length}",
                    style: TextStyle(
                      color: ColorConstants.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (notifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Aucune notification importante",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(context, notification);
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getNotifications(
    OrderProvider orderProvider,
    EstablishmentProvider establishmentProvider,
  ) {
    final List<Map<String, dynamic>> notifications = [];

    // 1. Commandes en attente
    final pendingOrders =
        orderProvider.dailyOrders
            .where((order) => order.status == OrderStatus.pending)
            .toList();

    if (pendingOrders.isNotEmpty) {
      notifications.add({
        'id': 'pending_orders',
        'type': 'order',
        'title': '${pendingOrders.length} commande(s) en attente',
        'message': 'Des commandes attendent votre confirmation.',
        'icon': Icons.hourglass_empty,
        'color': Colors.orange,
        'route': AppRouter.orders,
        'args': {'filter': 'pending'},
      });
    }

    // 2. Avis clients récents
    final hasNewReviews = establishmentProvider.hasNewReviews();
    if (hasNewReviews) {
      notifications.add({
        'id': 'new_reviews',
        'type': 'review',
        'title': 'Nouveaux avis clients',
        'message':
            'Consultez les nouvelles évaluations de votre établissement.',
        'icon': Icons.star,
        'color': Colors.amber,
        'route': AppRouter.reviews,
      });
    }

    // 3. Photos manquantes pour l'établissement
    final establishment = establishmentProvider.establishment;
    if (establishment != null &&
        (establishment.photoUrls.isEmpty ||
            establishment.photoUrls.length < 3)) {
      notifications.add({
        'id': 'missing_photos',
        'type': 'gallery',
        'title': 'Photos manquantes',
        'message': 'Améliorez votre visibilité en ajoutant plus de photos.',
        'icon': Icons.photo_library,
        'color': Colors.blue,
        'route': AppRouter.gallery,
      });
    }

    // 4. Information de contact incomplète
    if (establishment != null &&
        (establishment.phone.isEmpty || establishment.email.isEmpty)) {
      notifications.add({
        'id': 'incomplete_contact',
        'type': 'establishment',
        'title': 'Coordonnées incomplètes',
        'message': 'Complétez vos informations de contact pour vos clients.',
        'icon': Icons.contact_phone,
        'color': Colors.green,
        'route': AppRouter.contactInfo,
      });
    }

    return notifications;
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          notification['route'],
          arguments: notification['args'],
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification['icon'],
                color: notification['color'],
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
