import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/themes/colors.dart';

/// One tab's icon, label, and optional badge count (e.g. cart item count).
class NavBarItemData {
  const NavBarItemData({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.badgeCountGetter,
    this.iconKey,
  });

  final IconData icon;
  final String label;
  final int badgeCount;

  /// When set, the badge is wrapped in its own [Obx] reading this getter, so
  /// a reactive change (e.g. cart item count) only repaints the small badge
  /// instead of forcing the whole nav bar (all tabs) to rebuild.
  final int Function()? badgeCountGetter;

  /// Attach a [GlobalKey] to this tab's icon so its screen position can be
  /// resolved later (e.g. as the landing spot for a "fly to cart" animation).
  final GlobalKey? iconKey;
}

/// A hand-rolled replacement for [BottomNavigationBar].
///
/// This is the most-tapped control in the app, so its motion is deliberately
/// quiet: the pill slides on the compositor, the icon does no more than change
/// colour with a hair of scale, and nothing overshoots. The previous version
/// stacked a 420 ms `easeOutBack` slide (which animated `left`, and therefore
/// re-laid out every frame), a 320 ms pill pop and a 380 ms `elasticOut` icon
/// bounce on top of each other on every single tap.
class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<NavBarItemData> items;
  final ValueChanged<int> onTap;

  static const _height = 64.0;
  static const _margin = 6.0;

  void _handleTap(int index) {
    // Re-tapping the current tab is a no-op: no animation, no haptic.
    if (index == currentIndex) return;
    AppMotion.selection();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _margin,
              vertical: _margin,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Fixed position and width; only the transform changes, so
                    // the slide never triggers layout. Retargeting mid-flight
                    // continues from where the pill currently is.
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: itemWidth,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: itemWidth * currentIndex),
                        duration:
                            AppMotion.duration(context, AppMotion.standard),
                        curve: AppMotion.easeInOut,
                        builder: (context, dx, child) => Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        ),
                        child: const RepaintBoundary(child: _Pill()),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavItem(
                              data: items[i],
                              active: i == currentIndex,
                              onTap: () => _handleTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final NavBarItemData data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.mediumGreyColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: active,
        label: data.label,
        // The count is announced as part of the tab, so a screen reader says
        // "Cart, 3, selected" instead of reading a stray number.
        value: _badgeSemanticValue(),
        container: true,
        // The visible label and the badge are decoration here: this node
        // already says everything, and leaving them in would say it twice.
        // Excluding them also drops the detector's implicit tap action, so the
        // node carries its own.
        excludeSemantics: true,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: data.iconKey,
                    // Colour carries the selection; the scale is just enough to
                    // acknowledge the tap. It settles, it does not bounce.
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          end: active ? 1 : AppMotion.pressedScale),
                      duration: AppMotion.duration(context, AppMotion.instant),
                      curve: AppMotion.easeOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: color),
                        duration: AppMotion.instant,
                        curve: AppMotion.easeOut,
                        builder: (context, animatedColor, __) => HugeIcon(
                          icon: data.icon,
                          color: animatedColor ?? color,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  if (data.badgeCountGetter != null)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Obx(() {
                        final count = data.badgeCountGetter!();
                        return count > 0
                            ? _Badge(count: count)
                            : const SizedBox.shrink();
                      }),
                    )
                  else if (data.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: _Badge(count: data.badgeCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppMotion.instant,
              curve: AppMotion.easeOut,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.3,
              ),
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Null when there is nothing to announce, so the tab reads as a plain
  /// button rather than one with an empty value.
  String? _badgeSemanticValue() {
    final count = data.badgeCountGetter?.call() ?? data.badgeCount;
    return count > 0 ? '$count' : null;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Keyed on presence, not on the number: the badge grows in once, and a
      // changing count only crossfades the digits inside it.
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        constraints: const BoxConstraints(minWidth: 16),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.instant),
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: Text(
            '$count',
            key: ValueKey(count),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
