import 'dart:convert';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/navigation_service.dart';
import 'package:atlas/modules/orders/controllers/order_controller.dart';
import 'package:atlas/widgets/app_dialogs.dart';

class CartController extends GetxController {
  final _api = CallApi();

  var cartItems = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (AuthStorage().isLoggedIn) fetchCart();
  }

  Future<void> fetchCart() async {
    isLoading.value = true;
    try {
      final response = await _api.getData('cart');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = (body['data']?['items'] as List?) ?? [];
        cartItems.value = items
            .whereType<Map<String, dynamic>>()
            .map(_toCartItem)
            .toList();
      } else if (response.statusCode == 401) {
        cartItems.clear();
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Map<String, dynamic> _toCartItem(Map<String, dynamic> item) {
    final rawImg = item['image_url']?.toString() ?? '';
    final imageUrl = rawImg.isEmpty
        ? ''
        : rawImg.startsWith('http')
            ? rawImg
            : ApiConstants.fileUrl(rawImg);
    return {
      'id': item['product_id']?.toString() ?? '',
      'product_id': (item['product_id'] as num?)?.toInt(),
      'title': item['name']?.toString() ?? '',
      'imageUrl': imageUrl,
      'price': double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0.0,
      'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
    };
  }

  Future<void> addItem(Map<String, dynamic> item, {int initialQuantity = 1}) async {
    final idStr = item['id']?.toString() ?? '';
    final productId = int.tryParse(idStr);
    if (productId == null) return;

    final existingIdx =
        cartItems.indexWhere((e) => e['id']?.toString() == idStr);

    if (existingIdx != -1) {
      final currentQty =
          (cartItems[existingIdx]['quantity'] as num?)?.toInt() ?? 1;
      await _patchQuantity(productId, currentQty + initialQuantity, existingIdx);
    } else {
      // Optimistic add
      cartItems.add({
        'id': idStr,
        'product_id': productId,
        'title': item['title']?.toString() ?? '',
        'imageUrl': item['imageUrl']?.toString() ?? '',
        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
        'quantity': initialQuantity,
      });
      try {
        final response = await _api.postData(
          {'product_id': productId, 'quantity': initialQuantity},
          'cart/items',
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          cartItems.removeWhere((e) => e['id']?.toString() == idStr);
        }
      } catch (_) {
        cartItems.removeWhere((e) => e['id']?.toString() == idStr);
      }
    }
  }

  Future<void> updateQuantity(int index, int delta) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final productId = (item['product_id'] as num?)?.toInt();
    final newQty = ((item['quantity'] as num?)?.toInt() ?? 1) + delta;

    if (newQty <= 0) {
      await removeItem(index);
      return;
    }

    if (productId == null) {
      final updated = Map<String, dynamic>.from(item);
      updated['quantity'] = newQty;
      cartItems[index] = updated;
      return;
    }

    await _patchQuantity(productId, newQty, index);
  }

  Future<void> _patchQuantity(int productId, int newQty, int index) async {
    if (index >= 0 && index < cartItems.length) {
      final updated = Map<String, dynamic>.from(cartItems[index]);
      updated['quantity'] = newQty;
      cartItems[index] = updated;
    }
    try {
      await _api.patchData({'quantity': newQty}, 'cart/items/$productId');
    } catch (_) {
      fetchCart();
    }
  }

  Future<void> removeItem(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final productId = (item['product_id'] as num?)?.toInt();
    cartItems.removeAt(index);
    if (productId == null) return;
    try {
      await _api.deleteData('cart/items/$productId');
    } catch (_) {
      fetchCart();
    }
  }

  Future<void> clearCart() async {
    cartItems.clear();
    try {
      await _api.deleteData('cart');
    } catch (_) {}
  }

  double get totalPrice => cartItems.fold(0.0, (sum, item) {
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        return sum + (price * qty);
      });
}

class FavoritesController extends GetxController {
  final _api = CallApi();

  // Local toggle state (used by ProductCard heart button)
  var favoriteItems = <Map<String, dynamic>>[].obs;

