import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/auth/controllers/register_controller.dart';
import 'package:atlas/modules/auth/views/register_otp_view.dart';

class RegisterPhoneView extends StatefulWidget {
  const RegisterPhoneView({super.key});

  @override
  State<RegisterPhoneView> createState() => _RegisterPhoneViewState();
}

class _RegisterPhoneViewState extends State<RegisterPhoneView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final RegisterController _registerController;
  bool _agreePrivacy = false;
  bool _isPhoneValid = false;
  bool _submitBasdy = false;

  @override
  void initState() {
    super.initState();
    _registerController = Get.isRegistered<RegisterController>() ? Get.find<RegisterController>() : Get.put(RegisterController());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isButtonEnabled => _isPhoneValid && _agreePrivacy;

  void _submit() async {
    setState(() => _submitBasdy = true);
    if (!_agreePrivacy) {
      Get.snackbar(
        'attention'.tr,
        'please_agree_privacy'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFE53935),
        colorText: const Color(0xFFFFFFFF),
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final success = await _registerController.sendCode(_phoneController.text);
      if (success) {
        Get.to(() => RegisterOtpView(phone: _phoneController.text));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverAppBar()],
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'register_title'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 26,
                    fontFamily: 'Gilroy',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'phone_number'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 9),
                _buildPhoneField(),
                const SizedBox(height: 12),
                _buildPrivacyCheckbox(),
                const SizedBox(height: 16),
                Opacity(
                  opacity: _isButtonEnabled ? 1.0 : 0.5,
                  child: Obx(() => _buildGradientButton(
                        text: 'continue_button'.tr,
                        isLoading: _registerController.isLoading.value,
                        onTap: (!_isButtonEnabled || _registerController.isLoading.value) ? null : _submit,
                      )),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Get.back(),
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        'login_button'.tr,
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
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.green,
      elevation: 4,
      centerTitle: true,
      toolbarHeight: 120,
      automaticallyImplyLeading: false,
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          ),
          ClipRRect(
            child: Image.asset(
              'assets/images/logo3.png',
              height: 105,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'Gilroy',
        color: Colors.black87,
      ),
      onChanged: (value) {
        setState(() => _isPhoneValid = value.length == 8);
        if (_submitBasdy) _formKey.currentState!.validate();
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        hintText: 'XX XX XX XX',
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontFamily: 'Gilroy',
          fontSize: 15,
          fontWeight: FontWeight.w300,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        counterText: '',
        prefixIcon: TextButton(
          onPressed: () {},
          child: const Text(
            '+993',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w300,
              fontFamily: 'Gilroy',
            ),
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'field_required'.tr;
        if (value.length != 8) return 'invalid_phone_number'.tr;
        return null;
      },
    );
  }

  Widget _buildPrivacyCheckbox() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: _agreePrivacy,
        shape: const CircleBorder(),
        activeColor: AppColors.green,
        onChanged: (val) => setState(() => _agreePrivacy = val ?? false),
      ),
      title: Text(
        'privacy_agreement'.tr,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Gilroy',
          color: Colors.black87,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: onTap == null ? [Colors.grey, Colors.grey.shade600] : [AppColors.green, AppColors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Gilroy',
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
