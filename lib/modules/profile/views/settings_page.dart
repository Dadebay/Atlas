// ignore_for_file: deprecated_member_use

import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/modules/profile/views/help_support_page.dart';
import 'package:atlas/modules/profile/views/web_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/profile/controllers/language_controller.dart';
import 'package:atlas/modules/profile/views/language_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _buildUrl(String path) {
    final lang = Get.locale?.languageCode ?? 'tk';
    return '${ApiConstants.webBaseUrl}/$lang/$path';
  }

  void _openWebView(String path, String title) {
    Get.to(
      () => InfoWebViewPage(url: _buildUrl(path), title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Settings'.tr,
          style: const TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            color: AppColors.green,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Dil ──────────────────────────────────────────────────────
            _sectionLabel('language'.tr),
            const SizedBox(height: 10),
            _buildItem(
              icon: HugeIcons.strokeRoundedGlobal,
              title: 'language'.tr,
              onTap: () => Get.to(() => LanguagePage()),
              trailing: GetX<LanguageController>(
                init: LanguageController(),
                builder: (lc) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lc.selectedLanguage.value == 'tk' ? 'TKM' : 'RUS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Maglumat ─────────────────────────────────────────────────
            _sectionLabel('info_section'.tr),
            const SizedBox(height: 10),
            _SettingsExpandableGroup(
              icon: HugeIcons.strokeRoundedInformationCircle,
              title: 'biz_barada'.tr,
              items: [
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: 'biz_barada'.tr,
                  onTap: () => _openWebView('about', 'biz_barada'.tr),
                ),
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedShoppingBag01,
                  title: 'sargyt_etmek'.tr,
                  onTap: () => _openWebView('order', 'sargyt_etmek'.tr),
                ),
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedExchange01,
                  title: 'yzyna_gaytarmak'.tr,
                  onTap: () => _openWebView('returns', 'yzyna_gaytarmak'.tr),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsExpandableGroup(
              icon: HugeIcons.strokeRoundedAgreement01,
              title: 'hyzmatdashlyk'.tr,
              items: [
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedDeliveryTruck01,
                  title: 'eltip_berme_toleg'.tr,
                  onTap: () => _openWebView('delivery', 'eltip_berme_toleg'.tr),
                ),
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedAgreement01,
                  title: 'hyzmatdashlyk'.tr,
                  onTap: () => _openWebView('wholesale', 'hyzmatdashlyk'.tr),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsExpandableGroup(
              icon: HugeIcons.strokeRoundedQuestion,
              title: 'komek_goldaw'.tr,
              items: [
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedQuestion,
                  title: 'faq'.tr,
                  onTap: () => Get.to(() => const HelpSupportPage()),
                ),
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  title: 'toleg_usullary'.tr,
                  onTap: () => _openWebView('payment', 'toleg_usullary'.tr),
                ),
                _SettingsSubItem(
                  icon: HugeIcons.strokeRoundedShield01,
                  title: 'gizlinlik_yorelgesi'.tr,
                  onTap: () =>
                      _openWebView('privacy', 'gizlinlik_yorelgesi'.tr),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Gilroy',
          color: Colors.black38,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: icon,
                    color: AppColors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                trailing ??
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: Colors.black26,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ACCORDION DATA ───────────────────────────────────────────────────────────

class _SettingsSubItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsSubItem(
      {required this.icon, required this.title, required this.onTap});
}

// ─── ACCORDION WIDGET ─────────────────────────────────────────────────────────

class _SettingsExpandableGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<_SettingsSubItem> items;

  const _SettingsExpandableGroup({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  State<_SettingsExpandableGroup> createState() =>
      _SettingsExpandableGroupState();
}

class _SettingsExpandableGroupState extends State<_SettingsExpandableGroup>
    with SingleTickerProviderStateMixin {
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ─ Header ─────────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: HugeIcon(
                          icon: widget.icon,
                          color: AppColors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1B20),
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
            // ─ Sub-items ──────────────────────────────────────────────
            SizeTransition(
              sizeFactor: _fade,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Divider(
                        height: 1,
                        color: Colors.grey.shade100,
                        indent: 20,
                        endIndent: 20),
                    ...widget.items.asMap().entries.map((e) {
                      final isLast = e.key == widget.items.length - 1;
                      return Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: e.value.onTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
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
                          if (!isLast)
                            Divider(
                                height: 1,
                                color: Colors.grey.shade100,
                                indent: 58,
                                endIndent: 20),
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
