// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/core/services/auth_storage.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/orders/controllers/order_controller.dart';
import 'package:atlas/modules/profile/views/web_view.dart';
import 'package:atlas/widgets/app_dialogs.dart';
import 'package:atlas/themes/colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartCtrl = Get.find<CartController>();
  final _orderCtrl = Get.put(OrderController());
  final _api = CallApi();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: AuthStorage().phone ?? '');
  final _formKey = GlobalKey<FormState>();

  String _paymentMethod = 'cash';
  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = false;
  int? _selectedBankId;
  String? _selectedBankName;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'order_details'.tr,
          style: const TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                color: Colors.white,
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ── Delivery info ─────────────────────────────────
            _sectionCard(
              title: 'order_address'.tr,
              icon: HugeIcons.strokeRoundedLocation01,
              child: Column(
                children: [
                  _inputField(
                    controller: _addressCtrl,
                    hint: 'address_hint'.tr,
                    icon: HugeIcons.strokeRoundedLocation01,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'required'.tr : null,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: _phoneCtrl,
                    hint: 'your_phone_number_label'.tr,
                    icon: HugeIcons.strokeRoundedCall,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'required'.tr : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Payment method ────────────────────────────────
            _sectionCard(
              title: 'select_payment_method'.tr,
              icon: HugeIcons.strokeRoundedCreditCard,
              child: Column(
                children: [
                  Row(
                    children: [
                      _paymentOption(
                          'cash', 'Nagt', HugeIcons.strokeRoundedMoney01),
                      const SizedBox(width: 10),
                      _paymentOption(
                          'online', 'Kart', HugeIcons.strokeRoundedCreditCard),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Cart items ────────────────────────────────────
            Obx(() {
              final items = _cartCtrl.cartItems;
              return _sectionCard(
                title: 'order'.tr,
                icon: HugeIcons.strokeRoundedShoppingBag01,
                child: Column(
                  children: [
                    ...List.generate(items.length, (i) {
                      final item = items[i];
                      final title = item['title']?.toString() ?? '';
                      final image = item['imageUrl']?.toString() ?? '';
                      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFF5F7FA),
                                child:
                                    image.isEmpty || image.startsWith('assets')
                                        ? Image.asset(image,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image,
                                                    color: Colors.grey))
                                        : CachedNetworkImage(
                                            imageUrl: image,
                                            fit: BoxFit.contain,
                                            memCacheWidth: 168,
                                            memCacheHeight: 168,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.image,
                                                    color: Colors.grey),
                                          ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xFF1D1B20),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${price.toStringAsFixed(0)} TMT × $qty',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(price * qty).toStringAsFixed(0)} TMT',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20, color: Color(0xFFF0F0F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                            color: Colors.black54,
                          ),
                        ),
                        Obx(() => Text(
                              '${_cartCtrl.totalPrice.toStringAsFixed(0)} TMT',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.green,
                                fontFamily: 'Gilroy',
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Obx(() => ElevatedButton(
                onPressed: _orderCtrl.isCreating.value ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor: AppColors.green.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _orderCtrl.isCreating.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'yes_order'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gilroy',
                        ),
                      ),
              )),
        ),
      ),
    );
  }

  Future<void> _fetchBanks() async {
    if (_banks.isNotEmpty || _isLoadingBanks) return;
    setState(() => _isLoadingBanks = true);
    try {
      final response = await _api.getData('orders/banks');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data'] as List? ?? [];
        setState(() {
          _banks = items
              .map((e) => {
                    'id': (e['id'] as num).toInt(),
                    'name': e['name']?.toString() ?? '',
                  })
              .toList();
        });
      }
    } catch (_) {}
    setState(() => _isLoadingBanks = false);
  }

  Future<void> _showBankSheet() async {
    if (!mounted) return;
    final lang = Get.locale?.languageCode ?? 'tk';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lang == 'ru' ? 'Выберите банк' : 'Bank saýla',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
          content: _isLoadingBanks
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                )
              : _banks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          lang == 'ru' ? 'Банки не найдены' : 'Bank tapylmady',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _banks.map((bank) {
                        final isSelected = _selectedBankId == bank['id'];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setStateDialog(() {
                            _selectedBankId = bank['id'] as int;
                            _selectedBankName = bank['name'] as String;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.green.withOpacity(0.07)
                                  : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.green
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.green.withOpacity(0.12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedBank,
                                      color: isSelected
                                          ? AppColors.green
                                          : Colors.black38,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    bank['name'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Gilroy',
                                      color: isSelected
                                          ? AppColors.green
                                          : const Color(0xFF1D1B20),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.green, size: 20),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                    ),
                    child: Text(
                      lang == 'ru' ? 'Отмена' : 'Ýatyr',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedBankId == null
                        ? null
                        : () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      disabledBackgroundColor:
                          AppColors.green.withOpacity(0.35),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      lang == 'ru' ? 'Продолжить' : 'Dowam et',
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Online seçildiyse önce banka dialog'u göster
    if (_paymentMethod == 'online') {
      if (_banks.isEmpty) await _fetchBanks();
      await _showBankSheet();
      if (_selectedBankId == null) return; // Kullanıcı iptal etti
    }

    final items = List<Map<String, dynamic>>.from(_cartCtrl.cartItems);
    final result = await _orderCtrl.createOrder(
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      cartItems: items,
      paymentMethod: _paymentMethod,
      bankId: _selectedBankId,
    );

    if (result != null) {
      if (_paymentMethod == 'online' && result.isNotEmpty) {
        print('[Checkout] ► WebView açılıyor: $result');
        await Get.to(() => InfoWebViewPage(
              url: result,
              title: Get.locale?.languageCode == 'ru' ? 'Оплата' : 'Töleg',
              autoCloseHosts: const ['atlas.com.tm'],
            ));

        // WebView kapandı — ödeme yapıldı mı kontrol et
        final orderId = _orderCtrl.lastOnlineOrderId;
        final paid = orderId != null
            ? await _orderCtrl.checkOrderPaid(orderId)
            : false;

        if (paid) {
          // Ödeme başarılı
          _cartCtrl.clearCart();
          Get.back();
          AppDialogs.showTopSuccessSnackbar(
            title: 'order_success'.tr,
            subtitle: 'order_placed_desc'.tr,
            icon: HugeIcons.strokeRoundedShoppingBag01,
          );
        }
        // Ödeme yapılmadıysa checkout'ta kal, sepet kalır
      } else {
        // Nakit veya URL gelmedi
        _cartCtrl.clearCart();
        Get.back();
        AppDialogs.showTopSuccessSnackbar(
          title: 'order_success'.tr,
          subtitle: 'order_placed_desc'.tr,
          icon: HugeIcons.strokeRoundedShoppingBag01,
        );
      }
    } else {
      Get.snackbar(
        'error_title'.tr,
        'order_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(icon: icon, color: AppColors.green, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xFF1D1B20),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 14,
          fontFamily: 'Gilroy',
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: HugeIcon(icon: icon, color: AppColors.green, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.green.withOpacity(0.08)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: selected ? AppColors.green : Colors.black38,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  color: selected ? AppColors.green : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
