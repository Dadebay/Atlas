import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The single source of truth for how Atlas moves.
///
/// Every duration and curve in the app comes from here so the bottom bar, the
/// category segment, the cart flight and the product stepper all read as one
/// motion language instead of six unrelated ones.
///
/// Rules the tokens encode:
/// * UI motion stays under 300 ms — [emphasized] is the ceiling, not a target.
/// * Entrances and exits use [easeOut]; something travelling across the screen
///   uses [easeInOut]; sheets use [drawer].
/// * Press feedback never scales below 0.97, and nothing ever appears from
///   `scale: 0`.
abstract final class AppMotion {
  /// Press and colour feedback — the user must feel it inside one blink.
  static const Duration instant = Duration(milliseconds: 120);

  /// Icon swaps, badges, small popovers.
  static const Duration fast = Duration(milliseconds: 160);

  /// The default for UI enter/exit.
  static const Duration standard = Duration(milliseconds: 220);

  /// Rare, large surfaces: modals and sheets.
  static const Duration emphasized = Duration(milliseconds: 300);

  /// Enter / exit.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Travel from one place on screen to another.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Bottom sheets and drawers.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Press feedback scale floor. Anything smaller reads as a glitch.
  static const double pressedScale = 0.97;

  /// The scale a surface grows from when it appears. Never 0.
  static const double enterScale = 0.96;

  /// True when the platform asks for reduced motion — iOS "Reduce Motion" or
  /// Android "Remove animations".
  ///
  /// Reads the inherited [MediaQuery] when there is one so a test can override
  /// it, and falls back to the platform dispatcher so this is also answerable
  /// outside the widget tree.
  static bool reduceMotion([BuildContext? context]) {
    if (context != null) {
      final query = MediaQuery.maybeOf(context);
      if (query != null) return query.disableAnimations;
    }
    return WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// [normal], or zero when the platform asks for reduced motion.
  ///
  /// Use this for position and scale motion. Short opacity and colour feedback
  /// carries meaning, so it may keep its duration even under reduced motion.
  static Duration duration(BuildContext context, Duration normal) =>
      reduceMotion(context) ? Duration.zero : normal;

  /// A curve is meaningless over a zero duration; this keeps call sites from
  /// having to branch twice.
  static Curve curve(BuildContext context, Curve normal) =>
      reduceMotion(context) ? Curves.linear : normal;

  //==================== Haptics ====================//

  /// Moving between peers: a bottom-nav tab, a segment, a filter chip.
  ///
  /// Kept under reduced motion — it is feedback, not decoration.
  static void selection() => HapticFeedback.selectionClick();

  /// A discrete success the user asked for, such as an item reaching the cart.
  /// Never fire this on every increment, on scroll, or on a page opening.
  static void success() => HapticFeedback.lightImpact();
}