  // API liked products (shown in FavoritesScreen)
  var likedProducts = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var errorMsg = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (AuthStorage().isLoggedIn) fetchLikedProducts();
  }

  Future<void> fetchLikedProducts() async {
    isLoading.value = true;
    errorMsg.value = '';
    try {
      final response =
          await _api.getData('products/all?page=1&size=10&liked=true');
      if (response.statusCode == 401) {
        likedProducts.clear();
        favoriteItems.clear();
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        likedProducts.value = items.map((e) {
          final item = e as Map<String, dynamic>;
          final title = item['name']?.toString() ?? '';
          final rawImageUrl = item['image_url']?.toString() ?? '';
          final String imageUrl = rawImageUrl.isEmpty
              ? ''
              : rawImageUrl.startsWith('http')
                  ? rawImageUrl
                  : ApiConstants.fileUrl(rawImageUrl);
          final salePrice =
              double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0.0;
          final discountRaw =
              (double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0).round();
          final oldPrice = discountRaw > 0 && salePrice > 0
              ? salePrice + salePrice * discountRaw / 100
              : null;
          return {
            'id': item['id'].toString(),
            'title': title,
            'imageUrl': imageUrl,
            'price': salePrice,
            'oldPrice': oldPrice,
            'discount': discountRaw > 0 ? '$discountRaw' : null,
            'rating': 0.0,
          };
        }).toList();

        // Seed local liked set from API
        favoriteItems.value = likedProducts
            .map((p) => {'id': p['id'], 'title': p['title']})
            .toList();
      } else {
        errorMsg.value = 'error';
      }
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  bool isFavorited(dynamic id, dynamic title) {
    if (id != null) {
      return favoriteItems
          .any((item) => item['id'].toString() == id.toString());
    }
    return favoriteItems.any((item) => item['title'] == title);
  }

  Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    final numericId = int.tryParse(id ?? '');

    // No valid id — local only toggle (no API)
    if (numericId == null || numericId == 0) {
      _localToggle(item, id);
      return;
    }

    final wasLiked = isFavorited(id, item['title']);

    // Optimistic update — keep favoriteItems (heart icon state) and
    // likedProducts (FavoritesScreen grid) in sync so the favorites page
    // reflects the change immediately, without waiting for a re-fetch.
    if (wasLiked) {
      favoriteItems.removeWhere((e) => e['id'].toString() == id);
      likedProducts.removeWhere((e) => e['id'].toString() == id);
    } else {
      favoriteItems.add(item);
      if (!likedProducts.any((e) => e['id'].toString() == id)) {
        likedProducts.add(item);
      }
    }

    // API call
    try {
      final endpoint =
          wasLiked ? 'products/unlike/$numericId' : 'products/like/$numericId';
      print('[Like] POST $endpoint (wasLiked=$wasLiked, id=$numericId)');
      final response = await _api.postData({}, endpoint);
      print('[Like] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 401) {
        _revert(wasLiked, item, id!);
        likedProducts.clear();
        favoriteItems.clear();
        AuthStorage().clear();
        AppDialogs.showLoginRequiredSnackbar();
        NavigationService.goToLogin();
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        print('[Like] Failed — reverting local state');
        _revert(wasLiked, item, id!);
      }
    } catch (e) {
      print('[Like] Error: $e — reverting local state');
      _revert(wasLiked, item, id!);
    }
  }

  // Called from FavoritesScreen after exit animation completes
  Future<void> removeFromFavorites(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final numericId = int.tryParse(id);

    likedProducts.removeWhere((p) => p['id'].toString() == id);
    favoriteItems.removeWhere((e) => e['id'].toString() == id);

    if (numericId == null) return;
    try {
      print('[Like] POST products/unlike/$numericId (favorites remove)');
      final response = await _api.postData({}, 'products/unlike/$numericId');
      print('[Like] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 401) {
        AuthStorage().clear();
        AppDialogs.showLoginRequiredSnackbar();
        NavigationService.goToLogin();
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        likedProducts.add(item);
        favoriteItems.add({'id': item['id'], 'title': item['title']});
      }
    } catch (e) {
      print('[Like] Error: $e');
      likedProducts.add(item);
      favoriteItems.add({'id': item['id'], 'title': item['title']});
    }
  }

  void _localToggle(Map<String, dynamic> item, String? id) {
    int idx = -1;
    if (id != null) {
      idx = favoriteItems.indexWhere((e) => e['id']?.toString() == id);
    } else {
      idx = favoriteItems.indexWhere((e) => e['title'] == item['title']);
    }
    if (idx != -1) {
      favoriteItems.removeAt(idx);
    } else {
      favoriteItems.add(item);
    }
  }

  void _revert(bool wasLiked, Map<String, dynamic> item, String id) {
    if (wasLiked) {
      favoriteItems.add(item);
      if (!likedProducts.any((e) => e['id'].toString() == id)) {
        likedProducts.add(item);
      }
    } else {
      favoriteItems.removeWhere((e) => e['id'].toString() == id);
      likedProducts.removeWhere((e) => e['id'].toString() == id);
    }
  }
}

class ProfileController extends GetxController {
  final AuthStorage _authStorage = AuthStorage();

  var isLoggedIn = false.obs;
  var userName = "".obs;
  var userPhone = "".obs;

  // Language state
  var currentLanguage = 'tk'.obs;

  @override
  void onInit() {
    super.onInit();
    final storage = Get.find<GetStorage>();
    currentLanguage.value = storage.read('langCode') ?? 'tk';
    checkLoginState();
  }

  void checkLoginState() {
    isLoggedIn.value = _authStorage.isLoggedIn;
    if (isLoggedIn.value) {
      userName.value = _authStorage.name ?? "User";
      userPhone.value = _authStorage.phone ?? "";
    } else {
      userName.value = "";
      userPhone.value = "";
    }
  }

  void saveLogin(String token, String name, String phone) {
    _authStorage.saveToken(token);
    _authStorage.saveName(name);
    _authStorage.savePhone(phone);
    checkLoginState();
    if (Get.isRegistered<FavoritesController>()) {
      Get.find<FavoritesController>().fetchLikedProducts();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().fetchMyOrders();
    }
  }

  void logout() {
    _authStorage.clear();
    checkLoginState();
    if (Get.isRegistered<FavoritesController>()) {
      final fav = Get.find<FavoritesController>();
      fav.likedProducts.clear();
      fav.favoriteItems.clear();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().myOrders.clear();
    }
  }

  void changeLanguage(String langCode) {
    Get.updateLocale(Locale(langCode));
    currentLanguage.value = langCode;
    Get.find<GetStorage>().write('langCode', langCode);
  }
}
