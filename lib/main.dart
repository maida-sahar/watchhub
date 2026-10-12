import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/providers/product_provider.dart';
import 'package:watch_hub/repositories/product_repository.dart';
import 'package:watch_hub/services/product_service.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth Imports
import 'providers/auth_provider.dart';

// Category Module Imports
import 'providers/category_provider.dart';
import 'repositories/category_repository.dart';
import 'services/category_service.dart';

// Brand Module Imports
import 'providers/brand_provider.dart';
import 'repositories/brand_repository.dart';
import 'services/brand_service.dart';

// Wishlist Module Imports
import 'providers/wishlist_provider.dart';
import 'repositories/wishlist_repository.dart';
import 'services/wishlist_service.dart';

// Cart Module Imports
import 'providers/cart_provider.dart';
import 'repositories/cart_repository.dart';
import 'services/cart_service.dart';

// Checkout Module Imports
import 'providers/checkout_provider.dart';
import 'repositories/checkout_repository.dart';
import 'services/checkout_service.dart';

// Orders Module Imports
import 'providers/order_provider.dart';
import 'repositories/order_repository.dart';
import 'services/order_service.dart';
import 'services/firestore_service.dart';

// Customers Module Imports
import 'providers/user_provider.dart';
import 'repositories/user_repository.dart';
import 'services/user_service.dart';

// Reviews Module Imports
import 'providers/review_provider.dart';
import 'repositories/review_repository.dart';
import 'services/review_service.dart';

// Notifications Module Imports
import 'providers/notification_provider.dart';
import 'repositories/notification_repository.dart';
import 'services/notification_service.dart';

