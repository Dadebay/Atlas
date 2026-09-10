import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/modules/auth/controllers/auth_controller.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/pressable.dart';

/// Lets the customer put a name on an account that was created from nothing but
/// a phone number.
///
/// The API stores the first and last name joined together in a single
/// `username` string, so the two fields are split on the way in and joined on
/// the way out. Nothing here is required — an account with no name is a valid
/// account, and the profile falls back to showing the phone number.
class EditNameSheet extends StatefulWidget {
  const EditNameSheet({super.key, required this.currentName});

  final String currentName;

  static Future<void> show(String currentName) {
    return Get.bottomSheet<void>(
      EditNameSheet(currentName: currentName),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      enterBottomSheetDuration: AppMotion.emphasized,
      exitBottomSheetDuration: AppMotion.standard,
    );
  }

  @override
  State<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<EditNameSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  final FocusNode _firstFocus = FocusNode();

  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();

    final parts = widget.currentName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    _firstName = TextEditingController(
      text: parts.isEmpty ? '' : parts.first,
    );
    _lastName = TextEditingController(
      text: parts.length < 2 ? '' : parts.skip(1).join(' '),
    );

    _firstName.addListener(() => setState(() {}));
    _lastName.addListener(() => setState(() {}));

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _firstFocus.requestFocus());
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _firstFocus.dispose();
    super.dispose();
  }

  String get _username => [
        _firstName.text.trim(),
        _lastName.text.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

  bool get _hasChanges =>
      _username.isNotEmpty && _username != widget.currentName.trim();

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await _auth.updateUsername(_username);
    if (saved && mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        // The keyboard inset is padding *inside* a scroll view rather than on
        // the sheet itself. Adding it outside pushed the fixed-height column
        // past the screen the moment the keyboard opened, which is what
        // overflowed. Now the content scrolls clear of the keyboard, and on a
        // short screen the sheet still fits.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative: the sheet is already draggable and dismissible.
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE3EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'edit_profile'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF14181F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'edit_name_desc'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF7A828F),
                ),
              ),
              const SizedBox(height: 22),
              _NameField(
                controller: _firstName,
                focusNode: _firstFocus,
                label: 'auth_first_name'.tr,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _NameField(
                controller: _lastName,
                label: 'auth_last_name'.tr,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_hasChanges) _save();
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () => _SaveButton(
                  label: 'save'.tr,
                  isLoading: _auth.isSavingProfile.value,
                  onTap: _hasChanges ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(26)],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: Color(0xFF14181F),
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w400,
          color: Color(0xFFB6BCC6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        // Named for every state, so the global inputDecorationTheme cannot
        // paint a second border inside this one.
        border: border(const Color(0xFFE6EAF0), 1.4),
        enabledBorder: border(const Color(0xFFE6EAF0), 1.4),
        focusedBorder: border(AppColors.green, 1.6),
        disabledBorder: border(const Color(0xFFE6EAF0), 1.4),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;

    return AnimatedOpacity(
      duration: AppMotion.duration(context, AppMotion.fast),
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 54,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                  ),
                ),
        ),
      ),
    );
  }
}
