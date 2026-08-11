import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/modules/auth/views/login_view.dart';
import 'package:atlas/modules/auth/views/register_phone_view.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';
import 'package:atlas/modules/profile/views/web_view.dart';
import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/modules/profile/controllers/language_controller.dart';
import 'package:atlas/modules/profile/views/language_page.dart';
import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:atlas/modules/profile/views/help_support_page.dart';
import 'package:atlas/modules/profile/views/settings_page.dart';
import 'package:atlas/modules/orders/views/my_orders_screen.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isLoggedIn.value ? _buildLoggedIn() : _buildNotLoggedIn());
  }

  void _openWebView(String path, String title) {
    final lang = Get.locale?.languageCode ?? 'tk';
    Get.to(
      () => InfoWebViewPage(
        url: '${ApiConstants.webBaseUrl}/$lang/$path',
        title: title,
      ),
      transition: Transition.rightToLeft,
    );
  }

  // ─── NOT LOGGED IN ────────────────────────────────────────────────────────

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'not_logged_in_title'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 26,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'not_logged_in_desc'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Gilroy',
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              _buildGradientButton(
                text: 'login_button'.tr,
                onTap: () => Get.to(() => const LoginView()),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Get.to(() => const RegisterPhoneView()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text(
                      'register_button'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.green,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOGGED IN ────────────────────────────────────────────────────────────

  Widget _buildLoggedIn() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'profile'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildMenuSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── SHARED SLIVER APP BAR ────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.green,
      elevation: 4,
      centerTitle: true,
      toolbarHeight: 120,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 24),
          child: IconButton(
            onPressed: () => Get.to(() => const SettingsPage()),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 24,
          width: double.maxFinite,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
        ),
      ),
      title: ClipRRect(
        child: Image.asset(
          'assets/images/logo3.png',
          height: 100,
          // color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.shopping_bag_outlined,
            color: Colors.white,
            size: 56,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppColors.green, AppColors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontFamily: 'Gilroy',
            ),
          ),
        ),
      ),
    );
  }

  // ─── PROFILE HEADER ───────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.green.withOpacity(0.1),
              child: Obx(() => Text(
                    controller.userName.value.isNotEmpty ? controller.userName.value[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                      fontFamily: 'Gilroy',
                    ),
                  )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.userName.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Gilroy',
                        color: Color(0xFF1D1B20),
                      ),
                    )),
                const SizedBox(height: 4),
                Obx(() => Text(
                      '+${controller.userPhone.value}',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MENU ─────────────────────────────────────────────────────────────────

  Widget _buildMenuSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildMenuItem(
          HugeIcons.strokeRoundedGlobal,
          'language'.tr,
          () => Get.to(() => LanguagePage()),
          trailing: GetX<LanguageController>(
            init: LanguageController(),
            builder: (langCtrl) => Text(
              langCtrl.selectedLanguage.value == 'tk' ? 'TKM' : 'RUS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          HugeIcons.strokeRoundedFavourite,
          'favorites'.tr,
          () => Get.find<MainController>().changeIndex(3),
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          HugeIcons.strokeRoundedShoppingBag01,
          'my_orders'.tr,
          () => Get.to(() => const MyOrdersScreen()),
        ),
        const SizedBox(height: 12),
        _ProfileExpandableGroup(
          icon: HugeIcons.strokeRoundedInformationCircle,
          title: 'biz_barada'.tr,
          items: [
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedInformationCircle,
              title: 'biz_barada'.tr,
              onTap: () => _openWebView('about', 'biz_barada'.tr),
            ),
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedShoppingBag01,
              title: 'sargyt_etmek'.tr,
              onTap: () => _openWebView('delivery', 'sargyt_etmek'.tr),
            ),
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedExchange01,
              title: 'yzyna_gaytarmak'.tr,
              onTap: () => _openWebView('returns', 'yzyna_gaytarmak'.tr),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileExpandableGroup(
          icon: HugeIcons.strokeRoundedAgreement01,
          title: 'hyzmatdashlyk'.tr,
          items: [
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedDeliveryTruck01,
              title: 'eltip_berme_toleg'.tr,
              onTap: () => _openWebView('delivery', 'eltip_berme_toleg'.tr),
            ),
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedAgreement01,
              title: 'hyzmatdashlyk'.tr,
              onTap: () => _openWebView('wholesale', 'hyzmatdashlyk'.tr),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileExpandableGroup(
          icon: HugeIcons.strokeRoundedQuestion,
          title: 'komek_goldaw'.tr,
          items: [
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedQuestion,
              title: 'faq'.tr,
              onTap: () => Get.to(() => const HelpSupportPage()),
            ),
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedCreditCard,
              title: 'toleg_usullary'.tr,
              onTap: () => _openWebView('payment', 'toleg_usullary'.tr),
            ),
            _ProfileSubItem(
              icon: HugeIcons.strokeRoundedShield01,
              title: 'gizlinlik_yorelgesi'.tr,
              onTap: () => _openWebView('privacy', 'gizlinlik_yorelgesi'.tr),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          HugeIcons.strokeRoundedLogout01,
          'logout'.tr,
          () => _showLogoutDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                HugeIcon(
                  icon: icon,
                  color: isDestructive ? Colors.red : Colors.black87,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.black87,
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                trailing ??
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: isDestructive ? Colors.red.withOpacity(0.4) : Colors.black26,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── LOGOUT DIALOG ────────────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'logout'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'deleteProfileDescription'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gilroy',
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.logout();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'yes'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ACCORDION DATA ───────────────────────────────────────────────────────────

class _ProfileSubItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileSubItem({required this.icon, required this.title, required this.onTap});
}

// ─── ACCORDION WIDGET ─────────────────────────────────────────────────────────

class _ProfileExpandableGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<_ProfileSubItem> items;

  const _ProfileExpandableGroup({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  State<_ProfileExpandableGroup> createState() => _ProfileExpandableGroupState();
}

class _ProfileExpandableGroupState extends State<_ProfileExpandableGroup> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _rotate = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ─ Header ────────────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: widget.icon,
                        color: Colors.black87,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: _rotate,
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 18,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ─ Sub-items ─────────────────────────────────────────────────
            SizeTransition(
              sizeFactor: _fade,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                    ...widget.items.asMap().entries.map((e) {
                      final isLast = e.key == widget.items.length - 1;
                      return Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: e.value.onTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 6),
                                    HugeIcon(
                                      icon: e.value.icon,
                                      color: AppColors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        e.value.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1D1B20),
                                          fontSize: 14,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                    ),
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowRight01,
                                      size: 15,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 58, endIndent: 20),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
