// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:atlas/modules/category/models/category_model.dart';
import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/search/views/search_screen.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/core/utils/app_log.dart';
import 'package:atlas/widgets/filter_pill.dart';

const _kGreen = AppColors.green;

class SubCategoryProductScreen extends StatefulWidget {
  final CategoryModel? category;
  final String? overrideTitle;
  final bool isDiscount;
  final bool isNew;

  const SubCategoryProductScreen({
    super.key,
    this.category,
    this.overrideTitle,
    this.isDiscount = false,
    this.isNew = false,
  });

  @override
  State<SubCategoryProductScreen> createState() =>
      _SubCategoryProductScreenState();
}

class _SubCategoryProductScreenState extends State<SubCategoryProductScreen> {
  final _api = CallApi();

  int _selectedSubIndex = -1;
  int? _selectedBrandId;
  String? _selectedSort;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  int? get _effectiveCategoryId {
    if (widget.category == null) return null;
    if (_selectedSubIndex == -1) return widget.category!.id;
    return widget.category!.children[_selectedSubIndex].id;
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts(widget.category?.id);
  }

  Future<void> _fetchProducts([int? categoryId]) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _products = [];
    });
    try {
      String url;
      if (categoryId != null) {
        url = 'products/all?page=1&size=50&category_id=$categoryId';
      } else if (widget.isDiscount) {
        url = 'products/all?page=1&size=50&discount=true';
      } else if (widget.isNew) {
        url = 'products/all?page=1&size=50&new_in_come=true';
      } else {
        url = 'products/all?page=1&size=50';
      }
      if (_selectedBrandId != null) {
        url += '&brand_id=$_selectedBrandId';
      }
      AppLog.d('[Category] GET $url');
      final response = await _api.getData(url);
      AppLog.d('[Category] Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['data']?['items'] as List?) ?? [];
        AppLog.d('[Category] Products count: ${items.length}');
        final lang = Get.locale?.languageCode ?? 'tk';
        if (!mounted) return;
        setState(() {
          _products = items
              .whereType<Map<String, dynamic>>()
              .map((p) => _toProductMap(p, lang))
              .toList();
          _sortProducts();
        });
      }
    } catch (e) {
      AppLog.d('[Category] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _sortProducts() {
    if (_selectedSort == 'low') {
      _products.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_selectedSort == 'high') {
      _products.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else if (_selectedSort == 'discount') {
      _products.sort((a, b) {
        final da = int.tryParse(a['discount']?.toString() ?? '0') ?? 0;
        final db = int.tryParse(b['discount']?.toString() ?? '0') ?? 0;
        return db.compareTo(da);
      });
    }
  }

  Map<String, dynamic> _toProductMap(Map<String, dynamic> item, String lang) {
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
    final brandName = item['brand_name']?.toString() ?? '';

    return {
      'id': item['id']?.toString() ?? '',
      'title': title,
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPrice,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'brandName': brandName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'tk';
    final hasSubcategories = widget.category?.children.isNotEmpty == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _buildCircleButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            iconSize: 20,
            onTap: () => Get.back(),
          ),
        ),
        title: Text(
          widget.overrideTitle ?? widget.category?.localName(lang) ?? '',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Gilroy',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _buildCircleButton(
              icon: HugeIcons.strokeRoundedSearch01,
              iconSize: 18,
              onTap: () => Get.to(() => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (hasSubcategories) _buildSubcategoryRow(lang),
            _buildFilterRow(lang),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: HugeIcon(icon: icon, color: Colors.black, size: iconSize),
        ),
      ),
    );
  }

  void _showRightSheet(Widget child) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.78,
            height: double.infinity,
            child: child,
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  int? _tempBrandId;
  String? _tempSort;

  Widget _buildFilterRow(String lang) {
    final count = _products.length;
    final countText = count > 0
        ? (lang == 'ru'
            ? '$count ${count == 1 ? 'товар' : count < 5 ? 'товара' : 'товаров'}'
            : '$count sany haryt')
        : (lang == 'ru' ? 'Загрузка...' : 'Ýüklenýär...');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'ru' ? 'Всего:' : 'Jemi:',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    countText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gilroy',
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilterPill(
            icon: HugeIcons.strokeRoundedStore01,
            label: 'brands'.tr,
            isActive: _selectedBrandId != null,
            onTap: _showBrandFilterSheet,
            onClear: _selectedBrandId != null
                ? () {
                    setState(() => _selectedBrandId = null);
                    _fetchProducts(_effectiveCategoryId);
                  }
                : null,
          ),
          const SizedBox(width: 8),
          FilterPill(
            icon: HugeIcons.strokeRoundedSlidersHorizontal,
            label: lang == 'ru' ? 'Фильтр' : 'Süzgüç',
            isActive: _selectedSort != null,
            onTap: _showSortSheet,
            onClear: _selectedSort != null
                ? () {
                    setState(() => _selectedSort = null);
                    _fetchProducts(_effectiveCategoryId);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? leading,
    bool isHighlight = false,
  }) {
    final isSpecial = isHighlight && isSelected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                if (!isHighlight) ...[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _kGreen : Colors.grey.shade400,
                        width: isSelected ? 6 : 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                if (leading != null) ...[leading, const SizedBox(width: 12)],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                      fontWeight: isSpecial ? FontWeight.w700 : FontWeight.w500,
                      color: isSpecial ? _kGreen : const Color(0xFF1D1B20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetBottomButtons({
    required VoidCallback onCancel,
    required VoidCallback onApply,
  }) {
    final lang = Get.locale?.languageCode ?? 'tk';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    lang == 'ru' ? 'Отмена' : 'Goýbolsun et',
                    style: const TextStyle(
                      color: _kGreen,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onApply,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    lang == 'ru' ? 'Применить' : 'Saýla',
                    style: const TextStyle(
                      color: _kGreen,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrandFilterSheet() {
    _tempBrandId = _selectedBrandId;
    final brandsController = Get.put(BrandsController());
    if (brandsController.brands.isEmpty && !brandsController.isLoading.value) {
      brandsController.fetchBrands();
    }
    final lang = Get.locale?.languageCode ?? 'tk';
    String brandQuery = '';

    _showRightSheet(StatefulBuilder(builder: (ctx, setInner) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('brands'.tr,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Gilroy')),
                    ),
                    IconButton(
                        onPressed: Navigator.of(ctx).pop,
                        icon: const Icon(Icons.close, size: 22)),
                  ],
                ),
              ),
            ),
            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (value) => setInner(() => brandQuery = value),
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText:
                      lang == 'ru' ? 'Поиск брендов...' : 'Brend gözle...',
                  hintStyle: const TextStyle(
                    color: Colors.black38,
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: _kGreen,
                      size: 18,
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    borderSide: const BorderSide(color: _kGreen, width: 1.5),
                  ),
                ),
              ),
            ),
            // "All" option (only visible when not searching)
            if (brandQuery.trim().isEmpty) ...[
              _radioTile(
                label: lang == 'ru' ? 'Все бренды' : 'Hemmesini saýla',
                isSelected: _tempBrandId == null,
                isHighlight: true,
                onTap: () => setInner(() => _tempBrandId = null),
              ),
              const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFE5E7EB)),
            ],
            // Brand list
            Expanded(
              child: Obx(() {
                if (brandsController.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _kGreen, strokeWidth: 2));
                }

                final query = brandQuery.trim().toLowerCase();
                final brands = query.isEmpty
                    ? brandsController.brands
                    : brandsController.brands
                        .where((b) => b.name.toLowerCase().contains(query))
                        .toList();

                if (brands.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'no_data_found'.tr,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: brands.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFE5E7EB)),
                  itemBuilder: (_, i) {
                    final brand = brands[i];
                    final isSel = _tempBrandId == brand.id;
                    return _radioTile(
                      label: brand.name,
                      isSelected: isSel,
                      leading: SizedBox(
                        width: 36,
                        height: 36,
                        child: brand.image.isEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: _kGreen.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                    child: Text(
                                  brand.name.isNotEmpty
                                      ? brand.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: _kGreen,
                                      fontWeight: FontWeight.bold),
                                )),
                              )
                            : ClipOval(
                                child: CachedNetworkImage(
                                imageUrl: brand.image,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Container(
                                  color: _kGreen.withOpacity(0.08),
                                  child: Center(
                                      child: Text(
                                    brand.name.isNotEmpty
                                        ? brand.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: _kGreen,
                                        fontWeight: FontWeight.bold),
                                  )),
                                ),
                              )),
                      ),
                      onTap: () => setInner(() => _tempBrandId = brand.id),
                    );
                  },
                );
              }),
            ),
            _sheetBottomButtons(
              onCancel: Navigator.of(ctx).pop,
              onApply: () {
                setState(() => _selectedBrandId = _tempBrandId);
                _fetchProducts(_effectiveCategoryId);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }));
  }

  void _showSortSheet() {
    _tempSort = _selectedSort;
    final lang = Get.locale?.languageCode ?? 'tk';

    final options = [
      (value: null as String?, label: lang == 'ru' ? 'Все' : 'Hemmesini saýla'),
      (
        value: 'low',
        label: lang == 'ru' ? 'Цена: от дешевых' : 'Arzandan gymmada'
      ),
      (
        value: 'high',
        label: lang == 'ru' ? 'Цена: от дорогих' : 'Gymmatdan arzana'
      ),
      (
        value: 'discount',
        label: lang == 'ru' ? 'По скидке' : 'Arzanladyş boýunça'
      ),
    ];

    _showRightSheet(StatefulBuilder(
        builder: (ctx, setInner) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'ru' ? 'Сортировка' : 'Tertiplemek',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Gilroy'),
                          ),
                        ),
                        IconButton(
                            onPressed: Navigator.of(ctx).pop,
                            icon: const Icon(Icons.close, size: 22)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((opt) => _radioTile(
                      label: opt.label,
                      isSelected: _tempSort == opt.value,
                      isHighlight: opt.value == null,
                      onTap: () => setInner(() => _tempSort = opt.value),
                    )),
                const Spacer(),
                _sheetBottomButtons(
                  onCancel: Navigator.of(ctx).pop,
                  onApply: () {
                    setState(() {
                      _selectedSort = _tempSort;
                      _sortProducts();
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            )));
  }

  Widget _buildBody() {
    final lang = Get.locale?.languageCode ?? 'tk';
    final children = widget.category?.children ?? [];
    final String activeCatName = _selectedSubIndex == -1
        ? (widget.overrideTitle ?? widget.category?.localName(lang) ?? '')
        : (children.isNotEmpty && _selectedSubIndex < children.length
            ? children[_selectedSubIndex].localName(lang)
            : (widget.overrideTitle ?? widget.category?.localName(lang) ?? ''));

    if (_isLoading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ProductCardShimmerGrid(count: 6),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchProducts(_effectiveCategoryId),
        color: AppColors.green,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Plays once and rests on its last frame — an empty state
                  // has nothing more to say after the first pass.
                  Lottie.asset(
                    'assets/images/shopping-cart.json',
                    width: 180,
                    height: 180,
                    repeat: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'product_not_found'.tr,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchProducts(_effectiveCategoryId),
      color: AppColors.green,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 260,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = _products[index];
                  return ProductCard(
                    id: p['id'],
                    title: p['title'] ?? '',
                    price: (p['price'] as double?) ?? 0.0,
                    oldPrice: p['oldPrice'] as double?,
                    discount: p['discount'] as String?,
                    brandName: p['brandName'] as String?,
                    imageUrl: p['imageUrl'] ?? '',
                    categoryName: activeCatName,
                    onTap: () => Get.to(
                      () => ProductDetailScreen(id: p['id'] as String?),
                      binding: ProductDetailBinding(),
                    ),
                    onCartPressed: null,
                  );
                },
                childCount: _products.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  lang == 'ru'
                      ? '— Все товары показаны —'
                      : '— Hemmesi görkezildi —',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryRow(String lang) {
    final children = widget.category!.children;
    final allLabel = lang == 'ru' ? 'Все' : 'Ählisi';

    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedSubIndex == -1;
            return GestureDetector(
              onTap: () {
                if (_selectedSubIndex != -1) {
                  setState(() => _selectedSubIndex = -1);
                  _fetchProducts(widget.category!.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  allLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0D1B3E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            );
          }

          final subIndex = index - 1;
          final sub = children[subIndex];
          final isSelected = _selectedSubIndex == subIndex;
          return GestureDetector(
            onTap: () {
              if (sub.children.isNotEmpty) {
                Get.to(
                  () => SubCategoryProductScreen(category: sub),
                  preventDuplicates: false,
                );
              } else {
                setState(() => _selectedSubIndex = subIndex);
                _fetchProducts(sub.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.green : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sub.localName(lang),
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF0D1B3E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  if (sub.children.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.black45,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
