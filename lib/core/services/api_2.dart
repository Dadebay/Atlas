import 'api_constants.dart';

class Api2 {
  static String get baseUrl => ApiConstants.baseUrl;

  //==================== AUTH (passwordless / OTP) ====================//
  /// POST — asks the server to SMS a 4 digit code. Answers HTTP 201.
  static const String sendCode = 'users/send-code';

  /// POST — verifies the code. Signs in, registering the phone if it is new.
  /// Answers HTTP 201 with `{ user, accessToken }`.
  static const String otpLogin = 'users/otp-login';

  /// GET — the signed in customer. Requires the bearer token.
  static const String me = 'users/me';

  /// PATCH — updates the profile. `username` is the only writable field.
  static const String updateUser = 'users';

  /// PATCH — registers the Firebase messaging token for the customer.
  static const String fcmToken = 'users/fcm-token';

  static const String upload = 'files/upload';

  // Brands
  static const String brands = 'brands';
  static String brandById(int id) => 'brands/$id';

  // Categories
  static const String categories = 'categories';
  static const String categoriesTree = 'categories/tree';
  static const String categoriesTreeByLang = 'categories/tree-by-lang';
  static String categoryById(int id) => 'categories/$id';

  // Products
  static const String productsAll = 'products/all';

  // Hero slides
  static const String heroSlides = 'hero-slides';
}
