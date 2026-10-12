import '../models/cart_model.dart';
import '../models/checkout_model.dart';
import '../models/order_model.dart';
import '../services/checkout_service.dart';

/// Exception specific to high-level checkout repository operations.
class CheckoutException implements Exception {
  final String message;
  const CheckoutException(this.message);

  @override
  String toString() => message;
}

/// Checkout repository to handle business logic, address CRUD, validations, and mapping.
class CheckoutRepository {
  final CheckoutService _service;

  // ignore: prefer_initializing_formals
  CheckoutRepository({required CheckoutService service}) : _service = service;

  /// Exposes a real-time stream of all user shipping addresses.
  Stream<List<ShippingAddress>> watchAddresses(String userId) {
    return _service.watchAddresses(userId);
  }

  /// Fetches the user's shipping addresses once.
  Future<List<ShippingAddress>> getUserAddresses(String userId) async {
    try {
      return await _service.getUserAddresses(userId);
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  /// Saves a new address, enforcing validations and a maximum limit of 5 addresses.
  Future<ShippingAddress> saveAddress(ShippingAddress address) async {
    _validateAddressFields(address);

    try {
      final list = await _service.getUserAddresses(address.userId);
      
      // Enforce: Maximum 5 addresses limit
      if (list.length >= 5) {
        throw const CheckoutException('Maximum limit of 5 addresses reached. Please delete an address to add a new one.');
      }

      // Enforce: Duplicate checking
      final isDuplicate = list.any((existing) =>
          existing.streetAddress.trim().toLowerCase() == address.streetAddress.trim().toLowerCase() &&
          existing.city.trim().toLowerCase() == address.city.trim().toLowerCase() &&
          existing.area.trim().toLowerCase() == address.area.trim().toLowerCase());
      if (isDuplicate) {
        throw const CheckoutException('A duplicate shipping address already exists.');
      }

      return await _service.saveAddress(address);
    } catch (e) {
      if (e is CheckoutException) rethrow;
      throw CheckoutException(e.toString());
    }
  }

  /// Updates an existing address.
  Future<void> updateAddress(ShippingAddress address) async {
    _validateAddressFields(address);

    try {
      final list = await _service.getUserAddresses(address.userId);
      
      // Enforce: Duplicate checking (excluding current address)
      final isDuplicate = list.any((existing) =>
          existing.id != address.id &&
          existing.streetAddress.trim().toLowerCase() == address.streetAddress.trim().toLowerCase() &&
          existing.city.trim().toLowerCase() == address.city.trim().toLowerCase() &&
          existing.area.trim().toLowerCase() == address.area.trim().toLowerCase());
      if (isDuplicate) {
        throw const CheckoutException('Another shipping address with these details already exists.');
      }

      await _service.updateAddress(address);
    } catch (e) {
      if (e is CheckoutException) rethrow;
      throw CheckoutException(e.toString());
    }
  }

  /// Deletes an address.
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _service.deleteAddress(userId, addressId);
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  /// Designates a specific address as the user's default address.
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await _service.setDefaultAddress(userId, addressId);
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  /// Fetches the user's default address once.
  Future<ShippingAddress?> getDefaultAddress(String userId) async {
    try {
      return await _service.getDefaultAddress(userId);
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  /// Enforces checkout business validation rules.
  Future<void> validateCheckout({
    required String userId,
    required String? addressId,
    required List<CartModel> cartItems,
    DeliveryMethod? deliveryMethod,
  }) async {
    try {
      await _service.validateCheckout(
        userId: userId,
        addressId: addressId,
        cartItems: cartItems,
        deliveryMethod: deliveryMethod,
      );
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  CheckoutModel prepareCheckout({
    required String userId,
    required List<CartModel> cartItems,
    required ShippingAddress? shippingAddress,
    DeliveryMethod? deliveryMethod,
    double taxRate = 0.0,
    double defaultDeliveryCharge = 5.0,
  }) {
    return _service.prepareCheckout(
      userId: userId,
      cartItems: cartItems,
      shippingAddress: shippingAddress,
      deliveryMethod: deliveryMethod,
      taxRate: taxRate,
      defaultDeliveryCharge: defaultDeliveryCharge,
    );
  }

  /// Transactional order placement wrapper.
  Future<String> placeOrder(OrderModel order) async {
    try {
      return await _service.placeOrder(order);
    } catch (e) {
      throw CheckoutException(e.toString());
    }
  }

  /// Internal address validation helper.
  void _validateAddressFields(ShippingAddress address) {
    if (address.fullName.trim().isEmpty) {
      throw const CheckoutException('Full Name is required.');
    }
    if (address.phone.trim().isEmpty) {
      throw const CheckoutException('Phone Number is required.');
    }
    
    // Normalizes input to strip whitespaces/dashes before regex validation
    final normalizedPhone = address.phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(normalizedPhone)) {
      throw const CheckoutException('Invalid phone number format. Please enter a valid number (e.g. +1234567890).');
    }

    if (address.alternatePhone != null && address.alternatePhone!.trim().isNotEmpty) {
      final normalizedAltPhone = address.alternatePhone!.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phoneRegex.hasMatch(normalizedAltPhone)) {
        throw const CheckoutException('Invalid alternate phone number format.');
      }
    }

    if (address.country.trim().isEmpty) {
      throw const CheckoutException('Country is required.');
    }
    if (address.province.trim().isEmpty) {
      throw const CheckoutException('Province is required.');
    }
    if (address.city.trim().isEmpty) {
      throw const CheckoutException('City is required.');
    }
    if (address.area.trim().isEmpty) {
      throw const CheckoutException('Area/Neighborhood is required.');
    }
    if (address.streetAddress.trim().isEmpty) {
      throw const CheckoutException('Street Address is required.');
    }
    
    final normalizedPostalCode = address.postalCode.trim();
    if (normalizedPostalCode.isEmpty) {
      throw const CheckoutException('Postal Code is required.');
    }
    if (normalizedPostalCode.length < 3 || normalizedPostalCode.length > 10) {
      throw const CheckoutException('Postal Code must be between 3 and 10 characters.');
    }
  }
}
