import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/auth/controllers/register_controller.dart';
import 'package:atlas/modules/main/controllers/main_controller.dart';

class RegisterPasswordView extends StatefulWidget {
  final String phone;
  final String code;
  const RegisterPasswordView({super.key, required this.phone, required this.code});

  @override
  State<RegisterPasswordView> createState() => _RegisterPasswordViewState();
}

class _RegisterPasswordViewState extends State<RegisterPasswordView> {
  late final RegisterController _registerController;

  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();

  final _passwordController = TextEditingController();
  final _passFocusNode = FocusNode();
  bool _obscurePassword = true;
  int _passwordLength = 0;

  final _confirmController = TextEditingController();
  final _confFocusNode = FocusNode();
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _registerController = Get.isRegistered<RegisterController>() ? Get.find<RegisterController>() : Get.put(RegisterController());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocusNode.dispose();
    _passFocusNode.dispose();
    _confFocusNode.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'field_required'.tr;
    if (value.length > 26) return 'username_too_long'.tr;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'enter_password'.tr;
    if (value.length < 8) return 'password_min_8'.tr;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'field_required'.tr;
    if (value != _passwordController.text) return 'passwords_not_match'.tr;
    return null;
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    final success = await _registerController.register(
      phone: widget.phone,
      code: widget.code,
      password: _passwordController.text,
      username: _usernameController.text,
    );

    if (success) {
      Get.until((route) => route.isFirst);
      Get.find<MainController>().changeIndex(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 90,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          onPressed: () => Get.back(),
        ),
        title: ClipRRect(
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
        actions: const [SizedBox(width: 48)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              const SizedBox(height: 28),

              // ─── Username ────────────────────────────────────────────────
              _fieldLabel('username_label'.tr, required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                style: _inputTextStyle,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocusNode),
                onTapOutside: (_) => _usernameFocusNode.unfocus(),
                decoration: _inputDecoration(hint: 'username_hint'.tr),
                validator: _validateUsername,
              ),
              const SizedBox(height: 24),

              // ─── Password ─────────────────────────────────────────────────
              _fieldLabel('password_label'.tr, required: true, sub: '(${'at_least_8'.tr})'),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passFocusNode,
                    obscureText: _obscurePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.next,
                    style: _inputTextStyle,
                    onChanged: (val) => setState(() => _passwordLength = val.length),
                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confFocusNode),
                    onTapOutside: (_) => _passFocusNode.unfocus(),
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      suffix: _visibilityButton(
                        obscure: _obscurePassword,
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_passwordLength / 8',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Gilroy'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Confirm Password ─────────────────────────────────────────
              _fieldLabel('confirm_password_label'.tr, required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                focusNode: _confFocusNode,
                obscureText: _obscureConfirm,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                style: _inputTextStyle,
                onFieldSubmitted: (_) => _confFocusNode.unfocus(),
                onTapOutside: (_) => _confFocusNode.unfocus(),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  suffix: _visibilityButton(
                    obscure: _obscureConfirm,
                    onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 36),

              // ─── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() => ElevatedButton(
                      onPressed: _registerController.isLoading.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'register_button'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          if (_registerController.isLoading.value) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    )),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false, String? sub}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Colors.black54,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(width: 6),
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Gilroy')),
        ],
        if (required) const Text(' *', style: TextStyle(fontSize: 16, color: Colors.red)),
      ],
    );
  }

  Widget _visibilityButton({required bool obscure, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
      onPressed: onTap,
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
        fontSize: 15,
        fontFamily: 'Gilroy',
        color: Colors.black87,
      );

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w300),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
    );
  }
}
