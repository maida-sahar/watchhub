import 'package:flutter/material.dart';
import 'package:watch_hub/admin/dashboard/dashboard_screen.dart';
import 'package:watch_hub/admin/products/add_product_screen.dart';
import 'package:watch_hub/admin/products/product_list_screen.dart';
import 'package:watch_hub/screens/home/home_screen.dart';
import 'package:watch_hub/widgets/maintenance_gate.dart';
import 'package:watch_hub/screens/search/search_screen.dart';

import '../core/guards/route_guard.dart';
import '../models/user_model.dart';
import '../models/brand_model.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';

// --- Auth Screens ---
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_error_screen.dart';

// --- Category Module (Admin + Customer) ---
import '../admin/categories/category_list_screen.dart';
import '../screens/categories/category_screen.dart';

// --- Brand Module (Admin + Customer) ---
import '../admin/brands/brand_list_screen.dart';
import '../admin/brands/add_brand_screen.dart';
import '../admin/brands/edit_brand_screen.dart';
import '../screens/brand/brand_details_screen.dart';
import '../screens/brand/brand_screen.dart';

// --- Wishlist Module (Admin + Customer) ---
import '../screens/wishlist/wishlist_screen.dart';
import '../admin/wishlist/wishlist_analytics_screen.dart';

// --- Cart Module (Customer) ---
import '../screens/cart/cart_screen.dart';

// --- Checkout Module (Customer) ---
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/shipping_address_screen.dart';
import '../screens/checkout/delivery_method_screen.dart';
import '../screens/checkout/order_review_screen.dart';
import '../screens/checkout/order_success_screen.dart';

// --- Orders Module (Customer) ---
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_details_screen.dart';
import '../models/order_model.dart';

// --- Orders Module (Admin) ---
import '../admin/orders/orders_screen.dart' ;

// --- Customers Module (Admin) ---
import '../admin/customers/customers_screen.dart';

// --- Reports Module (Admin) ---
import '../admin/reports/reports_dashboard_screen.dart';

// --- Reviews Module (Admin) ---
import '../admin/reviews/reviews_screen.dart';

// --- Notifications Module ---
import '../screens/notifications/notification_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';

// --- Profile & Settings Module ---
import '../screens/profile/profile_settings_screen.dart';
import '../admin/settings/admin_settings_screen.dart';
import '../screens/products/product_details_screen.dart';

