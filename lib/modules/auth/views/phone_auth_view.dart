import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:atlas/core/utils/phone_utils.dart';
import 'package:atlas/modules/auth/controllers/auth_controller.dart';
import 'package:atlas/modules/auth/views/otp_verify_view.dart';
import 'package:atlas/modules/auth/widgets/auth_shell.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/core/theme/app_motion.dart';

/// Step 1 of the passwordless flow — the only thing the customer has to know is
/// their phone number. Signing in and signing up are the same screen, because
/// the server registers an unknown number automatically.
class PhoneAuthView extends StatefulWidget {
  const PhoneAuthView({super.key});

  /// Pops every screen of the auth flow at once, back to whatever asked for it.
  static void finish() {
    Get.until((route) => !(route.settings.name ?? '').startsWith('/auth'));
  }

  @override
  State<PhoneAuthView> createState() => _PhoneAuthViewState();
}

class _PhoneAuthViewState extends State<PhoneAuthView> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  late final AuthController _auth;

  // Pre-ticked at the product owner's request. The terms stay reachable and
  // the customer can untick before continuing.
  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    _auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    _auth.reset();
    _phoneController.addListener(() => setState(() {}));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isPhoneComplete => PhoneUtils.isValidLocal(_phoneController.text);
  bool get _canSubmit => _isPhoneComplete && _agreedToTerms;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final sent = await _auth.sendCode(_phoneController.text);
    if (!sent || !mounted) return;
    Get.to(
      () => const OtpVerifyView(),
      routeName: '/auth/otp',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      step: 1,
      title: 'auth_phone_title'.tr,
      subtitle: 'auth_phone_subtitle'.tr,
      children: [
        _PhoneField(controller: _phoneController, focusNode: _focusNode),
        const SizedBox(height: 20),
        _TermsCheckbox(
          value: _agreedToTerms,
          onChanged: (v) => setState(() => _agreedToTerms = v),
        ),
        const SizedBox(height: 28),
        Obx(
          () => AuthPrimaryButton(
            label: 'auth_send_code'.tr,
            isLoading: _auth.isSendingCode.value,
            onTap: _canSubmit ? _submit : null,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'auth_no_password_note'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Gilroy',
              color: Color(0xFF9AA1AC),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  static const Color _idleBorder = Color(0xFFE6EAF0);
  static const Color _fill = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final isComplete = PhoneUtils.isValidLocal(controller.text);
    final activeBorder = isComplete ? AppColors.green : _idleBorder;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    // One field, with the country code living inside it as a prefix. The
    // previous version nested a TextField inside a decorated Container, and
    // because the app's inputDecorationTheme still supplied enabledBorder and
    // focusedBorder, the inner field drew a second rounded box on top of the
    // outer one whenever it had focus.
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      inputFormatters: PhoneUtils.inputFormatters,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        fontFamily: 'Gilroy',
        color: Color(0xFF14181F),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fill,
        hintText: '65 01 02 03',
        hintStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.6,
          fontFamily: 'Gilroy',
          color: Color(0xFFB6BCC6),
        ),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        // Every state is named explicitly; leaving any of them to the theme is
        // what produced the doubled border in the first place.
        border: border(_idleBorder, 1.4),
        enabledBorder: border(activeBorder, 1.4),
        focusedBorder: border(AppColors.green, 1.6),
        disabledBorder: border(_idleBorder, 1.4),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                PhoneUtils.displayPrefix,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF14181F),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.only(left: 14),
                color: const Color(0xFFDDE3EB),
              ),
            ],
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedScale(
            duration: AppMotion.duration(context, AppMotion.fast),
            curve: AppMotion.easeOut,
            scale: isComplete ? 1 : 0,
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 22,
              width: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: value ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: value ? AppColors.green : const Color(0xFFC7CEDA),
                  width: 1.6,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'privacy_agreement'.tr,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF5A626E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
