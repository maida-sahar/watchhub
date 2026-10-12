import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';
import 'checkout_model.dart';

/// Represents a customer order in WatchHub.
class OrderModel {
  final String orderId;
  final String userId;
  final List<CartModel> items;
  final ShippingAddress shippingAddress;
  final DeliveryMethod deliveryMethod;
  final double subtotal;
  final double discount;
  final double couponDiscount;
  final double shippingCharge;
  final double tax;
  final double grandTotal;
  final String currency;
  final String paymentMethod; // e.g. 'Cash on Delivery'
  final String paymentStatus; // e.g. 'pending', 'paid', 'failed'
  final String orderStatus;   // e.g. 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
  final DateTime estimatedDeliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.deliveryMethod,
    required this.subtotal,
    required this.discount,
    required this.couponDiscount,
    required this.shippingCharge,
    required this.tax,
    required this.grandTotal,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.estimatedDeliveryDate,
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
    this.cancelledAt,
  });

  OrderModel copyWith({
    String? orderId,
    String? userId,
    List<CartModel>? items,
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
    String? paymentStatus,
    String? orderStatus,
    DateTime? estimatedDeliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    DateTime? cancelledAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'deliveryMethod': deliveryMethod.toMap(),
      'subtotal': subtotal,
      'discount': discount,
      'couponDiscount': couponDiscount,
      'shippingCharge': shippingCharge,
      'tax': tax,
      'grandTotal': grandTotal,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'estimatedDeliveryDate': Timestamp.fromDate(estimatedDeliveryDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final parsedItems = (map['items'] as List?)
            ?.map((e) => CartModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final addressMap = map['shippingAddress'] as Map<String, dynamic>?;
    final deliveryMap = map['deliveryMethod'] as Map<String, dynamic>?;

    if (addressMap == null) {
      throw ArgumentError('OrderModel validation failed: shippingAddress is required.');
    }
    if (deliveryMap == null) {
      throw ArgumentError('OrderModel validation failed: deliveryMethod is required.');
    }

    return OrderModel(
      orderId: documentId ?? (map['orderId'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      items: parsedItems,
      shippingAddress: ShippingAddress.fromMap(addressMap),
      deliveryMethod: DeliveryMethod.fromMap(deliveryMap),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      couponDiscount: (map['couponDiscount'] as num?)?.toDouble() ?? 0.0,
      shippingCharge: (map['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      orderStatus: map['orderStatus'] as String? ?? 'pending',
      estimatedDeliveryDate: _parseDateTime(map['estimatedDeliveryDate']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      cancellationReason: map['cancellationReason'] as String?,
      cancelledAt: map['cancelledAt'] != null ? _parseDateTime(map['cancelledAt']) : null,
    );
  }

  String toJson() => json.encode(toMapForJson());

  Map<String, dynamic> toMapForJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toMapForJson()).toList(),
      'shippingAddress': shippingAddress.toMapForJson(),
      'deliveryMethod': deliveryMethod.toMap(),
      'subtotal': subtotal,
      'discount': discount,
      'couponDiscount': couponDiscount,
      'shippingCharge': shippingCharge,
      'tax': tax,
      'grandTotal': grandTotal,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromJson(String source) =>
      OrderModel.fromMap(json.decode(source) as Map<String, dynamic>);

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
    return 'OrderModel(orderId: $orderId, userId: $userId, grandTotal: $grandTotal, orderStatus: $orderStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.orderId == orderId &&
        other.userId == userId &&
        other.subtotal == subtotal &&
        other.discount == discount &&
        other.couponDiscount == couponDiscount &&
        other.shippingCharge == shippingCharge &&
        other.tax == tax &&
        other.grandTotal == grandTotal &&
        other.currency == currency &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus &&
        other.orderStatus == orderStatus &&
        other.estimatedDeliveryDate == estimatedDeliveryDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        _isCartItemsEqual(other.items, items) &&
        other.shippingAddress == shippingAddress &&
        other.deliveryMethod == deliveryMethod &&
        other.cancellationReason == cancellationReason &&
        other.cancelledAt == cancelledAt;
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
      orderId,
      userId,
      subtotal,
      discount,
      couponDiscount,
      shippingCharge,
      tax,
      grandTotal,
      currency,
      paymentMethod,
      paymentStatus,
      orderStatus,
      estimatedDeliveryDate,
      createdAt,
      updatedAt,
      Object.hashAll(items),
      shippingAddress,
      deliveryMethod,
      cancellationReason,
      cancelledAt,
    ]);
  }
}
