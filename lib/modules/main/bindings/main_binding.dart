import 'package:get/get.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';
import 'package:atlas/modules/home/controllers/home_controller.dart';
import 'package:atlas/modules/category/controllers/category_controller.dart';
import 'package:atlas/modules/product_detail/controllers/product_detail_controller.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/auth/controllers/auth_controller.dart';
import 'package:atlas/core/services/catalog_service.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CatalogService(), permanent: true);
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<CategoryController>(() => CategoryController());
    Get.lazyPut<ProductDetailController>(() => ProductDetailController());

    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<FavoritesController>(() => FavoritesController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
