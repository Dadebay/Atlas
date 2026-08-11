import 'api_constants.dart';

class Api2 {
  static String get baseUrl => ApiConstants.baseUrl;

  // Authentication endpoints
  static const String sendCode = 'users/send-code';
  static const String register = 'users/register';
  static const String login = 'users/login';
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
