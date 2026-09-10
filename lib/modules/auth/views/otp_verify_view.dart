import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:atlas/core/utils/phone_utils.dart';
import 'package:atlas/modules/auth/controllers/auth_controller.dart';
import 'package:atlas/modules/auth/views/phone_auth_view.dart';
import 'package:atlas/modules/auth/widgets/auth_shell.dart';
import 'package:atlas/themes/colors.dart';
import 'package:hugeicons/hugeicons.dart';

/// Step 2 — the SMS code is the only credential. Verifying it signs the
/// customer in, creating the account first when the number is new.
class OtpVerifyView extends StatefulWidget {
  const OtpVerifyView({super.key});

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  static const int _length = 4;

  final List<TextEditingController> _controllers = List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNodes.first.requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    // Pasting the whole code into one box fills the row.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _length - 1);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Backspace on an empty box steps back into the previous one.
      _focusNodes[index - 1].requestFocus();
    }

    _auth.codeError.value = null;
    setState(() {});

    // Auto-submit as soon as the last digit lands.
    if (_code.length == _length) _submit();
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  Future<void> _submit() async {
    if (_code.length != _length || _auth.isVerifying.value) return;
    FocusScope.of(context).unfocus();

    final result = await _auth.verifyCode(_code);
    if (!mounted) return;

    switch (result) {
      case OtpResult.signedIn:
        PhoneAuthView.finish();
      case OtpResult.invalidCode:
        _clearCode();
      case OtpResult.failed:
        break;
    }
  }

  Future<void> _resend() async {
    _clearCode();
    await _auth.sendCode(_auth.phone);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      step: 2,
      title: 'auth_otp_title'.tr,
      subtitle: 'auth_otp_subtitle'.tr,
      children: [
        _PhoneChip(
          phone: PhoneUtils.toDisplay(_auth.phone),
          onChange: () => Get.back(),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_length, (i) => _buildDigitBox(i)),
        ),
        Obx(() {
          final error = _auth.codeError.value;
          if (error == null) return const SizedBox(height: 24);
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 17, color: Color(0xFFE53935)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontFamily: 'Gilroy',
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        Obx(
          () => AuthPrimaryButton(
            label: 'auth_verify'.tr,
            isLoading: _auth.isVerifying.value,
            onTap: _code.length == _length ? _submit : null,
          ),
        ),
        const SizedBox(height: 22),
        Center(child: Obx(_buildResend)),
      ],
    );
  }

  Widget _buildResend() {
    final seconds = _auth.secondsLeft.value;
    final sending = _auth.isSendingCode.value;

    // The 180 second window starts at the first request and is not extended by
    // a resend, so the button stays locked until it has actually run out.
    if (seconds > 0) {
      return Text(
        'auth_resend_in'.trParams({'time': _auth.countdownLabel}),
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Gilroy',
          color: Color(0xFF9AA1AC),
        ),
      );
    }

    return TextButton(
      onPressed: sending ? null : _resend,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        sending ? 'auth_sending'.tr : 'auth_resend'.tr,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    final hasError = _auth.codeError.value != null;

    final Color borderColor = hasError
        ? const Color(0xFFE53935)
        : (isFocused || hasValue)
            ? AppColors.green
            : const Color(0xFFE6EAF0);

    OutlineInputBorder box(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    // One field per digit, with the box drawn by the field's own decoration.
    // Wrapping a TextField in a decorated Container drew the box twice: the
    // app's inputDecorationTheme still supplied a fill and a focusedBorder, so
    // a second rounded rect appeared inside the outer one on focus.
    return SizedBox(
      width: 68,
      height: 92,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        showCursor: false,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          fontFamily: 'Gilroy',
          color: Color(0xFF14181F),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: hasValue ? AppColors.green.withValues(alpha: 0.06) : const Color(0xFFF4F6FA),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          // Every state is named, so nothing is left for the theme to fill in.
          border: box(borderColor, 1.4),
          enabledBorder: box(borderColor, 1.4),
          focusedBorder: box(borderColor, 1.8),
          errorBorder: box(const Color(0xFFE53935), 1.4),
          focusedErrorBorder: box(const Color(0xFFE53935), 1.8),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}

class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.phone, required this.onChange});

  final String phone;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          //  Icon(Icons.smartphone_rounded, size: 18, color: Color(0xFF7A828F)),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedSmartPhone01,
            color: Color(0xFF7A828F),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phone,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: Color(0xFF14181F),
              ),
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              'auth_change_number'.tr,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
