// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/core/services/catalog_service.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/brands/controllers/brands_controller.dart';
import 'package:atlas/widgets/filter_pill.dart';

const _kGreen = AppColors.green;

class ProductListScreen extends StatefulWidget {
  final String title;
  final bool isDiscount;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.isDiscount,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _api = CallApi();
  final _scrollController = ScrollController();
  late final BrandsController _brandsCtrl;

  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;

  int? _selectedBrandId;
  String? _selectedSort; // null | 'low' | 'high' | 'discount'

  // Temp selections inside sheet (not committed until "Apply")
  int? _tempBrandId;
  String? _tempSort;

  @override
  void initState() {
    super.initState();
    _brandsCtrl = Get.put(BrandsController());
    if (_brandsCtrl.brands.isEmpty && !_brandsCtrl.isLoading.value) {
      _brandsCtrl.fetchBrands();
    }
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMore) _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _products.clear();
        _page = 1;
        _hasMore = true;
      });
    }
    setState(() => _isLoading = true);

    try {
      final filter = widget.isDiscount ? 'discount=true' : 'new_in_come=true';
      String url = 'products/all?page=$_page&size=$_pageSize&$filter';
      if (_selectedBrandId != null) url += '&brand_id=$_selectedBrandId';

      final response = await _api.getData(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['data']['items'] as List? ?? [];
        final total = (body['data']['total'] as num?)?.toInt() ?? 0;
        final lang = Get.locale?.languageCode ?? 'tk';

        var fetched = items
            .map((e) => _toProductMap(e as Map<String, dynamic>, lang))
            .toList();

        if (_selectedSort == 'low') {
          fetched.sort(
              (a, b) => (a['price'] as double).compareTo(b['price'] as double));
        } else if (_selectedSort == 'high') {
          fetched.sort(
              (a, b) => (b['price'] as double).compareTo(a['price'] as double));
        } else if (_selectedSort == 'discount') {
          fetched.sort((a, b) => (b['discount'] != null ? 1 : 0)
              .compareTo(a['discount'] != null ? 1 : 0));
        }

        setState(() {
          _products.addAll(fetched);
          _page++;
          _hasMore = _products.length < total;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async => _fetchProducts(reset: true);

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
    final categoryName = item['category_name']?.toString() ?? '';
    final categoryId = item['category_id'] is int
        ? item['category_id'] as int
        : int.tryParse(item['category_id']?.toString() ?? '');
    final brandName = item['brand_name']?.toString() ?? '';
    final brandId = item['brand_id'] is int
        ? item['brand_id'] as int
        : int.tryParse(item['brand_id']?.toString() ?? '');

    return {
      'id': item['id'].toString(),
      'title': title,
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPrice,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'brandId': brandId,
      'brandName': brandName,
    };
  }

  // ── Right-side sheet helper ────────────────────────────────────────────

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
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.78,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            ),
            child: child,
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  // ── Brand sheet ────────────────────────────────────────────────────────

  void _showBrandSheet() {
    _tempBrandId = _selectedBrandId;
    final lang = Get.locale?.languageCode ?? 'tk';
    String brandQuery = '';

    _showRightSheet(StatefulBuilder(
      builder: (ctx, setInner) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'brands'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Navigator.of(ctx).pop,
                        icon: const Icon(Icons.close, size: 22),
                      ),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                  label: lang == 'ru' ? 'Hemmesini saýla' : 'Hemmesini saýla',
                  isSelected: _tempBrandId == null,
                  isHighlight: true,
                  onTap: () => setInner(() => _tempBrandId = null),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
              ],
              // Brand list
              Expanded(
                child: Obx(() {
                  if (_brandsCtrl.isLoading.value) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _kGreen, strokeWidth: 2));
                  }

                  final query = brandQuery.trim().toLowerCase();
                  final brands = query.isEmpty
                      ? _brandsCtrl.brands
                      : _brandsCtrl.brands
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
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        onTap: () => setInner(() => _tempBrandId = brand.id),
                      );
                    },
                  );
                }),
              ),
              // Bottom buttons
              _sheetBottomButtons(
                onCancel: Navigator.of(ctx).pop,
                onApply: () {
                  setState(() => _selectedBrandId = _tempBrandId);
                  _fetchProducts(reset: true);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    ));
  }

  // ── Sort sheet ─────────────────────────────────────────────────────────

  void _showSortSheet() {
    _tempSort = _selectedSort;
    final lang = Get.locale?.languageCode ?? 'tk';

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
                      lang == 'ru' ? 'Фильтр' : 'Süzgüç',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(ctx).pop,
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
          ),
          _radioTile(
            label: lang == 'ru' ? 'Hemmesini saýla' : 'Hemmesini saýla',
            isSelected: _tempSort == null,
            isHighlight: true,
            onTap: () => setInner(() => _tempSort = null),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _radioTile(
            label: lang == 'ru' ? 'По возрастанию цены' : 'Arzandan gymmada',
            isSelected: _tempSort == 'low',
            onTap: () => setInner(() => _tempSort = 'low'),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _radioTile(
            label: lang == 'ru' ? 'По убыванию цены' : 'Gymmatdan arzana',
            isSelected: _tempSort == 'high',
            onTap: () => setInner(() => _tempSort = 'high'),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _radioTile(
            label: lang == 'ru' ? 'По скидке' : 'Arzanladyş boýunça',
            isSelected: _tempSort == 'discount',
            onTap: () => setInner(() => _tempSort = 'discount'),
          ),
          const Spacer(),
          _sheetBottomButtons(
            onCancel: Navigator.of(ctx).pop,
            onApply: () {
              setState(() => _selectedSort = _tempSort);
              _fetchProducts(reset: true);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    ));
  }

  // ── Shared sheet widgets ───────────────────────────────────────────────

  Widget _radioTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? leading,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Gilroy',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlight ? _kGreen : const Color(0xFF1D1B20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kGreen : Colors.grey.shade300,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBottomButtons({
    required VoidCallback onCancel,
    required VoidCallback onApply,
  }) {
    final lang = Get.locale?.languageCode ?? 'tk';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  lang == 'ru' ? 'Отмена' : 'Goýbolsun et',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  lang == 'ru' ? 'Применить' : 'Saýla',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'tk';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Gilroy',
          ),
        ),
        leading: IconButton(
          onPressed: Get.back,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: _kGreen,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildFilterRow(lang),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String lang) {
    final count = _products.length;
    final countText = count > 0
        ? (lang == 'ru'
            ? '$count ${count == 1 ? 'товар' : count < 5 ? 'товара' : 'товаров'}'
            : '$count sany haryt')
        : (lang == 'ru' ? 'Загрузка...' : 'Ýüklenýär...');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          // Count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'ru' ? 'Всего:' : 'Jemi:',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Brand button
          FilterPill(
            label: 'brands'.tr,
            icon: HugeIcons.strokeRoundedStore01,
            isActive: _selectedBrandId != null,
            onTap: _showBrandSheet,
            onClear: _selectedBrandId != null
                ? () => setState(() {
                      _selectedBrandId = null;
                      _fetchProducts(reset: true);
                    })
                : null,
          ),
          const SizedBox(width: 8),
          // Sort button
          FilterPill(
            label: lang == 'ru' ? 'Фильтр' : 'Süzgüç',
            icon: HugeIcons.strokeRoundedSlidersHorizontal,
            isActive: _selectedSort != null,
            onTap: _showSortSheet,
            onClear: _selectedSort != null
                ? () => setState(() {
                      _selectedSort = null;
                      _fetchProducts(reset: true);
                    })
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_products.isEmpty && _isLoading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ProductCardShimmerGrid(count: 6),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: _kGreen,
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
                    'no_products_found'.tr,
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
      onRefresh: _refresh,
      color: _kGreen,
      backgroundColor: Colors.white,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 260,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                    CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
              ),
            );
          }

          final product = _products[index];
          final price = (product['price'] as num).toDouble();
          final catName = (product['categoryName'] as String?)?.isNotEmpty ==
                  true
              ? product['categoryName'] as String
              : CatalogService.to.categoryName(product['categoryId'] as int?);

          return ProductCard(
            id: product['id'] as String,
            title: product['title'] as String,
            imageUrl: product['imageUrl'] as String,
            price: price,
            oldPrice: (product['oldPrice'] as num?)?.toDouble(),
            discount: product['discount'] as String?,
            brandName: product['brandName'] as String?,
            categoryName: catName,
            onTap: () => Get.to(
              () => ProductDetailScreen(id: product['id'] as String?),
              binding: ProductDetailBinding(),
            ),
            onCartPressed: null,
          );
        },
      ),
    );
  }
}
