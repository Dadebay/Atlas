import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/modules/profile/controllers/language_controller.dart';
import 'package:atlas/widgets/language_selection_tile.dart';
import 'package:hugeicons/hugeicons.dart';

class LanguagePage extends StatelessWidget {
  LanguagePage({super.key});
  final LanguageController languageController = Get.put(LanguageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'language'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 24,
            color: AppColors.green,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: const Column(
        children: [
          SizedBox(height: 20),
          LanguageSelectionTile(
            title: 'Türkmen dili',
            iconPath: 'assets/icons/tmflag.svg',
            code: 'tk',
            goBack: true,
          ),
          SizedBox(height: 12),
          LanguageSelectionTile(
            title: 'Rus dili',
            iconPath: 'assets/icons/ruflag.svg',
            code: 'ru',
            goBack: true,
          ),
        ],
      ),
    );
  }
}
