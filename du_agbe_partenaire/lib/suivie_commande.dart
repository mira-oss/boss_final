import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:io';
import 'dart:math';

// Modèles de données
class OrderModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final DateTime orderDate;
  final List<OrderItem> items;
  final double total;
  final String status; // "pending", "ready", "delivered"
  final String? instructions;
  final String? clientPhoto;

  OrderModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.orderDate,
    required this.items,
    required this.total,
    required this.status,
    this.instructions,
    this.clientPhoto,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      clientName: data['clientName'] ?? 'Client inconnu',
      clientPhone: data['clientPhone'] ?? '',
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      items: List<OrderItem>.from(
        (data['items'] as List).map((item) => OrderItem.fromMap(item)),
      ),
      total: (data['total'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      instructions: data['instructions'],
      clientPhoto: data['clientPhoto'],
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? image;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? 'Produit inconnu',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      image: map['image'],
    );
  }
}

// Provider pour la gestion d'état
class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  String _filter = 'all';
  bool _isLoading = true;
  String _searchQuery = '';

  List<OrderModel> get orders {
    if (_searchQuery.isNotEmpty) {
      return _orders.where((order) {
        return order.clientName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            order.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filter == 'all') return _orders;
    return _orders.where((order) => order.status == _filter).toList();
  }

  String get filter => _filter;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  set filter(String value) {
    _filter = value;
    notifyListeners();
  }

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulons un délai réseau
      await Future.delayed(Duration(seconds: 1));

      // Dans une vraie implémentation, vous récupéreriez les données de Firestore
      // final snapshot = await FirebaseFirestore.instance.collection('orders').get();
      // _orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Données simulées pour l'exemple
      _orders = generateMockOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erreur lors de la récupération des commandes: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Simulons un délai réseau
      await Future.delayed(Duration(milliseconds: 600));

      // Dans une vraie implémentation, vous mettriez à jour Firestore
      // await FirebaseFirestore.instance
      //     .collection('orders')
      //     .doc(orderId)
      //     .update({'status': newStatus});

      // Mise à jour locale
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final oldOrder = _orders[index];
        _orders[index] = OrderModel(
          id: oldOrder.id,
          clientName: oldOrder.clientName,
          clientPhone: oldOrder.clientPhone,
          orderDate: oldOrder.orderDate,
          items: oldOrder.items,
          total: oldOrder.total,
          status: newStatus,
          instructions: oldOrder.instructions,
          clientPhoto: oldOrder.clientPhoto,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Génère des données de test
  List<OrderModel> generateMockOrders() {
    final List<String> clientNames = [
      'Kokou Hounsou',
      'Aminata Diallo',
      'Jean Adjakpa',
      'Sophie Lokossou',
      'Karim Bamba',
      'Marie Assogba',
      'Frank Adjovi',
      'Estelle Ahovi',
      'Pascal Amoussou',
    ];

    final List<String> dishes = [
      'Poulet Yassa',
      'Riz au Gras',
      'Sauce Gombo',
      'Alloco',
      'Akassa',
      'Poisson Braisé',
      'Pâte Rouge',
      'Igname Pilé',
      'Ablo',
    ];

    final List<String> photos = [
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36',
      'https://images.unsplash.com/photo-1580489944761-15a19d654956',
      'https://images.unsplash.com/photo-1633332755192-727a05c4013d',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
    ];

    final instructions = [
      'Livraison rapide SVP',
      'Sans trop d\'épices',
      'Extra sauce si possible',
      'Appeler avant d\'arriver',
      null,
    ];

    final statuses = ['pending', 'ready', 'delivered'];
    final random = Random();

    return List.generate(20, (index) {
      final clientName = clientNames[random.nextInt(clientNames.length)];
      final orderDate = DateTime.now().subtract(
        Duration(hours: random.nextInt(48), minutes: random.nextInt(60)),
      );

      final numItems = random.nextInt(3) + 1;
      final items = List.generate(numItems, (i) {
        final dishName = dishes[random.nextInt(dishes.length)];
        final quantity = random.nextInt(3) + 1;
        final price =
            (random.nextInt(8) + 2) * 500.0; // Entre 1000 et 5000 FCFA
        final hasImage = random.nextBool();

        return OrderItem(
          name: dishName,
          quantity: quantity,
          price: price,
          image:
              hasImage
                  ? 'https://source.unsplash.com/100x100/?food,$dishName'
                  : null,
        );
      });

      final total = items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      final status = statuses[random.nextInt(statuses.length)];

      return OrderModel(
        id: 'CMD-${10000 + index}',
        clientName: clientName,
        clientPhone: '+229 ${random.nextInt(90000000) + 10000000}',
        orderDate: orderDate,
        items: items,
        total: total,
        status: status,
        instructions: instructions[random.nextInt(instructions.length)],
        clientPhoto:
            random.nextBool() ? photos[random.nextInt(photos.length)] : null,
      );
    });
  }

  // Exporter les commandes en PDF
  Future<void> exportOrdersToPdf(BuildContext context) async {
    final pdf = pw.Document();

    // Créer le PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Rapport des Commandes',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Divider(),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Numéro',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Client',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Statut',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...orders.map((order) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(order.id),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(order.clientName),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          DateFormat('dd/MM HH:mm').format(order.orderDate),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${NumberFormat("#,###").format(order.total)} FCFA',
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(_getStatusName(order.status)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Résumé:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Nombre de commandes: ${orders.length}'),
            pw.Text(
              'En attente: ${orders.where((o) => o.status == 'pending').length}',
            ),
            pw.Text(
              'Prêtes: ${orders.where((o) => o.status == 'ready').length}',
            ),
            pw.Text(
              'Livrées: ${orders.where((o) => o.status == 'delivered').length}',
            ),
            pw.Text(
              'Total: ${NumberFormat("#,###").format(orders.fold(0.0, (sum, order) => sum + order.total))} FCFA',
            ),
          ];
        },
      ),
    );

    // Afficher le PDF pour prévisualisation et impression
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'commandes.pdf');
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Livrée';
      default:
        return 'Inconnu';
    }
  }
}

