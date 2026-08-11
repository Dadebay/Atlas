import 'dart:convert';

import 'package:atlas/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/core/services/api_constants.dart';
import 'package:atlas/core/services/call_api.dart';

class HeroSlideDetailScreen extends StatefulWidget {
  final int slideId;
  final String previewUrl;

  const HeroSlideDetailScreen({
    super.key,
    required this.slideId,
    required this.previewUrl,
  });

  @override
  State<HeroSlideDetailScreen> createState() => _HeroSlideDetailScreenState();
}

class _HeroSlideDetailScreenState extends State<HeroSlideDetailScreen> {
  final _api = CallApi();
  bool _isLoading = true;
  String _imageUrl = '';
  String _altText = '';

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.previewUrl;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final response = await _api.getData('hero-slides/${widget.slideId}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final item = body['data'] as Map<String, dynamic>;
        final lang = Get.locale?.languageCode ?? 'tk';
        final alt = (item['image_alt'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _imageUrl =
              ApiConstants.fileUrl(item['image_large']?.toString() ?? '');
          _altText = alt[lang] ?? alt['tk'] ?? alt['ru'] ?? '';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen zoomable image
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.image,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
          ),

          // Small spinner while fetching detail in background
          if (_isLoading)
            Positioned(
              bottom: bottomPadding + 24,
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

          // Alt text caption
          if (!_isLoading && _altText.isNotEmpty)
            Positioned(
              bottom: bottomPadding + 24,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _altText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Close button
          Positioned(
            top: topPadding + 10,
            left: 20,
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
