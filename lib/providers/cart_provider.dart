import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../repositories/cart_repository.dart';
import '../services/cart_service.dart';

/// Provider for managing state of the Shopping Cart in WatchHub.
///
/// Follows Clean Architecture by interacting ONLY with the [CartRepository].
/// Updates list, count, totals, loading/error states, and notifies UI.
class CartProvider extends ChangeNotifier {
  final CartRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<CartModel>>? _cartSubscription;

  List<CartModel> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Totals
  int _cartCount = 0;
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _grandTotal = 0.0;

  // Track per-item processing state for quantity adjustments or removals
  final Map<String, bool> _itemProcessingStates = {};

  CartProvider({CartRepository? repository})
      : _repository = repository ?? CartRepository(service: CartService()) {
    _listenToAuthChanges();
  }

  // --- Getters ---
  List<CartModel> get cartItems => List.unmodifiable(_cartItems);
  int get cartCount => _cartCount;
  double get subtotal => _subtotal;
  double get discount => _discount;
  double get grandTotal => _grandTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isItemProcessing(String cartItemId) => _itemProcessingStates[cartItemId] ?? false;

  /// Checks if a product exists locally in the cart.
  bool cartItemExists(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  /// Sets up initial cart items manually (e.g. for testing or offline recovery).
  void setCartItems(List<CartModel> items) {
    _cartItems = List.from(items);
    calculateTotals();
    notifyListeners();
  }

  /// Listens to auth state changes to start/stop the cart real-time subscription
  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToCart(user.uid);
      } else {
        _unsubscribeAndClear();
      }
    });
  }

  /// Subscribes to the real-time cart stream from the repository
  void _subscribeToCart(String userId) {
    _cartSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _cartSubscription = _repository.watchCart(userId).listen(
      (cartModels) {
        _cartItems = cartModels;
        _isLoading = false;
        _errorMessage = null;
        calculateTotals();
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Cancels subscription and clears local cache upon sign-out
  void _unsubscribeAndClear() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
    _cartItems = [];
    _isLoading = false;
    _errorMessage = null;
    _itemProcessingStates.clear();
    calculateTotals();
    notifyListeners();
  }

  // =========================================================
  // ACTIONS
  // =========================================================

  /// Loads cart manually once (primarily for specific manual triggers or fallbacks)
  Future<void> loadCart(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cartItems = await _repository.getUserCart(userId);
      calculateTotals();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a product to the cart. Returns `true` if successful, `false` otherwise.
  Future<bool> addToCart(String userId, ProductModel product, {int quantity = 1}) async {
    if (userId.isEmpty) {
      _errorMessage = 'Login required to add items to cart.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addToCart(userId, product, quantity: quantity);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Validates a product's quantity directly against Firestore state.
  Future<void> validateQuantity(String productId, int quantity) async {
    try {
      await _repository.validateQuantity(productId, quantity);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches available stock for a product from the database.
  Future<int> getAvailableStock(String productId) async {
    try {
      return await _repository.getAvailableStock(productId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Removes an item from the cart.
  Future<void> removeItem(String cartItemId) async {
    _setProcessing(cartItemId, true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.removeItem(cartItemId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(cartItemId, false);
    }
  }

  /// Increments quantity by 1.
  Future<void> increaseQuantity(String cartItemId) async {
    _setProcessing(cartItemId, true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.increaseQuantity(cartItemId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(cartItemId, false);
    }
  }

  /// Decrements quantity by 1.
  Future<void> decreaseQuantity(String cartItemId) async {
    _setProcessing(cartItemId, true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.decreaseQuantity(cartItemId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(cartItemId, false);
    }
  }

  /// Updates quantity of an item to a specific value.
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    _setProcessing(cartItemId, true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateQuantity(cartItemId: cartItemId, quantity: quantity);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setProcessing(cartItemId, false);
    }
  }

  /// Clears all cart items.
  Future<void> clearCart(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.clearCart(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recalculates cart total, subtotal, discount savings, and total items in memory.
  void calculateTotals() {
    _cartCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final calculatedGrandTotal = _cartItems.fold(0.0, (sum, item) => sum + (item.discountPrice * item.quantity));
    _grandTotal = calculatedGrandTotal;
    _discount = _subtotal - _grandTotal;
    if (_discount < 0) {
      _discount = 0.0;
    }
  }

  void _setProcessing(String cartItemId, bool value) {
    _itemProcessingStates[cartItemId] = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cartSubscription?.cancel();
    super.dispose();
  }
}
