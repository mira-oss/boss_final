import 'package:patenaire/data/models/order_model.dart' as model;
import 'package:patenaire/data/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

class OrderRepository {
  final FirebaseService _firebaseService;
  final Dio _dio;
  final String _baseUrl;

  OrderRepository(
    this._firebaseService, {
    required Dio dio,
    required String baseUrl,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  /// Récupère toutes les commandes d'un établissement
  Future<List<model.Order>> getOrders(String establishmentId) async {
    try {
      final snapshot =
          await _firebaseService.firestore
              .collection('orders')
              .where('establishmentId', isEqualTo: establishmentId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return model.Order.fromMap(data['id'], data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les commandes d'un établissement à une date spécifique
  Future<List<model.Order>> getOrdersByDate(
    String establishmentId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      final snapshot =
          await _firebaseService.firestore
              .collection('orders')
              .where('establishmentId', isEqualTo: establishmentId)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return model.Order.fromMap(data['id'], data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les détails d'une commande spécifique
  Future<model.Order> getOrderById(String orderId) async {
    try {
      final doc =
          await _firebaseService.firestore
              .collection('orders')
              .doc(orderId)
              .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('Commande non trouvée');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return model.Order.fromMap(data['id'], data);
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour le statut d'une commande
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firebaseService.firestore.collection('orders').doc(orderId).update(
        {'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les commandes terminées d'un établissement entre deux dates
  Future<List<model.Order>> getCompletedOrders(
    String establishmentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await _firebaseService.firestore
              .collection('orders')
              .where('establishmentId', isEqualTo: establishmentId)
              .where('status', isEqualTo: 'completed')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return model.Order.fromMap(data['id'], data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les produits les plus vendus d'un établissement
  Future<List<Map<String, dynamic>>> getTopProducts({
    required String establishmentId,
    required String period,
    int limit = 10,
  }) async {
    try {
      final DateTime now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'semaine':
          startDate = DateTime(now.year, now.month, now.day - 7);
          break;
        case 'mois':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'année':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
      }

      final snapshot =
          await _firebaseService.firestore
              .collection('orders')
              .where('establishmentId', isEqualTo: establishmentId)
              .where('status', isEqualTo: 'completed')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .get();

      Map<String, Map<String, dynamic>> productStats = {};

      for (var doc in snapshot.docs) {
        final orderData = doc.data();
        final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);

        for (var item in items) {
          final productId = item['productId'];
          final quantity = item['quantity'] ?? 0;
          final price = item['price'] ?? 0.0;
          final productName = item['productName'] ?? 'Produit inconnu';
          final category = item['category'] ?? 'Non spécifié';

          final existingStat =
              productStats[productId] ??
              {
                'quantity': 0,
                'totalSales': 0.0,
                'productName': productName,
                'category': category,
              };

          productStats[productId] = {
            'quantity': existingStat['quantity'] + quantity,
            'totalSales': existingStat['totalSales'] + (quantity * price),
            'productName': productName,
            'category': category,
          };
        }
      }

      final sortedProducts = productStats.values.toList();
      sortedProducts.sort(
        (a, b) =>
            (b['totalSales'] as double).compareTo(a['totalSales'] as double),
      );

      return sortedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Récupère les statistiques de vente
  Future<Map<String, dynamic>> getSalesStats({
    required String establishmentId,
    required String period,
  }) async {
    try {
      // Déterminer les dates en fonction de la période
      final DateTime now = DateTime.now();
      DateTime startDate;
      DateTime previousPeriodStart;
      DateTime previousPeriodEnd;

      switch (period) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          previousPeriodStart = DateTime(now.year, now.month, now.day - 1);
          previousPeriodEnd = DateTime(
            now.year,
            now.month,
            now.day - 1,
            23,
            59,
            59,
          );
          break;
        case 'week':
          startDate = DateTime(now.year, now.month, now.day - 7);
          previousPeriodStart = DateTime(now.year, now.month, now.day - 14);
          previousPeriodEnd = DateTime(now.year, now.month, now.day - 8);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          previousPeriodStart = DateTime(now.year, now.month - 2, now.day);
          previousPeriodEnd = DateTime(now.year, now.month - 1, now.day - 1);
          break;
        case 'custom':
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
          previousPeriodStart = DateTime(now.year, now.month - 2, now.day);
          previousPeriodEnd = DateTime(now.year, now.month - 1, now.day - 1);
      }

      // Récupérer les commandes complétées
      final currentOrders = await getCompletedOrders(
        establishmentId,
        startDate,
        now,
      );
      final previousOrders = await getCompletedOrders(
        establishmentId,
        previousPeriodStart,
        previousPeriodEnd,
      );

      // Calculer les statistiques
      double totalSales = currentOrders.fold(
        0,
        (sum, order) => sum + order.total,
      );
      double previousSales = previousOrders.fold(
        0,
        (sum, order) => sum + order.total,
      );

      final salesChange =
          previousSales > 0
              ? ((totalSales - previousSales) / previousSales) * 100
              : 0.0;

      final ordersChange =
          previousOrders.isNotEmpty
              ? ((currentOrders.length - previousOrders.length) /
                      previousOrders.length) *
                  100
              : 0.0;

      return {
        'totalSales': totalSales,
        'salesChange': salesChange,
        'totalOrders': currentOrders.length,
        'ordersChange': ordersChange,
        'salesData': _prepareSalesData(currentOrders, period),
        'paymentMethodData': _preparePaymentMethodData(currentOrders),
        'hourlyData': _prepareHourlyData(currentOrders),
        'productData': await getTopProducts(
          establishmentId: establishmentId,
          period: period,
        ),
        'categoryData': _prepareCategoryData(currentOrders),
        'customerData': [],
        'customerTypeData': [],
        'trafficData': [],
      };
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${e.toString()}',
      );
    }
  }

  // Méthodes auxiliaires pour préparer les données de graphiques
  List<Map<String, dynamic>> _prepareSalesData(
    List<model.Order> orders,
    String period,
  ) {
    Map<String, double> salesByDate = {};

    for (var order in orders) {
      final date = order.createdAt;
      String key;

      switch (period) {
        case 'day':
          key = '${date.hour}:00';
          break;
        case 'week':
          final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
          key = days[date.weekday % 7];
          break;
        case 'month':
          key = date.day.toString().padLeft(2, '0');
          break;
        default:
          key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }

      salesByDate[key] = (salesByDate[key] ?? 0) + order.total;
    }

    return salesByDate.entries
        .map((entry) => {'date': entry.key, 'amount': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _preparePaymentMethodData(
    List<model.Order> orders,
  ) {
    Map<String, int> countByMethod = {};

    for (var order in orders) {
      final method = order.paymentMethod ?? 'Unknown';
      countByMethod[method] = (countByMethod[method] ?? 0) + 1;
    }

    return countByMethod.entries
        .map((entry) => {'name': entry.key, 'value': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _prepareHourlyData(List<model.Order> orders) {
    Map<int, int> countByHour = {};

    for (var order in orders) {
      final hour = order.createdAt.hour;
      countByHour[hour] = (countByHour[hour] ?? 0) + 1;
    }

    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 24; i++) {
      result.add({
        'hour': '${i.toString().padLeft(2, '0')}:00',
        'count': countByHour[i] ?? 0,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _prepareCategoryData(List<model.Order> orders) {
    // Puisque OrderItem n'a pas de catégorie, nous allons regrouper par productId
    // Map pour stocker le total des ventes par produit
    Map<String, double> salesByProduct = {};

    // Parcourir toutes les commandes
    for (var order in orders) {
      // Pour chaque commande, parcourir les articles
      for (var item in order.items) {
        final amount = item.price * item.quantity;

        // Ajouter le montant au produit
        salesByProduct[item.productName] =
            (salesByProduct[item.productName] ?? 0) + amount;
      }
    }

    // Convertir en liste pour le graphique
    return salesByProduct.entries
        .map((entry) => {'name': entry.key, 'value': entry.value})
        .toList();
  }
}
