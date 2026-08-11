// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:atlas/core/services/call_api.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _api = CallApi();

  List<Map<String, dynamic>> _faqs = [];
  String _faqMessage = '';
  bool _isLoadingFaqs = true;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final response = await _api.getData('faqs');
      // ignore: avoid_print
      print(
          '[FAQ API] Status Code: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final dynamic data =
            (body is Map && body.containsKey('data')) ? body['data'] : body;

        if (data is List) {
          final lang = Get.locale?.languageCode ?? 'tk';
          setState(() {
            _faqs = data.map((e) {
              final item = e as Map<String, dynamic>;

              String question = '';
              if (item['question'] is Map) {
                final q = item['question'] as Map;
                question = q[lang]?.toString() ??
                    q['tk']?.toString() ??
                    q['ru']?.toString() ??
                    '';
              } else if (item['question'] != null) {
                question = item['question'].toString();
              }

              String answer = '';
              if (item['answer'] is Map) {
                final a = item['answer'] as Map;
                answer = a[lang]?.toString() ??
                    a['tk']?.toString() ??
                    a['ru']?.toString() ??
                    '';
              } else if (item['answer'] != null) {
                answer = item['answer'].toString();
              }

              return {
                'id': item['id'],
                'question': question,
                'answer': answer,
              };
            }).toList();
          });
        } else if (data is String) {
          setState(() => _faqMessage = data);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFaqs = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'help_support'.tr,
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
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('frequently_asked'.tr),
            const SizedBox(height: 16),
            _buildFaqSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    if (_isLoadingFaqs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_faqs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          _faqMessage.isNotEmpty ? _faqMessage : 'no_products_found'.tr,
          style: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Gilroy',
            fontSize: 14,
            height: 1.6,
          ),
        ),
      );
    }

    return Column(
      children: _faqs.asMap().entries.map((entry) {
        final i = entry.key;
        final faq = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: i < _faqs.length - 1 ? 12 : 0),
          child: _buildFaqItem(
            faq['question'] as String,
            faq['answer'] as String,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Gilroy',
            color: Color(0xFF1D1B20),
          ),
        ),
      ],
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(
            RegExp(r'</?(?:h[1-6]|p|div|li|ul|ol|blockquote)[^>]*>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          iconColor: AppColors.green,
          collapsedIconColor: Colors.black26,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Gilroy',
              color: Color(0xFF1D1B20),
            ),
          ),
          children: [
            Text(
              _stripHtml(answer),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
