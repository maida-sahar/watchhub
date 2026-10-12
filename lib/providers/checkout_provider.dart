import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/checkout_model.dart';
import '../models/order_model.dart';
import '../repositories/checkout_repository.dart';

/// Provider for managing state of Checkout and Shipping Addresses in WatchHub.
///
/// Follows Clean Architecture by interacting ONLY with the [CheckoutRepository].
/// Real-time syncs addresses, default address, loading/error status, and notifies UI.
class CheckoutProvider extends ChangeNotifier {
  final CheckoutRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<ShippingAddress>>? _addressSubscription;

  List<ShippingAddress> _addresses = [];
  ShippingAddress? _defaultAddress;
  CheckoutModel? _currentCheckout;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  DeliveryMethod? _selectedDeliveryMethod;
  String? _placedOrderId;
  DateTime? _placedOrderDeliveryDate;
  
  double _taxRate = 0.0;
  double _defaultDeliveryCharge = 5.0;

  /// Available payment methods, per the PRD (Cash on Delivery / Credit Card /
  /// Debit Card / Online Payment). This app does not integrate a real card
  /// processor — selecting Credit/Debit/Online Payment simply records the
  /// customer's chosen method on the order for fulfillment purposes, the
  /// same way Cash on Delivery already worked.
  static const List<String> availablePaymentMethods = [
    'Cash on Delivery',
    'Credit Card',
    'Debit Card',
    'Online Payment',
  ];

  /// Available delivery methods
  static const List<DeliveryMethod> availableDeliveryMethods = [
    DeliveryMethod(
      id: 'standard',
      title: 'Standard Delivery',
      description: 'Delivery in 3-5 business days',
      estimatedDeliveryDays: 5,
      deliveryCharge: 5.0,
      isAvailable: true,
    ),
    DeliveryMethod(
      id: 'express',
      title: 'Express Delivery',
      description: 'Delivery in 1-2 business days',
      estimatedDeliveryDays: 2,
      deliveryCharge: 15.0,
      isAvailable: true,
    ),
    DeliveryMethod(
      id: 'same_day',
      title: 'Same Day Delivery',
      description: 'Same day delivery service (Coming Soon)',
      estimatedDeliveryDays: 0,
      deliveryCharge: 25.0,
      isAvailable: false,
    ),
    DeliveryMethod(
      id: 'store_pickup',
      title: 'Store Pickup',
      description: 'Pick up from nearest branch (Coming Soon)',
      estimatedDeliveryDays: 0,
      deliveryCharge: 0.0,
      isAvailable: false,
    ),
  ];

  // ignore: prefer_initializing_formals
  CheckoutProvider({required CheckoutRepository repository}) : _repository = repository {
    _listenToAuthChanges();
  }

  // =========================================================
  // GETTERS & SETTERS
  // =========================================================

  List<ShippingAddress> get addresses => List.unmodifiable(_addresses);
  ShippingAddress? get defaultAddress => _defaultAddress;
  CheckoutModel? get currentCheckout => _currentCheckout;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  DeliveryMethod? get selectedDeliveryMethod => _selectedDeliveryMethod;
  String? get placedOrderId => _placedOrderId;
  DateTime? get placedOrderDeliveryDate => _placedOrderDeliveryDate;

  /// Selects the payment method for the active checkout.
  void selectPaymentMethod(String method) {
    if (!availablePaymentMethods.contains(method)) return;
    if (_currentCheckout != null) {
      _currentCheckout = _currentCheckout!.copyWith(paymentMethod: method);
      notifyListeners();
    }
  }

  /// Changes the currently selected shipping address for the active checkout.
  void selectShippingAddress(ShippingAddress address) {
    if (_currentCheckout != null) {
      _currentCheckout = _currentCheckout!.copyWith(shippingAddress: address);
      notifyListeners();
    }
  }

  /// Sets error message explicitly if needed.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================
  // ACTIONS & METHODS
  // =========================================================

