// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:get/get.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/auth_storage.dart';

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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[Orders] ► GET /api/$endpoint');
    try {
      final response = await _api.getData(endpoint);
      print('[Orders] ◄ status: ${response.statusCode}');
      print('[Orders] ◄ raw body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        print('[Orders] ◄ keys: ${body.keys.toList()}');
        final data = body['data'];
        if (data is List) {
          myOrders.value = List<Map<String, dynamic>>.from(data);
          await _enrichOrderItems();
          print('[Orders] ◄ parsed orders count: ${myOrders.length}');
          for (var i = 0; i < myOrders.length; i++) {
            final o = myOrders[i];
            print('[Orders] ─────── Order [$i] ───────');
            print('[Orders]   id         : ${o['id']}');
            print('[Orders]   status     : ${o['status']}');
            print('[Orders]   total_price: ${o['total_price']}');
            print('[Orders]   payment    : ${o['payment_method']}');
            print('[Orders]   address    : ${o['address']}');
            print('[Orders]   phone      : ${o['phone']}');
            print('[Orders]   payed      : ${o['payed']}');
            print('[Orders]   shipped    : ${o['shipped']}');
            print('[Orders]   created_at : ${o['created_at']}');
            final orderItems = o['order_items'] as List? ?? [];
            print('[Orders]   items (${orderItems.length}):');
            for (var j = 0; j < orderItems.length; j++) {
              final it = orderItems[j] as Map<String, dynamic>;
              print('[Orders]     [$j] product_id=${it['product_id']} '
                  'qty=${it['quantity']} '
                  'sale_price=${it['sale_price']} '
                  'discount=${it['discount']}');
            }
          }
        } else {
          print('[Orders] ◄ data is not a List: $data');
        }
      } else {
        print('[Orders] ◄ non-200 response body: ${response.body}');
      }
    } catch (e) {
      print('[Orders] ✗ fetchMyOrders error: $e');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[Orders] ► POST /api/orders');
      print('[Orders] ► request body: ${jsonEncode(body)}');
      final response = await _api.postData(body, 'orders');
      print('[Orders] ◄ status: ${response.statusCode}');
      print('[Orders] ◄ response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('[Orders] ✓ order created successfully');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (paymentMethod == 'online') {
          final respBody = jsonDecode(response.body) as Map<String, dynamic>;
          _printAllFields('[Orders][POST]', respBody);

          final orderId = respBody['data']?['id'];
          lastOnlineOrderId =
              orderId != null ? int.tryParse(orderId.toString()) : null;
          print('[Orders] ► orderId: $lastOnlineOrderId');

          // Önce POST response'unda URL ara
          String? invoiceUrl = _findUrl(respBody);
          print('[Orders] ► POST response URL: $invoiceUrl');

          // Bulunamazsa activate-order endpoint'ini çağır
          if ((invoiceUrl == null || invoiceUrl.isEmpty) &&
              lastOnlineOrderId != null) {
            invoiceUrl = await activatePayment(lastOnlineOrderId!);
          }

          result = invoiceUrl ?? '';
          print('[Orders] ► final invoiceUrl: $result');
        } else {
          result = '';
        }

        await fetchMyOrders();
      } else {
        print('[Orders] ✗ order creation failed (${response.statusCode})');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e) {
      print('[Orders] ✗ createOrder error: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
        print('[Orders] ► GET /api/products/$pid  status: ${res.statusCode}');
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
            print('[Orders]   product $pid → name=$name  image=$imageUrl');
          }
        }
      } catch (e) {
        print('[Orders] ✗ product fetch error (id=$pid): $e');
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
        print('$prefix  ${entry.key}: {');
        _printAllFields(prefix, entry.value as Map<String, dynamic>,
            depth: depth + 1);
        print('$prefix  }');
      } else {
        print('$prefix  ${entry.key}: ${entry.value}');
      }
    }
  }

  Future<String?> activatePayment(int orderId) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[Payment] ► GET /api/payments/activate-order/$orderId');
    try {
      final response = await _api.getData('payments/activate-order/$orderId');
      print('[Payment] ◄ status: ${response.statusCode}');
      print('[Payment] ◄ raw body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        print('[Payment] ◄ tüm alanlar:');
        _printAllFields('[Payment]', body);

        final url = _findUrl(body);
        print('[Payment] ◄ bulunan URL: $url');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return url;
      } else {
        print('[Payment] ✗ status ${response.statusCode}');
      }
    } catch (e) {
      print('[Payment] ✗ activatePayment error: $e');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }

  Future<bool> checkOrderPaid(int orderId) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[Payment] ► Ödeme durumu kontrol: GET /api/orders/$orderId');
    try {
      final response = await _api.getData('orders/$orderId');
      print('[Payment] ◄ status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final payed = body['data']?['payed'] == true;
        print('[Payment] ◄ payed: $payed');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return payed;
      }
    } catch (e) {
      print('[Payment] ✗ checkOrderPaid error: $e');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return false;
  }

  Future<bool> deleteOrder(int id) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[Orders] ► DELETE /api/orders/$id');
    try {
      final response = await _api.deleteData('orders/$id');
      print('[Orders] ◄ status: ${response.statusCode}');
      print('[Orders] ◄ body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (response.statusCode == 200 || response.statusCode == 204) {
        myOrders.removeWhere((o) => o['id'] == id);
        return true;
      }
    } catch (e) {
      print('[Orders] ✗ deleteOrder error: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return false;
  }
}
