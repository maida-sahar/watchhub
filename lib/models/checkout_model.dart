import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';

/// Represents a customer's shipping address in WatchHub.
class ShippingAddress {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? alternatePhone;
  final String country;
  final String province;
  final String city;
  final String area;
  final String streetAddress;
  final String postalCode;
  final String? landmark;
  final String addressType; // e.g., 'Home', 'Office', 'Other'
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShippingAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.alternatePhone,
    required this.country,
    required this.province,
    required this.city,
    required this.area,
    required this.streetAddress,
    required this.postalCode,
    this.landmark,
    required this.addressType,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  ShippingAddress copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? alternatePhone,
    String? country,
    String? province,
    String? city,
    String? area,
    String? streetAddress,
    String? postalCode,
    String? landmark,
    String? addressType,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
      streetAddress: streetAddress ?? this.streetAddress,
      postalCode: postalCode ?? this.postalCode,
      landmark: landmark ?? this.landmark,
      addressType: addressType ?? this.addressType,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'country': country,
      'province': province,
      'city': city,
      'area': area,
      'streetAddress': streetAddress,
      'postalCode': postalCode,
      'landmark': landmark,
      'addressType': addressType,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ShippingAddress(
      id: documentId ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      alternatePhone: map['alternatePhone'] as String?,
      country: map['country'] as String? ?? '',
      province: map['province'] as String? ?? '',
      city: map['city'] as String? ?? '',
      area: map['area'] as String? ?? '',
      streetAddress: map['streetAddress'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      landmark: map['landmark'] as String?,
      addressType: map['addressType'] as String? ?? 'Home',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMapForJson());

  Map<String, dynamic> toMapForJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'country': country,
      'province': province,
      'city': city,
      'area': area,
      'streetAddress': streetAddress,
      'postalCode': postalCode,
      'landmark': landmark,
      'addressType': addressType,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShippingAddress.fromJson(String source) =>
      ShippingAddress.fromMap(json.decode(source) as Map<String, dynamic>);

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'ShippingAddress(id: $id, userId: $userId, fullName: $fullName, phone: $phone, country: $country, city: $city, streetAddress: $streetAddress, addressType: $addressType, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShippingAddress &&
        other.id == id &&
        other.userId == userId &&
        other.fullName == fullName &&
        other.phone == phone &&
        other.alternatePhone == alternatePhone &&
        other.country == country &&
        other.province == province &&
        other.city == city &&
        other.area == area &&
        other.streetAddress == streetAddress &&
        other.postalCode == postalCode &&
        other.landmark == landmark &&
        other.addressType == addressType &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      userId,
      fullName,
      phone,
      alternatePhone,
      country,
      province,
      city,
      area,
      streetAddress,
      postalCode,
      landmark,
      addressType,
      isDefault,
      createdAt,
      updatedAt,
    ]);
  }
}

/// Represents a Delivery Method in WatchHub.
class DeliveryMethod {
  final String id;
  final String title;
  final String description;
  final int estimatedDeliveryDays;
  final double deliveryCharge;
  final bool isAvailable;

  const DeliveryMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedDeliveryDays,
    required this.deliveryCharge,
    required this.isAvailable,
  });

  DeliveryMethod copyWith({
    String? id,
    String? title,
    String? description,
    int? estimatedDeliveryDays,
    double? deliveryCharge,
    bool? isAvailable,
  }) {
    return DeliveryMethod(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedDeliveryDays: estimatedDeliveryDays ?? this.estimatedDeliveryDays,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimatedDeliveryDays': estimatedDeliveryDays,
      'deliveryCharge': deliveryCharge,
      'isAvailable': isAvailable,
    };
  }

  factory DeliveryMethod.fromMap(Map<String, dynamic> map) {
    return DeliveryMethod(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      estimatedDeliveryDays: (map['estimatedDeliveryDays'] as num?)?.toInt() ?? 0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      isAvailable: map['isAvailable'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeliveryMethod.fromJson(String source) =>
      DeliveryMethod.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DeliveryMethod(id: $id, title: $title, deliveryCharge: $deliveryCharge, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryMethod &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.estimatedDeliveryDays == estimatedDeliveryDays &&
        other.deliveryCharge == deliveryCharge &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      title,
      description,
      estimatedDeliveryDays,
      deliveryCharge,
      isAvailable,
    ]);
  }
}