// Gestionnaire de notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    var androidDetails = AndroidNotificationDetails(
      'order_channel_id',
      'Commandes',
      channelDescription: 'Notifications de nouvelles commandes',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF6200),
    );

    var iosDetails = DarwinNotificationDetails();
    var generalNotificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notificationsPlugin.show(0, title, body, generalNotificationDetails);
  }
}

// Page principale de suivi des commandes
class OrdersTrackingPage extends StatefulWidget {
  @override
  _OrdersTrackingPageState createState() => _OrdersTrackingPageState();
}

class _OrdersTrackingPageState extends State<OrdersTrackingPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Initialiser les notifications
    _notificationService.initNotification();

    // Charger les commandes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
    });

    // Simuler une nouvelle commande après 5 secondes
    Future.delayed(Duration(seconds: 5), () {
      _showNewOrderNotification();
    });
  }

  void _showNewOrderNotification() {
    _notificationService.showNotification(
      'Nouvelle commande reçue!',
      'CMD-10098 de Sophie Lokossou est en attente',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title:
                _isSearching
                    ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une commande...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        ordersProvider.searchQuery = value;
                      },
                    )
                    : Text('Suivi des Commandes'),
            backgroundColor: Color(0xFFFF6200),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ordersProvider.searchQuery = '';
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () => ordersProvider.exportOrdersToPdf(context),
              ),
              badges.Badge(
                position: badges.BadgePosition.topEnd(top: 5, end: 5),
                badgeContent: Text(
                  '${ordersProvider.orders.where((o) => o.status == 'pending').length}',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: badges.BadgeStyle(badgeColor: Colors.red),
                child: IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Afficher des notifications ou marquer comme lues
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notifications consultées')),
                    );
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Toutes', 'all', ordersProvider),
                    SizedBox(width: 8),
                    _buildFilterChip('En attente', 'pending', ordersProvider),
                    SizedBox(width: 8),
                    _buildFilterChip('Prêtes', 'ready', ordersProvider),
                    SizedBox(width: 8),
                    _buildFilterChip('Livrées', 'delivered', ordersProvider),
                  ],
                ),
              ),
            ),
          ),
          body:
              ordersProvider.isLoading
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6200),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('Chargement des commandes...'),
                      ],
                    ),
                  )
                  : ordersProvider.orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                    onRefresh: () => ordersProvider.fetchOrders(),
                    color: Color(0xFFFF6200),
                    child: AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(8),
                        itemCount: ordersProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = ordersProvider.orders[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildOrderCard(order, ordersProvider),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Action pour rafraîchir manuellement les commandes
              ordersProvider.fetchOrders();
              // Animer le FAB
              _animationController.forward(from: 0.0);
            },
            backgroundColor: Color(0xFFFF6200),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2.0 * pi,
                  child: child,
                );
              },
              child: Icon(Icons.refresh),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String filterValue,
    OrdersProvider provider,
  ) {
    bool isSelected = provider.filter == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Color(0xFFFF6200).withOpacity(0.2),
      checkmarkColor: Color(0xFFFF6200),
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFFFF6200) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      onSelected: (selected) {
        provider.filter = filterValue;
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, OrdersProvider provider) {
    // Déterminer l'icône de statut
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (order.status) {
      case 'pending':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      case 'ready':
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.green;
        statusText = 'Prête';
        break;
      case 'delivered':
        statusIcon = Icons.done_all;
        statusColor = Colors.blue;
        statusText = 'Livrée';
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusText = 'Inconnu';
    }

    return Slidable(
      key: Key(order.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (order.status != 'ready' && order.status != 'delivered')
            SlidableAction(
              onPressed: (_) {
                provider.updateOrderStatus(order.id, 'ready');
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check_circle,
              label: 'Prêt',
            ),
          if (order.status != 'delivered')
            SlidableAction(
              onPressed: (_) {
                provider.updateOrderStatus(order.id, 'delivered');
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.delivery_dining,
              label: 'Livré',
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              _showOrderDetailsDialog(context, order);
            },
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: Icons.info_outline,
            label: 'Détails',
          ),
          SlidableAction(
            onPressed: (_) {
              // Simuler un appel téléphonique
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appel à ${order.clientName} en cours...'),
                ),
              );
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            icon: Icons.phone,
            label: 'Appeler',
          ),
        ],
      ),
      child: Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
            ),
            child: InkWell(
              onTap: () => _showOrderDetailsDialog(context, order),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (order.clientPhoto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: CachedNetworkImage(
                              imageUrl: order.clientPhoto!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.grey[500]),
                          ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.clientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                order.clientPhone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${NumberFormat("#,###").format(order.total)} FCFA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFFF6200),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              timeago.format(order.orderDate, locale: 'fr'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Commande #${order.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (order.instructions != null) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.amber[800],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.instructions!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[900],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          order.items.map((item) {
                            return Chip(
                              avatar:
                                  item.image != null
                                      ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          item.image!,
                                        ),
                                      )
                                      : CircleAvatar(
                                        backgroundColor: Colors.grey[200],
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                              label: Text(
                                '${item.quantity}× ${item.name}',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.symmetric(horizontal: 4),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (order.clientPhoto != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            imageUrl: order.clientPhoto!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => CircularProgressIndicator(),
                            errorWidget:
                                (context, url, error) => Icon(Icons.error),
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[500]),
                        ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.clientName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              order.clientPhone,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Commande #${order.id}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Passée le ${DateFormat('dd/MM/yyyy à HH:mm').format(order.orderDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Articles commandés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            item.image != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: item.image!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.grey[500],
                                  ),
                                ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${NumberFormat("#,###").format(item.price)} FCFA',
                        ),
                        trailing: Text(
                          '${item.quantity}×',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 32),
                  if (order.instructions != null) ...[
                    Text(
                      'Instructions spéciales:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Text(order.instructions!),
                    ),
                    SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${NumberFormat("#,###").format(order.total)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFFFF6200),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (order.status != 'delivered')
                        ElevatedButton.icon(
                          icon: Icon(Icons.delivery_dining),
                          label: Text('Marquer comme livrée'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<OrdersProvider>(
                              context,
                              listen: false,
                            ).updateOrderStatus(order.id, 'delivered');
                            Navigator.of(context).pop();
                          },
                        ),
                      OutlinedButton.icon(
                        icon: Icon(Icons.phone),
                        label: Text('Appeler le client'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Appel à ${order.clientName} en cours...',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Aucune commande trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les nouvelles commandes apparaîtront ici',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Rafraîchir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6200),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
            },
          ),
        ],
      ),
    );
  }
}