// Settings Module Imports
import 'providers/settings_provider.dart';
import 'repositories/settings_repository.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://igwfwnclpairglgojeoo.supabase.co',
    anonKey: 'sb_publishable_rKE7LY11G-Ee-9NdXUq6UA_r7G-grdT',
 );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        
        // --- Category Module Chain -------------------------------
        // Service -> Repository -> Provider
        // (existing Category providers...)
        Provider<CategoryService>(
          create: (_) => CategoryService(),
        ),
        ProxyProvider<CategoryService, CategoryRepository>(
          update: (_, service, __) => CategoryRepository(service: service),
        ),
        ChangeNotifierProxyProvider<CategoryRepository, CategoryProvider>(
          create: (context) => CategoryProvider(
            repository: context.read<CategoryRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? CategoryProvider(repository: repository),
        ),

        // --- Brand Module Chain ----------------------------------
        // Service -> Repository -> Provider
        // (existing Brand providers...)
        Provider<BrandService>(
          create: (_) => BrandService(),
        ),
        ProxyProvider<BrandService, BrandRepository>(
          update: (_, service, __) => BrandRepository(service: service),
        ),
        ChangeNotifierProxyProvider<BrandRepository, BrandProvider>(
          create: (context) => BrandProvider(
            repository: context.read<BrandRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? BrandProvider(repository: repository),
        ),

         Provider<ProductService>(
          create: (_) => ProductService(),
        ),
        ProxyProvider<ProductService, ProductRepository>(
          update: (_, service, __) => ProductRepository(service: service),
        ),
        ChangeNotifierProxyProvider<ProductRepository, ProductProvider>(
          create: (context) => ProductProvider(
            repository: context.read<ProductRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? ProductProvider(repository: repository),
        ),

        // --- Wishlist Module Chain -------------------------------
        // Service -> Repository -> Provider
        // (existing Wishlist providers...)
        Provider<WishlistService>(
          create: (_) => WishlistService(),
        ),
        ProxyProvider<WishlistService, WishlistRepository>(
          update: (_, service, __) => WishlistRepository(service: service),
        ),
        ChangeNotifierProxyProvider<WishlistRepository, WishlistProvider>(
          create: (context) => WishlistProvider(
            repository: context.read<WishlistRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? WishlistProvider(repository: repository),
        ),

        // --- Cart Module Chain -----------------------------------
        // Service -> Repository -> Provider
        // (existing Cart providers...)
        Provider<CartService>(
          create: (_) => CartService(),
        ),
        ProxyProvider<CartService, CartRepository>(
          update: (_, service, __) => CartRepository(service: service),
        ),
        ChangeNotifierProxyProvider<CartRepository, CartProvider>(
          create: (context) => CartProvider(
            repository: context.read<CartRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? CartProvider(repository: repository),
        ),

        // --- Checkout Module Chain -------------------------------
        // Service -> Repository -> Provider
        // (existing Checkout providers...)
        Provider<CheckoutService>(
          create: (_) => CheckoutService(),
        ),
        ProxyProvider<CheckoutService, CheckoutRepository>(
          update: (_, service, __) => CheckoutRepository(service: service),
        ),
        ChangeNotifierProxyProvider<CheckoutRepository, CheckoutProvider>(
          create: (context) => CheckoutProvider(
            repository: context.read<CheckoutRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? CheckoutProvider(repository: repository),
        ),

        // --- Notifications Module Chain --------------------------
        // Service -> Repository -> Provider
        // Registered before Orders below because OrderProvider optionally
        // reads NotificationRepository (to auto-send "Order Shipped" etc.
        // notifications on status change) — Provider lookups can only see
        // providers declared earlier in this list.
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ProxyProvider<NotificationService, NotificationRepository>(
          update: (_, service, __) => NotificationRepository(service: service),
        ),
        ChangeNotifierProxyProvider<NotificationRepository, NotificationProvider>(
          create: (context) => NotificationProvider(
            repository: context.read<NotificationRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? NotificationProvider(repository: repository),
        ),

        // --- Orders Module Chain ---------------------------------
        // Service -> Repository -> Provider
        // OrderRepository additionally depends on FirestoreService
        // (already the app's single owner of `users` collection
        // reads/writes) so the Admin Order Details screen can look up
        // a customer's profile via Provider -> Repository, without any
        // UI layer touching Firebase or a foreign service directly.
        Provider<OrderService>(
          create: (_) => OrderService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        ProxyProvider2<OrderService, FirestoreService, OrderRepository>(
          update: (_, service, firestoreService, __) => OrderRepository(
            service: service,
            firestoreService: firestoreService,
          ),
        ),
        ChangeNotifierProxyProvider<OrderRepository, OrderProvider>(
          create: (context) => OrderProvider(
            repository: context.read<OrderRepository>(),
            notificationRepository: context.read<NotificationRepository>(),
          ),
          update: (context, repository, previous) =>
              previous ??
              OrderProvider(
                repository: repository,
                notificationRepository: context.read<NotificationRepository>(),
              ),
        ),

        // --- Customers Module Chain ------------------------------
        // Service -> Repository -> Provider
        // UserProvider additionally depends on OrderRepository to aggregate
        // order stats for users in real time.
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        ProxyProvider<UserService, UserRepository>(
          update: (_, service, __) => UserRepository(service: service),
        ),
        ChangeNotifierProxyProvider2<UserRepository, OrderRepository, UserProvider>(
          create: (context) => UserProvider(
            userRepository: context.read<UserRepository>(),
            orderRepository: context.read<OrderRepository>(),
          ),
          update: (_, userRepository, orderRepository, previous) =>
              previous ??
              UserProvider(
                userRepository: userRepository,
                orderRepository: orderRepository,
              ),
        ),

        // --- Reviews Module Chain --------------------------------
        // Service -> Repository -> Provider
        Provider<ReviewService>(
          create: (_) => ReviewService(),
        ),
        ProxyProvider<ReviewService, ReviewRepository>(
          update: (_, service, __) => ReviewRepository(service: service),
        ),
        ChangeNotifierProxyProvider<ReviewRepository, ReviewProvider>(
          create: (context) => ReviewProvider(
            repository: context.read<ReviewRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? ReviewProvider(repository: repository),
        ),

        // --- Settings Module Chain -------------------------------
        // Service -> Repository -> Provider
        Provider<SettingsService>(
          create: (_) => SettingsService(),
        ),
        ProxyProvider<SettingsService, SettingsRepository>(
          update: (_, service, __) => SettingsRepository(service: service),
        ),
        ChangeNotifierProxyProvider<SettingsRepository, SettingsProvider>(
          create: (context) => SettingsProvider(
            repository: context.read<SettingsRepository>(),
          ),
          update: (_, repository, previous) =>
              previous ?? SettingsProvider(repository: repository),
        ),
      ],
      child: const WatchHubApp(),
    ),
  );
}

class ClayBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ClayBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      borderRadius: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 0, 'Home'),
          _navItem(Icons.search_rounded, 1, 'Search'),
          _navItem(Icons.favorite_border_rounded, 2, 'Wishlist'),
          _navItem(Icons.shopping_bag_rounded, 3, 'Cart'),
          _navItem(Icons.person_outline_rounded, 4, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 26,
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}