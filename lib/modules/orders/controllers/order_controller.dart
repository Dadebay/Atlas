import 'dart:convert';

import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/utils/app_log.dart';

class OrderController extends GetxController {
  final _api = CallApi();

  var myOrders = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isCreating = false.obs;

  // Son oluşturulan online siparişin ID'si
  int? lastOnlineOrderId;

  // product_id → {name, imageUrl} cache
  final _productCache = <int, Map<String, dynamic>>{};

  @override
  void onInit() {
    super.onInit();
    if (AuthStorage().isLoggedIn) fetchMyOrders();
  }

  Future<void> fetchMyOrders() async {
    isLoading.value = true;
    const endpoint = 'orders/my';
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLog.d('[Orders] ► GET /api/$endpoint');
    try {
      final response = await _api.getData(endpoint);
      AppLog.d('[Orders] ◄ status: ${response.statusCode}');
      AppLog.d('[Orders] ◄ raw body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        AppLog.d('[Orders] ◄ keys: ${body.keys.toList()}');
        final data = body['data'];
        if (data is List) {
          myOrders.value = List<Map<String, dynamic>>.from(data);
          await _enrichOrderItems();
          AppLog.d('[Orders] ◄ parsed orders count: ${myOrders.length}');
          for (var i = 0; i < myOrders.length; i++) {
            final o = myOrders[i];
            AppLog.d('[Orders] ─────── Order [$i] ───────');
            AppLog.d('[Orders]   id         : ${o['id']}');
            AppLog.d('[Orders]   status     : ${o['status']}');
            AppLog.d('[Orders]   total_price: ${o['total_price']}');
            AppLog.d('[Orders]   payment    : ${o['payment_method']}');
            AppLog.d('[Orders]   address    : ${o['address']}');
            AppLog.d('[Orders]   phone      : ${o['phone']}');
            AppLog.d('[Orders]   payed      : ${o['payed']}');
            AppLog.d('[Orders]   shipped    : ${o['shipped']}');
            AppLog.d('[Orders]   created_at : ${o['created_at']}');
            final orderItems = o['order_items'] as List? ?? [];
            AppLog.d('[Orders]   items (${orderItems.length}):');
            for (var j = 0; j < orderItems.length; j++) {
              final it = orderItems[j] as Map<String, dynamic>;
              AppLog.d('[Orders]     [$j] product_id=${it['product_id']} '
                  'qty=${it['quantity']} '
                  'sale_price=${it['sale_price']} '
                  'discount=${it['discount']}');
            }
          }
        } else {
          AppLog.d('[Orders] ◄ data is not a List: $data');
        }
      } else {
        AppLog.d('[Orders] ◄ non-200 response body: ${response.body}');
      }
    } catch (e) {
      AppLog.d('[Orders] ✗ fetchMyOrders error: $e');
    }
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    isLoading.value = false;
  }

  // Returns: null=hata, ''=nakit başarı, 'https://...'=ödeme fatura URL'si
  Future<String?> createOrder({
    required String address,
    required String phone,
    required List<Map<String, dynamic>> cartItems,
    String paymentMethod = 'cash',
    int? bankId,
  }) async {
    isCreating.value = true;
    String? result;
    try {
      final items = cartItems.map((item) {
        return {
          'product_id': int.tryParse(item['id']?.toString() ?? '0') ?? 0,
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
        };
      }).toList();

      final body = <String, dynamic>{
        'address': address,
        'phone': phone,
        'payment_method': paymentMethod,
        'items': items,
        if (bankId != null) 'bank_id': bankId,
      };

      AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLog.d('[Orders] ► POST /api/orders');
      AppLog.d('[Orders] ► request body: ${jsonEncode(body)}');
      final response = await _api.postData(body, 'orders');
      AppLog.d('[Orders] ◄ status: ${response.statusCode}');
      AppLog.d('[Orders] ◄ response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLog.d('[Orders] ✓ order created successfully');
        AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (paymentMethod == 'online') {
          final respBody = jsonDecode(response.body) as Map<String, dynamic>;
          _printAllFields('[Orders][POST]', respBody);

          final orderId = respBody['data']?['id'];
          lastOnlineOrderId =
              orderId != null ? int.tryParse(orderId.toString()) : null;
          AppLog.d('[Orders] ► orderId: $lastOnlineOrderId');

          // Önce POST response'unda URL ara
          String? invoiceUrl = _findUrl(respBody);
          AppLog.d('[Orders] ► POST response URL: $invoiceUrl');

          // Bulunamazsa activate-order endpoint'ini çağır
          if ((invoiceUrl == null || invoiceUrl.isEmpty) &&
              lastOnlineOrderId != null) {
            invoiceUrl = await activatePayment(lastOnlineOrderId!);
          }

          result = invoiceUrl ?? '';
          AppLog.d('[Orders] ► final invoiceUrl: $result');
        } else {
          result = '';
        }

        await fetchMyOrders();
      } else {
        AppLog.d('[Orders] ✗ order creation failed (${response.statusCode})');
        AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e) {
      AppLog.d('[Orders] ✗ createOrder error: $e');
      AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    isCreating.value = false;
    return result;
  }

  Future<void> _enrichOrderItems() async {
    // collect unique product IDs not yet cached
    final ids = <int>{};
    for (final order in myOrders) {
      final items = order['order_items'] as List? ?? [];
      for (final item in items) {
        final pid = (item as Map)['product_id'];
        if (pid != null) {
          final id = int.tryParse(pid.toString());
          if (id != null && !_productCache.containsKey(id)) ids.add(id);
        }
      }
    }

    // fetch each missing product
    for (final pid in ids) {
      try {
        final res = await _api.getData('products/$pid');
        AppLog.d(
            '[Orders] ► GET /api/products/$pid  status: ${res.statusCode}');
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final p = body['data'] as Map<String, dynamic>?;
          if (p != null) {
            const lang = 'tk';
            final rawName = p['name'];
            String name = '';
            if (rawName is Map) {
              name = rawName[lang]?.toString() ??
                  rawName['tk']?.toString() ??
                  rawName['ru']?.toString() ??
                  '';
            } else {
              name = rawName?.toString() ?? '';
            }

            final imgsRaw = p['images'];
            String imageUrl = '';
            if (imgsRaw is List && imgsRaw.isNotEmpty) {
              final first = imgsRaw[0];
              if (first is String) imageUrl = first;
              if (first is Map) imageUrl = first['url']?.toString() ?? '';
            } else if (imgsRaw is String && imgsRaw.isNotEmpty) {
              imageUrl = imgsRaw;
            }
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'https://atlas.com.tm/public/$imageUrl';
            }

            _productCache[pid] = {'name': name, 'imageUrl': imageUrl};
            AppLog.d('[Orders]   product $pid → name=$name  image=$imageUrl');
          }
        }
      } catch (e) {
        AppLog.d('[Orders] ✗ product fetch error (id=$pid): $e');
      }
    }

    // inject cached data into order items
    final updated = myOrders.map((order) {
      final items = (order['order_items'] as List? ?? []).map((e) {
        final item = Map<String, dynamic>.from(e as Map);
        final pid = int.tryParse(item['product_id']?.toString() ?? '');
        if (pid != null && _productCache.containsKey(pid)) {
          item['_name'] = _productCache[pid]!['name'];
          item['_imageUrl'] = _productCache[pid]!['imageUrl'];
        }
        return item;
      }).toList();
      return {...order, 'order_items': items};
    }).toList();
    myOrders.value = updated;
  }

