import 'package:get/get.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';
import 'package:atlas/modules/home/controllers/home_controller.dart';
import 'package:atlas/modules/category/controllers/category_controller.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
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
    // Was created inside HomeScreen.build — a dependency must not be registered
    // from a build method.
    Get.lazyPut<BrandsController>(() => BrandsController());
    Get.lazyPut<ProductDetailController>(() => ProductDetailController());

    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<FavoritesController>(() => FavoritesController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    // Eagerly created so an existing session is refreshed from /users/me at
    // launch and a dead token is cleared before any screen renders.
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