// Point d'entrée de l'application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dans une vraie application, vous initialiseriez Firebase ici
  // await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => OrdersProvider(),
      child: RestaurantOrdersApp(),
    ),
  );
}

class RestaurantOrdersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Commandes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFFF6200),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFF6200),
          primary: Color(0xFFFF6200),
        ),
        appBarTheme: AppBarTheme(color: Color(0xFFFF6200), elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6200),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFFF6200), width: 2),
          ),
        ),
      ),
      home: OrdersTrackingPage(),
    );
  }
}

// Page de détails d'une commande (pour une navigation dédiée si nécessaire)
class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${order.id}'),
        backgroundColor: Color(0xFFFF6200),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations sur le client
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations client',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        if (order.clientPhoto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: CachedNetworkImage(
                              imageUrl: order.clientPhoto!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) => Icon(Icons.error),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[500],
                            ),
                          ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.clientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    order.clientPhone,
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Détails de la commande
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la commande',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date de commande:'),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(order.orderDate),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Numéro de commande:'),
                        Text(
                          order.id,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Statut:'),
                        _buildStatusBadge(order.status),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Articles commandés
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Articles commandés',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              item.image != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item.image!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                          title: Text(
                            item.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${NumberFormat("#,###").format(item.price)} FCFA',
                            style: TextStyle(color: Color(0xFFFF6200)),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.quantity}×',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${NumberFormat("#,###").format(order.total)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFFF6200),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (order.instructions != null) ...[
              SizedBox(height: 16),

              // Instructions spéciales
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.amber.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800]),
                          SizedBox(width: 8),
                          Text(
                            'Instructions spéciales',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        order.instructions!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone),
                    label: Text('Appeler le client'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Appel à ${order.clientName} en cours...',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.print),
                    label: Text('Imprimer facture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Impression de la facture...')),
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            if (order.status != 'delivered')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.delivery_dining),
                  label: Text('Marquer comme livrée'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Provider.of<OrdersProvider>(
                      context,
                      listen: false,
                    ).updateOrderStatus(order.id, 'delivered');
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case 'pending':
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        text = 'En attente';
        break;
      case 'ready':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        text = 'Prête';
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.blue;
        text = 'Livrée';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        text = 'Inconnu';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
