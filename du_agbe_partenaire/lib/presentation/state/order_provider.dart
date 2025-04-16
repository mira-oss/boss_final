// lib/presentation/state/order_provider.dart
import 'package:flutter/material.dart';
import 'package:patenaire/data/models/order_model.dart';
import 'package:patenaire/data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  List<Order> _orders = [];
  List<Order> _dailyOrders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  String? _currentEstablishmentId;

  double? _totalSales;
  double? _salesChange;
  int? _totalOrders;
  double? _ordersChange;
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _paymentMethodData = [];
  List<Map<String, dynamic>> _hourlyData = [];
  List<Map<String, dynamic>> _productData = [];
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _customerData = [];
  List<Map<String, dynamic>> _customerTypeData = [];
  List<Map<String, dynamic>> _trafficData = [];

  OrderProvider(this._orderRepository);

  List<Order> get orders => _orders;
  List<Order> get dailyOrders => _dailyOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentEstablishmentId => _currentEstablishmentId;

  double? get totalSales => _totalSales;
  double? get salesChange => _salesChange;
  int? get totalOrders => _totalOrders;
  double? get ordersChange => _ordersChange;
  List<Map<String, dynamic>> get salesData => _salesData;
  List<Map<String, dynamic>> get paymentMethodData => _paymentMethodData;
  List<Map<String, dynamic>> get hourlyData => _hourlyData;
  List<Map<String, dynamic>> get productData => _productData;
  List<Map<String, dynamic>> get categoryData => _categoryData;
  List<Map<String, dynamic>> get customerData => _customerData;
  List<Map<String, dynamic>> get customerTypeData => _customerTypeData;
  List<Map<String, dynamic>> get trafficData => _trafficData;

  /// Nouvelle méthode ajoutée pour plus de flexibilité
  void setEstablishmentId(String? establishmentId) {
    if (_currentEstablishmentId != establishmentId) {
      _currentEstablishmentId = establishmentId;
      notifyListeners();
    }
  }

  void updateEstablishmentId(String? establishmentId) {
    _currentEstablishmentId = establishmentId;
    if (establishmentId != null) {
      fetchOrders(establishmentId);
      fetchDailyOrders(establishmentId);
    }
    notifyListeners();
  }

  Future<void> fetchOrders(String establishmentId) async {
    _setLoading(true);
    try {
      _orders = await _orderRepository.getOrders(establishmentId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> fetchDailyOrders(String establishmentId) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _dailyOrders = await _orderRepository.getOrdersByDate(
        establishmentId,
        today,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> getOrderDetails(String orderId) async {
    _setLoading(true);
    try {
      _selectedOrder = await _orderRepository.getOrderById(orderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);
    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus.name);
      _orders =
          _orders
              .map(
                (order) =>
                    order.id == orderId
                        ? order.copyWith(status: newStatus)
                        : order,
              )
              .toList();

      _dailyOrders =
          _dailyOrders
              .map(
                (order) =>
                    order.id == orderId
                        ? order.copyWith(status: newStatus)
                        : order,
              )
              .toList();

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(status: newStatus);
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOrderStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_currentEstablishmentId == null) return;

    _setLoading(true);
    try {
      final statistics = await _orderRepository.getSalesStats(
        establishmentId: _currentEstablishmentId!,
        period: _getPeriodFromDates(startDate, endDate),
      );

      _totalSales = statistics['totalSales'];
      _salesChange = statistics['salesChange'];
      _totalOrders = statistics['totalOrders'];
      _ordersChange = statistics['ordersChange'];
      _salesData = List<Map<String, dynamic>>.from(
        statistics['salesData'] ?? [],
      );
      _paymentMethodData = List<Map<String, dynamic>>.from(
        statistics['paymentMethodData'] ?? [],
      );
      _hourlyData = List<Map<String, dynamic>>.from(
        statistics['hourlyData'] ?? [],
      );
      _productData = List<Map<String, dynamic>>.from(
        statistics['productData'] ?? [],
      );
      _categoryData = List<Map<String, dynamic>>.from(
        statistics['categoryData'] ?? [],
      );
      _customerData = List<Map<String, dynamic>>.from(
        statistics['customerData'] ?? [],
      );
      _customerTypeData = List<Map<String, dynamic>>.from(
        statistics['customerTypeData'] ?? [],
      );
      _trafficData = List<Map<String, dynamic>>.from(
        statistics['trafficData'] ?? [],
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
      _clearStatisticsData();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  String _getPeriodFromDates(DateTime start, DateTime end) {
    final duration = end.difference(start).inDays;
    if (duration <= 1) return 'day';
    if (duration <= 7) return 'week';
    if (duration <= 31) return 'month';
    return 'custom';
  }

  void _clearStatisticsData() {
    _totalSales = null;
    _salesChange = null;
    _totalOrders = null;
    _ordersChange = null;
    _salesData = [];
    _paymentMethodData = [];
    _hourlyData = [];
    _productData = [];
    _categoryData = [];
    _customerData = [];
    _customerTypeData = [];
    _trafficData = [];
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  int getOrderCountByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }
}
