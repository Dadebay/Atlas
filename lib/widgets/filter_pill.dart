import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/pressable.dart';

/// A filter or sort chip.
///
/// Selecting one changes a list the user is already looking at, so the chip
/// itself has to carry the state change: the fill, border and label crossfade
/// over [AppMotion.fast] and the clear button settles in from 0.94. What does
/// *not* animate is the result grid — re-flying every card on each filter tap
/// would make a two-tap refinement feel like a page load.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
    this.onClear,
    this.height = 42,
    this.borderRadius = 12,
    this.inactiveColor = const Color(0xFFF3F4F6),
    this.inactiveBorderColor,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;
  final double height;
  final double borderRadius;
  final Color inactiveColor;
  final Color? inactiveBorderColor;

  static const Color _activeColor = AppColors.green;
  static const Color _inactiveText = Color(0xFF1D1B20);

  @override
  Widget build(BuildContext context) {
    final showClear = isActive && onClear != null;
    final duration = AppMotion.duration(context, AppMotion.fast);

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.easeOut,
        height: height,
        padding: EdgeInsets.only(left: 12, right: showClear ? 8 : 14),
        decoration: BoxDecoration(
          color: isActive ? _activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: inactiveBorderColor == null
              ? null
              : Border.all(
                  color: isActive ? _activeColor : inactiveBorderColor!,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The pill's own node: one spoken name and one selected state.
            // The clear button below stays a separate control, so it is not
            // swallowed by this node.
            Semantics(
              button: true,
              selected: isActive,
              label: label,
              container: true,
              excludeSemantics: true,
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    HugeIcon(
                      icon: icon!,
                      color: isActive ? Colors.white : Colors.black87,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: AppMotion.easeOut,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _inactiveText,
                      fontFamily: 'Gilroy',
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
            // Settles in at 0.94 rather than appearing from nothing.
            AnimatedSwitcher(
              duration: duration,
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
                  child: child,
                ),
              ),
              child: showClear
                  ? Padding(
                      key: const ValueKey(true),
                      padding: const EdgeInsets.only(left: 6),
                      child: Semantics(
                        button: true,
                        label: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        child: Pressable(
                          onTap: onClear,
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey(false)),
            ),
          ],
        ),
      ),
    );
  }
}
