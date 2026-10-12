import 'notification_model.dart';

class AppPreferences {
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', etc.
  final bool compactMode;

  const AppPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.compactMode = false,
  });

  factory AppPreferences.fromMap(Map<String, dynamic> map) {
    return AppPreferences(
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'en',
      compactMode: map['compactMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'compactMode': compactMode,
    };
  }

  AppPreferences copyWith({
    String? theme,
    String? language,
    bool? compactMode,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      compactMode: compactMode ?? this.compactMode,
    );
  }
}

class UserProfileSettings {
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  const UserProfileSettings({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
  });

  factory UserProfileSettings.fromMap(Map<String, dynamic> map) {
    return UserProfileSettings(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
    };
  }

  UserProfileSettings copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    return UserProfileSettings(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class AdminSettings {
  final String storeName;
  final String storeDescription;
  final String phone;
  final String email;
  final String address;
  final String city;
  final bool deliveryAvailable;
  final double defaultDeliveryCharge;
  final bool orderAutoConfirm;
  final bool globalNotificationsEnabled;
  final bool maintenanceMode;
  final String currency; // e.g. 'USD', 'EUR'
  final double taxRate; // percentage, e.g. 5.0 for 5%

  const AdminSettings({
    this.storeName = 'WatchHub Store',
    this.storeDescription = 'Premium Watch Marketplace',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.deliveryAvailable = true,
    this.defaultDeliveryCharge = 5.0,
    this.orderAutoConfirm = true,
    this.globalNotificationsEnabled = true,
    this.maintenanceMode = false,
    this.currency = 'USD',
    this.taxRate = 0.0,
  });

  factory AdminSettings.fromMap(Map<String, dynamic> map) {
    return AdminSettings(
      storeName: map['storeName'] ?? 'WatchHub Store',
      storeDescription: map['storeDescription'] ?? 'Premium Watch Marketplace',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      deliveryAvailable: map['deliveryAvailable'] ?? true,
      defaultDeliveryCharge: (map['defaultDeliveryCharge'] as num?)?.toDouble() ?? 5.0,
      orderAutoConfirm: map['orderAutoConfirm'] ?? true,
      globalNotificationsEnabled: map['globalNotificationsEnabled'] ?? true,
      maintenanceMode: map['maintenanceMode'] ?? false,
      currency: map['currency'] ?? 'USD',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeDescription': storeDescription,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'deliveryAvailable': deliveryAvailable,
      'defaultDeliveryCharge': defaultDeliveryCharge,
      'orderAutoConfirm': orderAutoConfirm,
      'globalNotificationsEnabled': globalNotificationsEnabled,
      'maintenanceMode': maintenanceMode,
      'currency': currency,
      'taxRate': taxRate,
    };
  }

  AdminSettings copyWith({
    String? storeName,
    String? storeDescription,
    String? phone,
    String? email,
    String? address,
    String? city,
    bool? deliveryAvailable,
    double? defaultDeliveryCharge,
    bool? orderAutoConfirm,
    bool? globalNotificationsEnabled,
    bool? maintenanceMode,
    String? currency,
    double? taxRate,
  }) {
    return AdminSettings(
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      defaultDeliveryCharge: defaultDeliveryCharge ?? this.defaultDeliveryCharge,
      orderAutoConfirm: orderAutoConfirm ?? this.orderAutoConfirm,
      globalNotificationsEnabled: globalNotificationsEnabled ?? this.globalNotificationsEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

class SettingsModel {
  final String userId;
  final UserProfileSettings profile;
  final NotificationSettingsModel notifications;
  final AppPreferences appPreferences;
  final AdminSettings admin;

  const SettingsModel({
    required this.userId,
    this.profile = const UserProfileSettings(),
    this.notifications = const NotificationSettingsModel(),
    this.appPreferences = const AppPreferences(),
    this.admin = const AdminSettings(),
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map, String userId) {
    return SettingsModel(
      userId: userId,
      profile: map['profile'] != null
          ? UserProfileSettings.fromMap(Map<String, dynamic>.from(map['profile']))
          : const UserProfileSettings(),
      notifications: map['notifications'] != null
          ? NotificationSettingsModel.fromMap(Map<String, dynamic>.from(map['notifications']))
          : const NotificationSettingsModel(),
      appPreferences: map['appPreferences'] != null
          ? AppPreferences.fromMap(Map<String, dynamic>.from(map['appPreferences']))
          : const AppPreferences(),
      admin: map['admin'] != null
          ? AdminSettings.fromMap(Map<String, dynamic>.from(map['admin']))
          : const AdminSettings(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile': profile.toMap(),
      'notifications': notifications.toMap(),
      'appPreferences': appPreferences.toMap(),
      'admin': admin.toMap(),
    };
  }

  SettingsModel copyWith({
    String? userId,
    UserProfileSettings? profile,
    NotificationSettingsModel? notifications,
    AppPreferences? appPreferences,
    AdminSettings? admin,
  }) {
    return SettingsModel(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      notifications: notifications ?? this.notifications,
      appPreferences: appPreferences ?? this.appPreferences,
      admin: admin ?? this.admin,
    );
  }
}
