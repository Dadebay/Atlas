import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/modules/auth/views/register_password_view.dart';

class RegisterOtpView extends StatefulWidget {
  final String phone;
  const RegisterOtpView({super.key, required this.phone});

  @override
  State<RegisterOtpView> createState() => _RegisterOtpViewState();
}

class _RegisterOtpViewState extends State<RegisterOtpView> {
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _otpFocusNodes[i].addListener(() => setState(() {}));
    }
    // _showOtpIfAvailable();
  }

  // void _showOtpIfAvailable() {
  //   Future.delayed(const Duration(milliseconds: 600), () {
  //     if (!mounted) return;
  //     final ctrl = Get.find<RegisterController>();
  //     final otp = ctrl.lastOtp;
  //     if (otp == null || otp.isEmpty) return;
  //     Get.snackbar(
  //       'OTP',
  //       otp,
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: AppColors.green,
  //       colorText: Colors.white,
  //       borderRadius: 14,
  //       margin: const EdgeInsets.all(16),
  //       duration: const Duration(seconds: 10),
  //       icon:
  //           const Icon(Icons.lock_open_rounded, color: Colors.white, size: 26),
  //       titleText: const Text(
  //         'OTP kod',
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.w700,
  //           fontSize: 14,
  //           fontFamily: 'Gilroy',
  //         ),
  //       ),
  //       messageText: Text(
  //         otp,
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.w900,
  //           fontSize: 28,
  //           fontFamily: 'Gilroy',
  //           letterSpacing: 8,
  //         ),
  //       ),
  //     );
  //   });
  // }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _submit() {
    if (_otpCode.length != 4) {
      Get.snackbar(
        'attention'.tr,
        'enter_otp_code'.tr,
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
    Get.to(() => RegisterPasswordView(phone: widget.phone, code: _otpCode));
  }

  Widget _buildOtpBox(int index) {
    final isFocused = _otpFocusNodes[index].hasFocus;
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final isActive = isFocused || hasValue;

    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Gilroy',
          color: isActive ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: isActive ? AppColors.green : Colors.grey.shade100,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasValue ? AppColors.green : Colors.grey.shade300,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.green, width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        '+993 ${widget.phone}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gilroy',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'verify_phone_desc'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildOtpBox(i),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'continue_button'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
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
}