/// Single source of truth for building every route in the app.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------------- Auth / Bootstrap ----------------
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);

      case AppRoutes.login:
        return _page(const LoginScreen(), settings);

      case AppRoutes.signup:
        return _page(const SignupScreen(), settings);

      case AppRoutes.forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);

      case AppRoutes.authError:
        return _page(const AuthErrorScreen(), settings);

      // ---------------- Customer Area (Guarded) ----------------
      case AppRoutes.customerHome:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: MaintenanceGate(child: HomeScreen()),
          ),
          settings,
        );

      case AppRoutes.customerCategories:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: CategoryScreen(),
          ),
          settings,
        );

      case AppRoutes.notifications:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: NotificationsScreen(),
          ),
          settings,
        );

      case AppRoutes.customerBrands:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: BrandScreen(),
          ),
          settings,
        );

      case AppRoutes.brandDetails:
        final brand = settings.arguments as BrandModel?;
        if (brand == null) {
          return _errorRoute('Brand details require a valid BrandModel instance.');
        }
        return _page(
          RouteGuard(
            allowedRole: UserRole.customer,
            child: BrandDetailsScreen(brand: brand),
          ),
          settings,
        );

      case AppRoutes.customerProducts:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: ProductListScreen() ,
          ),
          settings,
        );

      case AppRoutes.productDetails:
        final product = settings.arguments as ProductModel?;
        if (product == null) {
          return _errorRoute('Product details require a valid ProductModel instance.');
        }
        final authProvider = navigatorKey.currentContext?.read<AuthProvider>();
        final currentUserId = authProvider?.currentUid ?? '';
        return _page(
          RouteGuard(
            allowedRole: UserRole.customer,
            child: ProductDetailsScreen(product: product, currentUserId: currentUserId),
          ),
          settings,
        );

      case AppRoutes.customerWishlist:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: WishlistScreen(),
          ),
          settings,
        );

      case AppRoutes.customerCart:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: CartScreen(),
          ),
          settings,
        );

      case AppRoutes.customerCheckout:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: CheckoutScreen(),
          ),
          settings,
        );

      case AppRoutes.customerShippingAddress:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: ShippingAddressScreen(),
          ),
          settings,
        );

      case AppRoutes.customerDeliveryMethod:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: DeliveryMethodScreen(),
          ),
          settings,
        );

      case AppRoutes.customerOrderReview:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: OrderReviewScreen(),
          ),
          settings,
        );

      case AppRoutes.customerOrderSuccess:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: OrderSuccessScreen(),
          ),
          settings,
        );

      case AppRoutes.customerOrders:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: OrdersScreen(),
          ),
          settings,
        );

      case AppRoutes.orderDetails:
        final arg = settings.arguments;
        if (arg is OrderModel) {
          return _page(
            RouteGuard(
              allowedRole: UserRole.customer,
              child: OrderDetailsScreen(order: arg),
            ),
            settings,
          );
        } else if (arg is String) {
          return _page(
            RouteGuard(
              allowedRole: UserRole.customer,
              child: OrderDetailsScreen(orderId: arg),
            ),
            settings,
          );
        }
        return _errorRoute('Order details require an OrderModel or String orderId.');

      case AppRoutes.customerProfile:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: ProfileSettingsScreen(),
          ),
          settings,
        );

      case AppRoutes.search:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: SearchScreen(),
          ),
          settings,
        );

      case AppRoutes.notificationSettings:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.customer,
            child: NotificationSettingsScreen(),
          ),
          settings,
        );

      // ---------------- Admin Area (Guarded) ----------------
      case AppRoutes.adminDashboard:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: DashboardScreen(),
          ),
          settings,
        );

      case AppRoutes.adminProducts:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: AddProductScreen(),
          ),
          settings,
        );

      case AppRoutes.adminWishlistAnalytics:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: WishlistAnalyticsScreen(),
          ),
          settings,
        );

      case AppRoutes.adminCategories:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: CategoryListScreen(),
          ),
          settings,
        );

      case AppRoutes.adminBrands:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: BrandListScreen(),
          ),
          settings,
        );

      case AppRoutes.adminAddBrand:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: AddBrandScreen(),
          ),
          settings,
        );

      case AppRoutes.adminEditBrand:
        final brand = settings.arguments as BrandModel?;
        if (brand == null) {
          return _errorRoute('Editing a brand requires a valid BrandModel instance.');
        }
        return _page(
          RouteGuard(
            allowedRole: UserRole.admin,
            child: EditBrandScreen(brand: brand),
          ),
          settings,
        );

      case AppRoutes.adminCoupons:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: _PlaceholderScreen(title: 'Admin Coupons'),
          ),
          settings,
        );

      case AppRoutes.adminOrders:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: AdminOrdersScreen(),
          ),
          settings,
        );

      case AppRoutes.adminCustomers:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: CustomersScreen(),
          ),
          settings,
        );

      case AppRoutes.adminReports:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: ReportsDashboardScreen(),
          ),
          settings,
        );

      case AppRoutes.adminReviews:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: ReviewsScreen(),
          ),
          settings,
        );

      case AppRoutes.adminSettings:
        return _page(
          const RouteGuard(
            allowedRole: UserRole.admin,
            child: AdminSettingsScreen(),
          ),
          settings,
        );

      default:
        return _errorRoute('No route defined for "${settings.name}"');
    }
  }

  static MaterialPageRoute _page(Widget widget, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => widget, settings: settings);
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-in placeholder screen for out-of-scope modules.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen goes here')),
    );
  }
}