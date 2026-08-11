// ignore_for_file: deprecated_member_use

import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/orders/controllers/order_controller.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(OrderController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'my_orders'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: Get.back,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.black,
            size: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: ctrl.fetchMyOrders,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: AppColors.green,
              size: 22,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }
        if (ctrl.myOrders.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: AppColors.green,
          onRefresh: ctrl.fetchMyOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.myOrders.length,
            itemBuilder: (_, i) => _buildOrderCard(ctrl.myOrders[i]),
          ),
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FAF3),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBag01,
              color: AppColors.green,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'no_orders'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_orders_desc'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'];
    final status = (order['status'] ?? 'pending').toString();
    final totalPrice = order['total_price'];
    final paymentMethod = (order['payment_method'] ?? '').toString();
    final createdAt = order['created_at'] ?? '';
    final address = (order['address'] ?? '').toString();

    final formattedDate = _formatDate(createdAt);
    final paymentLabel = paymentMethod == 'cash'
        ? 'Nagt'
        : (paymentMethod == 'card' ? 'Bank karty' : paymentMethod);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sargyt belgisi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Text(
                  '#$id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoItem('Sargydyň senesi', formattedDate),
                    ),
                    Expanded(
                      child: _buildInfoItem('Töleg şekili', paymentLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoItem('Ýagdaýy', _statusLabel(status)),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                          'Salgy', address.isEmpty ? '-' : address),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'Jemi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_parsePrice(totalPrice)} TMT',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'Gilroy',
            color: Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontFamily: 'Gilroy',
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'order_pending'.tr;
      case 'delivered':
        return 'order_delivered'.tr;
      case 'cancelled':
        return 'order_cancelled'.tr;
      case 'processing':
        return 'order_processing'.tr;
      default:
        return status;
    }
  }

  String _parsePrice(dynamic price) {
    if (price == null) return '0';
    final num val = num.tryParse(price.toString()) ?? 0;
    return val.toStringAsFixed(0);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