  /// Listens to auth changes to bind/unbind address stream dynamically.
  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        watchAddresses(userId: user.uid);
      } else {
        _currentUserId = null;
        _addresses = [];
        _defaultAddress = null;
        _currentCheckout = null;
        _errorMessage = null;
        _selectedDeliveryMethod = null;
        _placedOrderId = null;
        _placedOrderDeliveryDate = null;
        _addressSubscription?.cancel();
        _addressSubscription = null;
        notifyListeners();
      }
    });
  }

  /// Subscribes to real-time address streams.
  void watchAddresses({String? userId}) {
    final uid = userId ?? _currentUserId;
    if (uid == null || uid.isEmpty) return;

    _addressSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _addressSubscription = _repository.watchAddresses(uid).listen(
      (list) {
        _addresses = list;
        _isLoading = false;
        _errorMessage = null;
        _updateDefaultAddressField();
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Manually loads user addresses.
  Future<void> loadAddresses() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'Login required to fetch addresses.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _repository.getUserAddresses(uid);
      _updateDefaultAddressField();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new address for the active user.
  Future<bool> addAddress(ShippingAddress address) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveAddress(address);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing address.
  Future<bool> updateAddress(ShippingAddress address) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateAddress(address);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a specific address.
  Future<bool> deleteAddress(String addressId) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteAddress(uid, addressId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets an address as the default one.
  Future<bool> setDefaultAddress(String addressId) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'Session expired. Please log in again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setDefaultAddress(uid, addressId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a delivery method and dynamically updates current checkout subtotal calculations.
  void selectDeliveryMethod(DeliveryMethod method) {
    if (!method.isAvailable) return;
    _selectedDeliveryMethod = method;
    if (_currentCheckout != null) {
      final actualMethod = method.id == 'standard'
          ? method.copyWith(deliveryCharge: _defaultDeliveryCharge)
          : method;
      _currentCheckout = _repository.prepareCheckout(
        userId: _currentCheckout!.userId,
        cartItems: _currentCheckout!.cartItems,
        shippingAddress: _currentCheckout!.shippingAddress,
        deliveryMethod: actualMethod,
        taxRate: _taxRate,
        defaultDeliveryCharge: _defaultDeliveryCharge,
      );
    }
    notifyListeners();
  }

  /// In-memory calculates totals and structures the active checkout summary.
  Future<void> prepareCheckout(List<CartModel> cartItems) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _errorMessage = 'Authentication required.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _placedOrderId = null;
    _placedOrderDeliveryDate = null;
    _isLoading = true;
    notifyListeners();

    double taxRate = 0.0;
    double defaultDeliveryCharge = 5.0;

    try {
      final adminDoc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
      if (adminDoc.exists && adminDoc.data() != null) {
        final data = adminDoc.data()!;
        taxRate = (data['taxRate'] as num?)?.toDouble() ?? 0.0;
        defaultDeliveryCharge = (data['defaultDeliveryCharge'] as num?)?.toDouble() ?? 5.0;
      }
    } catch (_) {
      // Safe fallback
    }

    _taxRate = taxRate;
    _defaultDeliveryCharge = defaultDeliveryCharge;

    final defaultMethod = _selectedDeliveryMethod ??
        availableDeliveryMethods.firstWhere((m) => m.id == 'standard');
    _selectedDeliveryMethod = defaultMethod;

    final actualDeliveryMethod = defaultMethod.id == 'standard'
        ? defaultMethod.copyWith(deliveryCharge: defaultDeliveryCharge)
        : defaultMethod;

    _currentCheckout = _repository.prepareCheckout(
      userId: uid,
      cartItems: cartItems,
      shippingAddress: _defaultAddress,
      deliveryMethod: actualDeliveryMethod,
      taxRate: taxRate,
      defaultDeliveryCharge: defaultDeliveryCharge,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Checks validation against real-time database state before placing order.
  Future<bool> validateCheckout() async {
    final checkout = _currentCheckout;
    if (checkout == null) {
      _errorMessage = 'No active checkout session found.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.validateCheckout(
        userId: checkout.userId,
        addressId: checkout.shippingAddress?.id,
        cartItems: checkout.cartItems,
        deliveryMethod: checkout.deliveryMethod,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real transactional checkout placement and cart clearing.
  Future<bool> placeOrder() async {
    final checkout = _currentCheckout;
    if (checkout == null) {
      _errorMessage = 'No active checkout session.';
      notifyListeners();
      return false;
    }
    if (checkout.shippingAddress == null) {
      _errorMessage = 'Shipping address is required.';
      notifyListeners();
      return false;
    }
    if (checkout.deliveryMethod == null) {
      _errorMessage = 'Delivery method selection is required.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Double check business rules validation
      await _repository.validateCheckout(
        userId: checkout.userId,
        addressId: checkout.shippingAddress!.id,
        cartItems: checkout.cartItems,
        deliveryMethod: checkout.deliveryMethod,
      );

      final estDeliveryDays = checkout.deliveryMethod!.estimatedDeliveryDays;
      final estDeliveryDate = DateTime.now().add(Duration(days: estDeliveryDays));

      // 2. Build final order document map model
      final order = OrderModel(
        orderId: '',
        userId: checkout.userId,
        items: checkout.cartItems,
        shippingAddress: checkout.shippingAddress!,
        deliveryMethod: checkout.deliveryMethod!,
        subtotal: checkout.subtotal,
        discount: checkout.discount,
        couponDiscount: checkout.couponDiscount,
        shippingCharge: checkout.shippingCharge,
        tax: checkout.tax,
        grandTotal: checkout.grandTotal,
        currency: checkout.currency,
        paymentMethod: checkout.paymentMethod,
        paymentStatus: 'pending',
        orderStatus: 'pending',
        estimatedDeliveryDate: estDeliveryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Place order via transactional DB batch
      final orderId = await _repository.placeOrder(order);

      // 4. Save placed metadata and reset checkout state
      _placedOrderId = orderId;
      _placedOrderDeliveryDate = estDeliveryDate;
      _currentCheckout = null;
      _selectedDeliveryMethod = null;

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to maintain default address updates and checkout reference synchronization.
  void _updateDefaultAddressField() {
    if (_addresses.isEmpty) {
      _defaultAddress = null;
    } else {
      final matches = _addresses.where((a) => a.isDefault).toList();
      _defaultAddress = matches.isNotEmpty ? matches.first : _addresses.first;
    }

    // Automatically assigns the default address to active checkout if it does not have one yet
    if (_currentCheckout != null && _currentCheckout!.shippingAddress == null && _defaultAddress != null) {
      _currentCheckout = _currentCheckout!.copyWith(shippingAddress: _defaultAddress);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _addressSubscription?.cancel();
    super.dispose();
  }
}