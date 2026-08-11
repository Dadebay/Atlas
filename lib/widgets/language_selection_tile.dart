import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:atlas/modules/profile/controllers/language_controller.dart';
import 'package:hugeicons/hugeicons.dart';

class LanguageSelectionTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final String code;
  final bool goBack;

  const LanguageSelectionTile({
    super.key,
    required this.title,
    required this.iconPath,
    required this.code,
    this.goBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController =
        Get.find<LanguageController>();
    return Obx(() {
      bool isSelected = languageController.selectedLanguage.value == code;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: () {
            languageController.changeLanguage(code);
            if (goBack) Get.back();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.green.withOpacity(0.05)
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.green : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SvgPicture.asset(
                    iconPath,
                    width: 32,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: isSelected ? AppColors.green : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    color: AppColors.green,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