/// Represents the checkout state and calculations in WatchHub.
class CheckoutModel {
  final String id;
  final String userId;
  final List<CartModel> cartItems;
  final ShippingAddress? shippingAddress;
  final DeliveryMethod? deliveryMethod;
  final double subtotal;
  final double discount;
  final double couponDiscount;
  final double shippingCharge;
  final double tax;
  final double grandTotal;
  final String currency;
  final String paymentMethod; // 'Cash on Delivery' | 'Credit Card' | 'Debit Card' | 'Online Payment'
  final String status; // e.g., 'pending', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  const CheckoutModel({
    required this.id,
    required this.userId,
    required this.cartItems,
    this.shippingAddress,
    this.deliveryMethod,
    required this.subtotal,
    required this.discount,
    required this.couponDiscount,
    required this.shippingCharge,
    required this.tax,
    required this.grandTotal,
    required this.currency,
    this.paymentMethod = 'Cash on Delivery',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  CheckoutModel copyWith({
    String? id,
    String? userId,
    List<CartModel>? cartItems,
    ShippingAddress? shippingAddress,
    DeliveryMethod? deliveryMethod,
    double? subtotal,
    double? discount,
    double? couponDiscount,
    double? shippingCharge,
    double? tax,
    double? grandTotal,
    String? currency,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CheckoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cartItems: cartItems ?? this.cartItems,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cartItems': cartItems.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress?.toMap(),
      'deliveryMethod': deliveryMethod?.toMap(),
      'subtotal': subtotal,
      'discount': discount,
      'couponDiscount': couponDiscount,
      'shippingCharge': shippingCharge,
      'tax': tax,
      'grandTotal': grandTotal,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CheckoutModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final parsedCartItems = (map['cartItems'] as List?)
            ?.map((e) => CartModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final addressMap = map['shippingAddress'] as Map<String, dynamic>?;
    final deliveryMap = map['deliveryMethod'] as Map<String, dynamic>?;

    return CheckoutModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      cartItems: parsedCartItems,
      shippingAddress: addressMap != null ? ShippingAddress.fromMap(addressMap) : null,
      deliveryMethod: deliveryMap != null ? DeliveryMethod.fromMap(deliveryMap) : null,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      couponDiscount: (map['couponDiscount'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (map['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash on Delivery',
      status: map['status'] as String? ?? 'pending',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMapForJson());

  Map<String, dynamic> toMapForJson() {
    return {
      'id': id,
      'userId': userId,
      'cartItems': cartItems.map((item) => item.toMapForJson()).toList(),
      'shippingAddress': shippingAddress?.toMapForJson(),
      'deliveryMethod': deliveryMethod?.toMap(),
      'subtotal': subtotal,
      'discount': discount,
      'couponDiscount': couponDiscount,
      'shippingCharge': shippingCharge,
      'tax': tax,
      'grandTotal': grandTotal,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CheckoutModel.fromJson(String source) =>
      CheckoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'CheckoutModel(id: $id, userId: $userId, subtotal: $subtotal, discount: $discount, grandTotal: $grandTotal, status: $status, deliveryMethod: $deliveryMethod)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckoutModel &&
        other.id == id &&
        other.userId == userId &&
        other.subtotal == subtotal &&
        other.discount == discount &&
        other.couponDiscount == couponDiscount &&
        other.shippingCharge == shippingCharge &&
        other.tax == tax &&
        other.grandTotal == grandTotal &&
        other.currency == currency &&
        other.paymentMethod == paymentMethod &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _isCartItemsEqual(other.cartItems, cartItems) &&
        other.shippingAddress == shippingAddress &&
        other.deliveryMethod == deliveryMethod;
  }

  static bool _isCartItemsEqual(List<CartModel> a, List<CartModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      userId,
      subtotal,
      discount,
      couponDiscount,
      shippingCharge,
      tax,
      grandTotal,
      currency,
      paymentMethod,
      status,
      createdAt,
      updatedAt,
      Object.hashAll(cartItems),
      shippingAddress,
      deliveryMethod,
    ]);
  }
}