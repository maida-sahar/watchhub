/// Centralized route name registry. Nothing in the app should use a raw
/// string literal for a route name -- always reference these constants,
/// so a rename never has to hunt through the codebase.
class AppRoutes {
  AppRoutes._();

  // --- Auth / bootstrap ---
  static const String splash = '/splash';
  static const String login = '/login'; 
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String authError = '/auth-error';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String search = '/search';

  // --- Customer area (guarded: role == customer) ---
  static const String customerHome = '/customer/home';
  static const String customerCategories = '/customer/categories';
  static const String customerBrands = '/customer/brands';
  static const String brandDetails = '/customer/brand-details';
  static const String customerProducts = '/customer/products';
  static const String customerWishlist = '/customer/wishlist';
  static const String customerCart = '/customer/cart';
  static const String customerOrders = '/customer/orders';
  static const String orderDetails = '/customer/order-details';
  static const String customerProfile = '/customer/profile';
  static const String customerSupport = '/customer/support';
  static const String customerCheckout = '/customer/checkout';
  static const String customerShippingAddress = '/customer/shipping-address';
  static const String customerDeliveryMethod = '/customer/delivery-method';
  static const String customerOrderReview = '/customer/order-review';
  static const String customerOrderSuccess = '/customer/order-success';
  static const String productDetails = '/customer/product-details';

  /// All routes only a customer may enter. Used by [RouteGuard].
  static const Set<String> customerOnlyRoutes = {
    customerHome,
    customerCategories,
    customerBrands,
    brandDetails,
    customerProducts,
    customerWishlist,
    customerCart,
    customerOrders,
    orderDetails,
    customerProfile,
    customerSupport,
    customerCheckout,
    customerShippingAddress,
    customerDeliveryMethod,
    customerOrderReview,
    customerOrderSuccess,
    productDetails,
    notificationSettings,
  };

  // --- Admin area (guarded: role == admin) ---
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminBrands = '/admin/brands';
  static const String adminAddBrand = '/admin/add-brand';
  static const String adminEditBrand = '/admin/edit-brand';
  static const String adminCoupons = '/admin/coupons';
  static const String adminOrders = '/admin/orders';
  static const String adminCustomers = '/admin/customers';
  static const String adminReports = '/admin/reports';
  static const String adminReviews = '/admin/reviews';
  static const String adminSettings = '/admin/settings';
  static const String adminWishlistAnalytics = '/admin/wishlist-analytics';

  /// All routes only an admin may enter. Used by [RouteGuard].
  static const Set<String> adminOnlyRoutes = {
    adminDashboard,
    adminProducts,
    adminCategories,
    adminBrands,
    adminAddBrand,
    adminEditBrand,
    adminCoupons,
    adminOrders,
    adminCustomers,
    adminReports,
    adminReviews,
    adminSettings,
    adminWishlistAnalytics,
  };
}