  // Response içindeki http ile başlayan ilk string değeri bulur
  String? _findUrl(dynamic obj, {int depth = 0}) {
    if (depth > 5) return null;
    if (obj is String &&
        (obj.startsWith('http://') || obj.startsWith('https://'))) {
      return obj;
    }
    if (obj is Map) {
      for (final entry in obj.entries) {
        final found = _findUrl(entry.value, depth: depth + 1);
        if (found != null) return found;
      }
    }
    if (obj is List) {
      for (final item in obj) {
        final found = _findUrl(item, depth: depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _printAllFields(String prefix, Map<String, dynamic> map,
      {int depth = 0}) {
    if (depth > 3) return;
    for (final entry in map.entries) {
      if (entry.value is Map) {
        AppLog.d('$prefix  ${entry.key}: {');
        _printAllFields(prefix, entry.value as Map<String, dynamic>,
            depth: depth + 1);
        AppLog.d('$prefix  }');
      } else {
        AppLog.d('$prefix  ${entry.key}: ${entry.value}');
      }
    }
  }

  Future<String?> activatePayment(int orderId) async {
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLog.d('[Payment] ► GET /api/payments/activate-order/$orderId');
    try {
      final response = await _api.getData('payments/activate-order/$orderId');
      AppLog.d('[Payment] ◄ status: ${response.statusCode}');
      AppLog.d('[Payment] ◄ raw body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        AppLog.d('[Payment] ◄ tüm alanlar:');
        _printAllFields('[Payment]', body);

        final url = _findUrl(body);
        AppLog.d('[Payment] ◄ bulunan URL: $url');
        AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return url;
      } else {
        AppLog.d('[Payment] ✗ status ${response.statusCode}');
      }
    } catch (e) {
      AppLog.d('[Payment] ✗ activatePayment error: $e');
    }
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }

  Future<bool> checkOrderPaid(int orderId) async {
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLog.d('[Payment] ► Ödeme durumu kontrol: GET /api/orders/$orderId');
    try {
      final response = await _api.getData('orders/$orderId');
      AppLog.d('[Payment] ◄ status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final payed = body['data']?['payed'] == true;
        AppLog.d('[Payment] ◄ payed: $payed');
        AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return payed;
      }
    } catch (e) {
      AppLog.d('[Payment] ✗ checkOrderPaid error: $e');
    }
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return false;
  }

  Future<bool> deleteOrder(int id) async {
    AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLog.d('[Orders] ► DELETE /api/orders/$id');
    try {
      final response = await _api.deleteData('orders/$id');
      AppLog.d('[Orders] ◄ status: ${response.statusCode}');
      AppLog.d('[Orders] ◄ body: ${response.body}');
      AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (response.statusCode == 200 || response.statusCode == 204) {
        myOrders.removeWhere((o) => o['id'] == id);
        return true;
      }
    } catch (e) {
      AppLog.d('[Orders] ✗ deleteOrder error: $e');
      AppLog.d('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return false;
  }
}
