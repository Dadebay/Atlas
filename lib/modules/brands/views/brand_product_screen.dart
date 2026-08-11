import 'dart:convert';
import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/widgets/product_card.dart';
import 'package:atlas/widgets/product_card_shimmer.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';
import 'package:atlas/modules/product_detail/views/product_detail_screen.dart';
import 'package:atlas/modules/product_detail/bindings/product_detail_binding.dart';
import 'package:atlas/modules/search/views/search_screen.dart';
import 'package:atlas/modules/brands/models/brand_model.dart';
import 'package:lottie/lottie.dart';

const _kGreen = AppColors.green;

class BrandProductScreen extends StatefulWidget {
  final BrandModel brand;
  const BrandProductScreen({super.key, required this.brand});

  @override
  State<BrandProductScreen> createState() => _BrandProductScreenState();
}

class _BrandProductScreenState extends State<BrandProductScreen> {
  final _api = CallApi();

  String? _selectedSort;
  String? _tempSort;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _products = [];
    });
    try {
      final url = 'products/all?page=1&size=100&brand_id=${widget.brand.id}';
      final response = await _api.getData(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['data']?['items'] as List?) ?? [];
        final lang = Get.locale?.languageCode ?? 'tk';
        if (!mounted) return;
        setState(() {
          _products = items.whereType<Map<String, dynamic>>().map((p) => _toProductMap(p, lang)).toList();
          _sortProducts();
        });
      }
    } catch (e) {
      print('[Brand] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _sortProducts() {
    if (_selectedSort == 'low') {
      _products.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_selectedSort == 'high') {
      _products.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
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

    final salePrice = double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0.0;
    final discountRaw = (double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0).round();
    final oldPrice = discountRaw > 0 && salePrice > 0 ? salePrice + salePrice * discountRaw / 100 : null;

    return {
      'id': item['id']?.toString() ?? '',
      'title': title,
      'imageUrl': imageUrl,
      'price': salePrice,
      'oldPrice': oldPrice,
      'discount': discountRaw > 0 ? '$discountRaw' : null,
      'brandName': widget.brand.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: _buildCircleButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            iconSize: 20,
            onTap: () => Get.back(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.brand.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
          ],
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
            _buildFilterRow(),
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
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  Widget _radioTile({
    required String label,
    required bool isSelected,
    bool isHighlight = false,
    Widget? leading,
    required VoidCallback onTap,
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

  Widget _buildFilterRow() {
    final lang = Get.locale?.languageCode ?? 'tk';
    final count = _products.length;
    final countText = lang == 'ru' ? '$count ${count == 1 ? 'товар' : (count < 5 ? 'товара' : 'товаров')}' : '$count sany haryt';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
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
                    color: Color(0xFF1D1B20),
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _filterPill(
            label: lang == 'ru' ? 'Сортировка' : 'Süzgüç',
            isActive: _selectedSort != null,
            onTap: _showSortSheet,
            onClear: () => setState(() {
              _selectedSort = null;
              _sortProducts();
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(left: 14, right: isActive ? 6 : 14, top: 7, bottom: 7),
        decoration: BoxDecoration(
          color: isActive ? _kGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? _kGreen : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF1D1B20),
                fontFamily: 'Gilroy',
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    _tempSort = _selectedSort;
    final lang = Get.locale?.languageCode ?? 'tk';

    final options = [
      (value: null as String?, label: lang == 'ru' ? 'Все' : 'Hemmesini saýla'),
      (value: 'low', label: lang == 'ru' ? 'Цена: от дешевых' : 'Arzandan gymmada'),
      (value: 'high', label: lang == 'ru' ? 'Цена: от дорогих' : 'Gymmatdan arzana'),
      (value: 'discount', label: lang == 'ru' ? 'По скидке' : 'Arzanladyş boýunça'),
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Gilroy'),
                          ),
                        ),
                        IconButton(onPressed: Navigator.of(ctx).pop, icon: const Icon(Icons.close, size: 22)),
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

    if (_isLoading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ProductCardShimmerGrid(count: 6),
      );
    }

    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchProducts,
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
                  Lottie.asset(
                    'assets/images/shopping-cart.json',
                    width: 180,
                    height: 180,
                    repeat: true,
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
      onRefresh: _fetchProducts,
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
                    categoryName: widget.brand.name,
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
                  lang == 'ru' ? '— Все товары показаны —' : '— Hemmesi görkezildi —',
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
}
