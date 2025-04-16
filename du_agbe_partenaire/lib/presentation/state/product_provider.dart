import 'package:flutter/material.dart';
import 'package:patenaire/data/models/product_model.dart';
import 'package:patenaire/data/repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;
  String? _establishmentId;
  List<Product> _products = [];
  bool _isLoading = false;

  ProductProvider(this._productRepository);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get establishmentId => _establishmentId;

  void setEstablishmentId(String? establishmentId) {
    _establishmentId = establishmentId;
    if (establishmentId != null) {
      fetchProducts();
    }
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    if (_establishmentId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _products = await _productRepository.getProductsByEstablishment(
        _establishmentId!,
      );
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getProductCategories() {
    return _products.map((product) => product.category).toSet().toList();
  }

  Future<void> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productRepository.addProduct(
        product.copyWith(establishmentId: _establishmentId),
      );
      await fetchProducts(forceRefresh: true);
    } catch (e) {
      print('Error adding product: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productRepository.updateProduct(product);
      await fetchProducts(forceRefresh: true);
    } catch (e) {
      print('Error updating product: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productRepository.deleteProduct(productId);
      await fetchProducts(forceRefresh: true);
    } catch (e) {
      print('Error deleting product: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
