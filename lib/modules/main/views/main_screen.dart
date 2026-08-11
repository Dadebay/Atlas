import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';
import 'package:atlas/modules/home/views/home_screen.dart';
import 'package:atlas/modules/category/views/category_screen.dart';
import 'package:atlas/modules/favorites/views/favorites_screen.dart';
import 'package:atlas/modules/orders/views/order_screen.dart';
import 'package:atlas/modules/profile/views/profile_screen.dart';
import 'package:atlas/widgets/animated_bottom_nav_bar.dart';
import 'package:atlas/widgets/cart_fly_animation.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: const [
              HomeScreen(),
              CategoryScreen(),
              CartScreen(),
              FavoritesScreen(),
              ProfileScreen(),
            ],
          )),
      bottomNavigationBar: Obx(() {
        final cartController = Get.find<CartController>();
        final cartCount = cartController.cartItems.length;

        return AnimatedBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeIndex,
          items: [
            NavBarItemData(
              icon: HugeIcons.strokeRoundedHome09,
              label: 'home'.tr,
            ),
            NavBarItemData(
              icon: HugeIcons.strokeRoundedGridView,
              label: 'category'.tr,
            ),
            NavBarItemData(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              label: 'cart'.tr,
              badgeCount: cartCount,
              iconKey: CartFlyAnimation.cartIconKey,
            ),
            NavBarItemData(
              icon: HugeIcons.strokeRoundedFavourite,
              label: 'favorites'.tr,
            ),
            NavBarItemData(
              icon: HugeIcons.strokeRoundedUser,
              label: 'profile'.tr,
            ),
          ],
        );
      }),
    );
  }
}
